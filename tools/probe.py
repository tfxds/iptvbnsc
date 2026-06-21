import urllib.request as ur, urllib.error, ssl
ctx=ssl.create_default_context(); ctx.check_hostname=False; ctx.verify_mode=ssl.CERT_NONE
B="http://csnbnsc.top"; U="alexander021"; Penc="19111992%40Lex"
def hit(url, ua="smart-tv"):
    try:
        r=ur.urlopen(ur.Request(url,headers={"User-Agent":ua}),timeout=25,context=ctx)
        b=r.read(220); return f"HTTP {r.status} CT={r.headers.get('Content-Type')} len?={r.headers.get('Content-Length')} :: {b[:160]!r}"
    except urllib.error.HTTPError as e:
        return f"HTTP {e.code} loc={e.headers.get('Location') if e.headers else None} :: {e.read()[:120]!r}"
    except Exception as e:
        return f"ERR {e}"
print("1 player_api auth     :", hit(f"{B}/player_api.php?username={U}&password={Penc}"))
print("2 player_api vod (UA roku):", hit(f"{B}/player_api.php?username={U}&password={Penc}&action=get_vod_streams","roku"))
print("3 player_api vod (UA VLC):", hit(f"{B}/player_api.php?username={U}&password={Penc}&action=get_vod_streams","VLC/3.0.0"))
print("4 player_api cats     :", hit(f"{B}/player_api.php?username={U}&password={Penc}&action=get_vod_categories"))
print("5 get.php m3u_plus    :", hit(f"{B}/get.php?username={U}&password={Penc}&type=m3u_plus&output=ts"))
