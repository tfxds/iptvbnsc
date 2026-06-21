import json, urllib.request, urllib.error, ssl, collections
ctx = ssl.create_default_context(); ctx.check_hostname=False; ctx.verify_mode=ssl.CERT_NONE
BASE="http://csnbnsc.top"; U="alexander021"; P="19111992@Lex"
def get(url, rng=False):
    req=urllib.request.Request(url, headers={"User-Agent":"smart-tv"}, method="GET")
    if rng: req.add_header("Range","bytes=0-300")
    try:
        with urllib.request.urlopen(req,timeout=25,context=ctx) as r:
            return r.status, dict(r.headers), r.read(300)
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers or {}), (e.read()[:200] if hasattr(e,'read') else b'')
    except Exception as e:
        return None, {"err":str(e)}, b''
# lista de filmes
api=f"{BASE}/player_api.php?username={U}&password=19111992%40Lex&action=get_vod_streams"
s,h,_=get(api)
import urllib.request as ur
raw=ur.urlopen(ur.Request(api,headers={"User-Agent":"smart-tv"}),timeout=30,context=ctx).read().decode("utf-8","replace")
vods=json.loads(raw)
print("total filmes:", len(vods))
ext=collections.Counter((v.get("container_extension") or "<none>") for v in vods)
print("extensoes:", dict(ext))
# pega 1 amostra de cada extensao e testa a URL real do filme (como o app monta)
seen=set(); samples=[]
for v in vods:
    e=v.get("container_extension") or "<none>"
    if e in seen: continue
    seen.add(e); samples.append(v)
print("\n== teste de URL por extensao ==")
for v in samples:
    sid=v.get("stream_id"); e=v.get("container_extension")
    url=f"{BASE}/movie/{U}/{P}/{sid}.{e}"
    st,hh,head=get(url, rng=True)
    print(f"[{e}] id={sid} '{v.get('name','')[:30]}' -> HTTP {st} CT={hh.get('Content-Type')} CL={hh.get('Content-Length')} loc={hh.get('Location')}")
