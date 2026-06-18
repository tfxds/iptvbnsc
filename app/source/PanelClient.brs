' ============================================================================
' PanelClient.brs - camada de protocolo do painel S.A Player (auth.php)
' Replica o que o app Android faz: XOR+Base64 com chave fixa, UA "smart-tv",
' MAC = SHA256(app_device_id), e os 3 fluxos (reseller_dns / login / poll).
' Contrato validado ao vivo em 2026-06-08 (ver docs/plans).
' ============================================================================

function panelConst() as Object
    return {
        ' TODO(backend BNSC): confirmar com o Gustavo o path EXATO do auth.php do app nesta
        ' instancia. O painel web fica em streamplayer.gerenciapro.top/bnsc; a rota que o APP
        ' consome ainda nao foi confirmada (palpite abaixo segue o padrao do saplayer:
        ' <pasta-painel>/api/auth.php). Validar com um poll ao vivo antes de publicar.
        url: "https://streamplayer.gerenciapro.top/bnsc/api/auth.php"
        ua: "smart-tv"
        appType: "roku"
        keyHex: "4A7B9CE32FA568D13B76C912EF458A1DB4592CF7639E3154A87DC2164E9328BF"
    }
end function

' --- helpers de hex (sem depender de Val(radix), que varia entre firmwares) ---
function panelHexToInt(h as String) as Integer
    digits = "0123456789ABCDEF"
    h = UCase(h)
    n = 0
    for i = 1 to Len(h)
        n = n * 16 + (Instr(1, digits, Mid(h, i, 1)) - 1)
    end for
    return n
end function

function panelByteToHex(n as Integer) as String
    digits = "0123456789ABCDEF"
    return Mid(digits, (n \ 16) + 1, 1) + Mid(digits, (n mod 16) + 1, 1)
end function

' XOR de dois bytes (0..255). BrightScript nao tem operador xor:
' a xor b = (a or b) and (255 - (a and b))
function panelXorByte(a as Integer, b as Integer) as Integer
    return (a or b) and (255 - (a and b))
end function

' chave como roByteArray
function panelKeyBytes() as Object
    ba = CreateObject("roByteArray")
    ba.FromHexString(panelConst().keyHex)
    return ba
end function

' XOR de um roByteArray com a chave repetida -> novo roByteArray
function panelXorBytes(data as Object) as Object
    key = panelKeyBytes()
    klen = key.Count()
    out = CreateObject("roByteArray")
    for i = 0 to data.Count() - 1
        out.Push(panelXorByte(data[i], key[i mod klen]))
    end for
    return out
end function

' objeto -> string "base64(xor(json))"
function panelEncode(obj as Object) as String
    json = FormatJson(obj)
    data = CreateObject("roByteArray")
    data.FromAsciiString(json)
    return panelXorBytes(data).ToBase64String()
end function

' string "base64(xor(json))" -> objeto (invalid se falhar)
function panelDecode(b64 as String) as Object
    raw = CreateObject("roByteArray")
    raw.FromBase64String(b64)
    plain = panelXorBytes(raw)
    return ParseJson(plain.ToAsciiString())
end function

' device id -> MAC igual ao painel: SHA256, 12 primeiros hex, 1o byte & 0xFC
function panelDeviceMac(deviceId as String) as String
    digest = CreateObject("roEVPDigest")
    digest.Setup("sha256")
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(deviceId)
    hex = digest.Process(ba)                       ' hex string do sha256
    h = LCase(Left(hex, 12))
    firstByte = panelHexToInt(Left(h, 2)) and 252  ' 0xFC
    macHex = panelByteToHex(firstByte) + Mid(h, 3) ' 12 chars
    mac = ""
    for i = 1 to 11 step 2
        if mac <> "" then mac = mac + ":"
        mac = mac + Mid(macHex, i, 2)
    end for
    return UCase(mac)
end function

' ============================================================================
' HTTP + fluxos. Estas funcoes fazem rede sincrona via roMessagePort, entao
' DEVEM rodar dentro de uma Task node (nunca na render thread).
' ============================================================================

' POST {"data": payload} com UA smart-tv. Devolve o objeto decriptado ou invalid.
function panelPost(authData as Object) as Object
    c = panelConst()
    authData.app_type = c.appType
    body = FormatJson({ data: panelEncode(authData) })

    port = CreateObject("roMessagePort")
    http = CreateObject("roUrlTransfer")
    http.SetMessagePort(port)
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    http.InitClientCertificates()
    http.SetUrl(c.url)
    http.AddHeader("User-Agent", c.ua)
    http.AddHeader("Content-Type", "application/json")
    http.SetRequest("POST")

    if http.AsyncPostFromString(body)
        msg = wait(30000, port)
        if type(msg) = "roUrlEvent"
            respStr = msg.GetString()
            if respStr <> invalid and respStr <> ""
                outer = ParseJson(respStr)
                if outer <> invalid and outer.data <> invalid
                    return panelDecode(outer.data)
                end if
            end if
        end if
    end if
    return invalid
end function

' Fluxo A: codigo do revendedor -> lista de DNS liberadas
function panelResellerDns(deviceId as String, code as String) as Object
    return panelPost({ app_device_id: deviceId, version: "reseller_dns", id_user: code })
end function

' Fluxo B: valida/registra login (GRAVA no painel, vincula o MAC ao revendedor)
function panelLogin(deviceId as String, code as String, dnsId as String, user as String, pass as String, authUrl as String) as Object
    return panelPost({ app_device_id: deviceId, version: "login", id_user: code, dns_id: dnsId, username: user, password: pass, auth_url: authUrl })
end function

' Fluxo C: poll por MAC -> branding + portal (urls) + dns. Usa version neutro
' ("poll") que cai no bloco default do auth.php. Confirmado ao vivo 2026-06-08.
function panelPoll(deviceId as String) as Object
    return panelPost({ app_device_id: deviceId, version: "poll" })
end function

' LOGOUT: avisa o painel pra LIMPAR o registro desse MAC (zera username/password/dns/reseller
' da linha do MAC na tabela playlist -> libera a vaga). Acao "logout" do auth.php.
function panelLogout(deviceId as String) as Object
    return panelPost({ app_device_id: deviceId, version: "logout" })
end function

' http://host:porta/get.php?... -> http://host:porta  (base p/ player_api Xtream)
function panelBaseFromUrl(u as String) as String
    if u = invalid or u = "" then return ""
    p = Instr(1, u, "://")
    if p = 0 then return u
    rest = Mid(u, p + 3)            ' host[:porta]/caminho...
    slash = Instr(1, rest, "/")
    if slash > 0 then rest = Left(rest, slash - 1)
    return Left(u, p + 2) + rest    ' esquema:// + host[:porta]
end function
