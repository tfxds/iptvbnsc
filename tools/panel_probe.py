#!/usr/bin/env python3
"""Harness de contrato do painel S.A Player (auth.php). Roda contra o painel AO VIVO.
Uso:
  python3 tools/panel_probe.py reseller_dns <code>
  python3 tools/panel_probe.py poll <device_id> [version]
  python3 tools/panel_probe.py mac <device_id>
  python3 tools/panel_probe.py login <code> <dns_id> <user> <pass> <auth_url>   # SO com PANEL_ALLOW_WRITE=1
"""
import sys, os, json, base64, hashlib, urllib.request

KEY = bytes.fromhex('4A7B9CE32FA568D13B76C912EF458A1DB4592CF7639E3154A87DC2164E9328BF')
URL = 'https://streamapps.dev/saplayer/api/auth.php'

def xor(d): return bytes(d[i] ^ KEY[i % len(KEY)] for i in range(len(d)))
def enc(o): return base64.b64encode(xor(json.dumps(o, separators=(',', ':')).encode())).decode()
def dec(b): return json.loads(xor(base64.b64decode(b)).decode('utf-8', 'replace'))

def mac_from_device(device_id):
    h = hashlib.sha256(device_id.encode()).hexdigest()[:12]
    first = int(h[:2], 16) & 0xFC
    hexmac = ('%02x' % first) + h[2:]
    return ':'.join(hexmac[i:i+2] for i in range(0, 12, 2)).upper()

def call(auth):
    body = json.dumps({'data': enc(auth)}).encode()
    req = urllib.request.Request(URL, data=body, method='POST')
    req.add_header('User-Agent', 'smart-tv')
    req.add_header('Content-Type', 'application/json')
    with urllib.request.urlopen(req, timeout=30) as r:
        resp = json.loads(r.read().decode())
    return dec(resp['data']) if 'data' in resp else resp

def base(device_id, version):
    return {'app_device_id': device_id, 'app_type': 'roku', 'version': version}

if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'reseller_dns'
    if cmd == 'mac':
        print(mac_from_device(sys.argv[2])); sys.exit(0)
    if cmd == 'reseller_dns':
        a = base('roku-probe-0001', 'reseller_dns'); a['id_user'] = sys.argv[2]
        r = call(a)
        assert isinstance(r, dict) and 'success' in r, f'resposta inesperada: {r}'
        print(json.dumps(r, ensure_ascii=False, indent=2)); sys.exit(0)
    if cmd == 'poll':
        version = sys.argv[3] if len(sys.argv) > 3 else 'login'
        r = call(base(sys.argv[2], version))
        print(json.dumps(r, ensure_ascii=False, indent=2)); sys.exit(0)
    if cmd == 'login':
        assert os.environ.get('PANEL_ALLOW_WRITE') == '1', 'login GRAVA no painel; rode com PANEL_ALLOW_WRITE=1 e conta de TESTE'
        a = base('roku-probe-0001', 'login')
        a.update(id_user=sys.argv[2], dns_id=sys.argv[3], username=sys.argv[4], password=sys.argv[5], auth_url=sys.argv[6])
        print(json.dumps(call(a), ensure_ascii=False, indent=2)); sys.exit(0)
    print('comando desconhecido'); sys.exit(1)
