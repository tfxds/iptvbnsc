#!/usr/bin/env python3
"""
Proxy de remux HEVC -> fMP4 para Roku.

O Roku NAO decodifica HEVC dentro de MPEG-TS (so fMP4/DASH). Paineis Xtream servem os
canais "4K/FHD" como HEVC-em-TS, entao o Roku da errCode -5 "unsupported video format".
Este servico remuxa sob demanda (ffmpeg -c copy, sem re-encode) TS -> fMP4 com tag hvc1,
que o Roku abre. O app reaponta os canais HEVC pra ca quando da -5.

Config por variavel de ambiente (NAO commitar credenciais):
  PANEL     base do painel ate o id, ex: http://host/live/USER/PASS   (sem /<id>.m3u8)
  BR_PROXY  http_proxy de saida (relay num IP autorizado pelo painel), ex: http://1.2.3.4:8888
  PORT      porta do servico (default 8090)
  IDLE      segundos sem request pra matar o ffmpeg do canal (default 30)

Endpoints:
  GET /r/<id>/index.m3u8   -> sobe o ffmpeg do canal (se preciso) e serve a playlist fMP4
  GET /r/<id>/<arquivo>    -> serve init.mp4 / index<N>.m4s
  GET /health
"""
import os, time, threading, subprocess, re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PANEL = os.environ.get("PANEL", "http://CHANGEME/live/USER/PASS")
BR_PROXY = os.environ.get("BR_PROXY", "")
PORT = int(os.environ.get("PORT", "8090"))
IDLE = int(os.environ.get("IDLE", "30"))
HLS = "/tmp/hls"
UA = "VLC/3.0.20 LibVLC/3.0.20"

procs = {}
lock = threading.Lock()


def clean_dir(d):
    try:
        for f in os.listdir(d):
            os.remove(os.path.join(d, f))
    except Exception:
        pass


def start(cid):
    d = os.path.join(HLS, cid)
    os.makedirs(d, exist_ok=True)
    clean_dir(d)
    src = "%s/%s.m3u8" % (PANEL, cid)
    cmd = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-user_agent", UA,
           "-i", src, "-c", "copy", "-bsf:a", "aac_adtstoasc", "-tag:v", "hvc1",
           "-f", "hls", "-hls_time", "4", "-hls_list_size", "6",
           "-hls_flags", "delete_segments+append_list+independent_segments",
           "-hls_segment_type", "fmp4", os.path.join(d, "index.m3u8")]
    env = dict(os.environ)
    if BR_PROXY:
        env["http_proxy"] = BR_PROXY
    p = subprocess.Popen(cmd, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    procs[cid] = {"p": p, "d": d, "t": time.time()}
    return d


def ensure(cid):
    with lock:
        e = procs.get(cid)
        if e and e["p"].poll() is None:
            e["t"] = time.time()
            return e["d"]
        return start(cid)


def touch(cid):
    with lock:
        e = procs.get(cid)
        if e:
            e["t"] = time.time()


def reaper():
    while True:
        time.sleep(10)
        with lock:
            for cid in list(procs):
                e = procs[cid]
                if e["p"].poll() is not None or time.time() - e["t"] > IDLE:
                    try:
                        e["p"].kill()
                    except Exception:
                        pass
                    procs.pop(cid, None)


CT = {".m3u8": "application/vnd.apple.mpegurl", ".m4s": "video/mp4", ".mp4": "video/mp4"}


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
            return
        m = re.match(r"^/r/(\d+)/([A-Za-z0-9_.\-]+)$", path)
        if not m:
            self.send_response(404)
            self.end_headers()
            return
        cid, fname = m.group(1), m.group(2)
        if fname == "index.m3u8":
            d = ensure(cid)
            pl = os.path.join(d, "index.m3u8")
            for _ in range(100):
                if os.path.exists(pl) and os.path.getsize(pl) > 0:
                    break
                time.sleep(0.1)
        else:
            touch(cid)
        fp = os.path.join(HLS, cid, fname)
        if not os.path.exists(fp):
            self.send_response(404)
            self.end_headers()
            return
        try:
            data = open(fp, "rb").read()
        except Exception:
            self.send_response(404)
            self.end_headers()
            return
        ext = os.path.splitext(fname)[1]
        self.send_response(200)
        self.send_header("Content-Type", CT.get(ext, "application/octet-stream"))
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    os.makedirs(HLS, exist_ok=True)
    threading.Thread(target=reaper, daemon=True).start()
    ThreadingHTTPServer(("0.0.0.0", PORT), H).serve_forever()
