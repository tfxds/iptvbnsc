#!/usr/bin/env python3
# Diagnostico do player de filmes BNSC: replica o protocolo do painel (XOR+Base64),
# resolve o portal do codigo do revendedor, pega um filme e testa a URL real.
import json, base64, urllib.request, urllib.error, ssl

KEY = bytes.fromhex("4A7B9CE32FA568D13B76C912EF458A1DB4592CF7639E3154A87DC2164E9328BF")
PANEL = "https://streamplayer.gerenciapro.top/bnsc/api/auth.php"
UA = "smart-tv"
APP_TYPE = "roku"
DEVICE = "diag-bnsc-test-0001"
CODE = "2"
USER = "alexander021"
PASS = "19111992@Lex"

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def xor(data: bytes) -> bytes:
    return bytes(b ^ KEY[i % len(KEY)] for i, b in enumerate(data))

def enc(obj) -> str:
    return base64.b64encode(xor(json.dumps(obj).encode())).decode()

def dec(b64: str):
    try:
        return json.loads(xor(base64.b64decode(b64)).decode("utf-8", "replace"))
    except Exception as e:
        return {"__decode_error": str(e)}

def panel_post(authdata: dict):
    authdata["app_type"] = APP_TYPE
    body = json.dumps({"data": enc(authdata)}).encode()
    req = urllib.request.Request(PANEL, data=body, method="POST",
                                 headers={"User-Agent": UA, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30, context=ctx) as r:
            raw = r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return {"__http": e.code, "__body": e.read().decode("utf-8","replace")[:300]}
    except Exception as e:
        return {"__err": str(e)}
    try:
        outer = json.loads(raw)
    except Exception:
        return {"__raw": raw[:400]}
    if isinstance(outer, dict) and "data" in outer:
        return dec(outer["data"])
    return {"__outer": outer}

def http_head(url, method="GET", range_bytes=True):
    req = urllib.request.Request(url, method=method, headers={"User-Agent": "smart-tv"})
    if range_bytes:
        req.add_header("Range", "bytes=0-200")
    try:
        with urllib.request.urlopen(req, timeout=20, context=ctx) as r:
            ct = r.headers.get("Content-Type")
            cl = r.headers.get("Content-Length")
            head = r.read(200)
            return f"HTTP {r.status} | Content-Type={ct} | Content-Length={cl} | first-bytes={head[:32]!r}"
    except urllib.error.HTTPError as e:
        loc = e.headers.get("Location") if e.headers else None
        return f"HTTP {e.code} | Location={loc} | body={e.read()[:120]!r}"
    except Exception as e:
        return f"ERR {e}"

print("== 1) reseller_dns (codigo %s) ==" % CODE)
dns = panel_post({"app_device_id": DEVICE, "version": "reseller_dns", "id_user": CODE})
print(json.dumps(dns, ensure_ascii=False)[:800])

# tenta extrair lista de dns
cands = []
if isinstance(dns, dict):
    for k in ("dns", "urls", "data", "list", "servers"):
        v = dns.get(k)
        if isinstance(v, list):
            cands = v
            break

print("\n== 2) login ==")
# pega o primeiro dns_id pra logar
dns_id = ""
auth_url = ""
if cands:
    first = cands[0]
    if isinstance(first, dict):
        dns_id = first.get("dns_id") or first.get("id") or first.get("url") or ""
        auth_url = first.get("url") or first.get("dns_id") or ""
    else:
        dns_id = str(first); auth_url = str(first)
login = panel_post({"app_device_id": DEVICE, "version": "login", "id_user": CODE,
                    "dns_id": dns_id, "username": USER, "password": PASS, "auth_url": auth_url})
print(json.dumps(login, ensure_ascii=False)[:800])

print("\n== 3) poll ==")
poll = panel_post({"app_device_id": DEVICE, "version": "poll"})
print(json.dumps(poll, ensure_ascii=False)[:1000])
