#!/usr/bin/env python3
import os, time, threading, subprocess, re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

BR_PROXY = "http://187.77.241.121:8888"
PANEL = "http://bnscdn.top/live/bnscalexadm/1973284650"
HLS = "/tmp/hls"
IDLE = 30
UA = "VLC/3.0.20 LibVLC/3.0.20"
procs = {}
lock = threading.Lock()

def clean_dir(d):
    try:
        for f in os.listdir(d): os.remove(os.path.join(d, f))
    except Exception: pass

def start(cid):
    d = os.path.join(HLS, cid)
    os.makedirs(d, exist_ok=True)
    clean_dir(d)
    src = "%s/%s.ts" % (PANEL, cid)
    # A TCL Roku do cliente NAO decodifica HEVC/H.265 (mesmo em fMP4 valido com tag hvc1
    # o device devolve -5 "unsupported video format"). Esses canais "4K" sao na verdade
    # 1080p HEVC. Solucao definitiva: TRANSCODAR HEVC->H.264 (avc1), que toca em 100% dos
    # Roku. Em 2 cores EPYC o transcode roda ~3.7x tempo real (sobra folga). pix_fmt yuv420p
    # forca 8-bit (cobre tambem canais Main10/HDR tipo HBO 4K). force_key_frames a cada 2s
    # garante segmentos HLS independentes/alinhados.
    # SEM append_list: ele injeta um #EXT-X-DISCONTINUITY no inicio da playlist e, quando
    # esse tag rola pra fora da janela (delete_segments), o Roku reclama "Invalid
    # EXT-X-DISCONTINUITY" e derruba o canal ("no valid bitrates" / -3) depois de tocar.
    # Segmentos de 2s + janela de 8 -> a playlist enche rapido e fica estavel (live).
    # Capa em 1080p: canais "4K" reais (3840x2160, ex 149859) custam mais pra transcodar
    # (1.5x tempo real) e geram ~21Mbps; downscale p/ 1080p sobe pra ~2.3x e cai p/ ~8Mbps
    # (entrega mais suave pelo relay + device decodifica facil). A TV renderiza 720p mesmo,
    # entao a imagem final e identica. min(1920,iw) deixa 1080p e menores intactos.
    # MASTER playlist (via -master_pl_name): o Roku so liga o decoder de AUDIO se a playlist
    # declarar CODECS (ex avc1...,mp4a.40.2) num master -> sem isso tocava VIDEO SEM SOM. O
    # master tambem traz BANDWIDTH -> mata o "no valid bitrates"/-3. Deixo o ffmpeg gerar o
    # master pra os CODECS/BANDWIDTH virem certos dos streams reais.
    cmd = ["ffmpeg","-y","-hide_banner","-loglevel","error","-fflags","+genpts",
           "-user_agent",UA,"-i",src,
           "-vf","scale='min(1920,iw)':-2",
           "-c:v","libx264","-preset","ultrafast","-tune","zerolatency",
           "-pix_fmt","yuv420p","-profile:v","high","-level","4.2",
           "-g","48","-keyint_min","48","-sc_threshold","0",
           "-force_key_frames","expr:gte(t,n_forced*2)",
           "-c:a","aac","-ac","2","-b:a","128k",
           "-f","hls","-hls_time","2","-hls_list_size","8",
           "-hls_flags","delete_segments+independent_segments",
           "-hls_segment_type","fmp4",
           "-master_pl_name","master.m3u8", os.path.join(d,"media.m3u8")]
    env = dict(os.environ, http_proxy=BR_PROXY)
    p = subprocess.Popen(cmd, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    procs[cid] = {"p":p, "d":d, "t":time.time()}
    return d

def ensure(cid):
    with lock:
        e = procs.get(cid)
        if e and e["p"].poll() is None:
            e["t"] = time.time(); return e["d"]
        return start(cid)

def touch(cid):
    with lock:
        e = procs.get(cid)
        if e: e["t"] = time.time()

def reaper():
    while True:
        time.sleep(10)
        with lock:
            for cid in list(procs):
                e = procs[cid]
                if e["p"].poll() is not None or time.time()-e["t"] > IDLE:
                    try: e["p"].kill()
                    except Exception: pass
                    procs.pop(cid, None)

CT = {".m3u8":"application/vnd.apple.mpegurl", ".m4s":"video/mp4", ".mp4":"video/mp4"}

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        path = self.path.split("?",1)[0]
        if path == "/health":
            self.send_response(200); self.end_headers(); self.wfile.write(b"ok"); return
        m = re.match(r"^/r/(\d+)/([A-Za-z0-9_.\-]+)$", path)
        if not m:
            self.send_response(404); self.end_headers(); return
        cid, fname = m.group(1), m.group(2)
        if fname == "index.m3u8":
            # index.m3u8 = o MASTER (com CODECS/BANDWIDTH). ffmpeg escreve master.m3u8 +
            # media.m3u8 + init.mp4 + segmentos. Espera >=3 segmentos na MEDIA antes de
            # servir o master (janela live estavel -> device abre de primeira, sem retry).
            d = ensure(cid)
            master = os.path.join(d,"master.m3u8")
            media = os.path.join(d,"media.m3u8")
            init = os.path.join(d,"init.mp4")
            for _ in range(400):
                if os.path.exists(master) and os.path.exists(media) and os.path.exists(init):
                    try:
                        if open(media).read().count("#EXTINF") >= 3: break
                    except Exception: pass
                time.sleep(0.1)
            fp = master
        else:
            touch(cid)
            fp = os.path.join(HLS, cid, fname)
        if not os.path.exists(fp):
            self.send_response(404); self.end_headers(); return
        try:
            data = open(fp,"rb").read()
        except Exception:
            self.send_response(404); self.end_headers(); return
        ext = os.path.splitext(fname)[1]
        self.send_response(200)
        self.send_header("Content-Type", CT.get(ext,"application/octet-stream"))
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Access-Control-Allow-Origin","*")
        self.end_headers()
        self.wfile.write(data)

if __name__ == "__main__":
    os.makedirs(HLS, exist_ok=True)
    threading.Thread(target=reaper, daemon=True).start()
    ThreadingHTTPServer(("0.0.0.0", 8090), H).serve_forever()
