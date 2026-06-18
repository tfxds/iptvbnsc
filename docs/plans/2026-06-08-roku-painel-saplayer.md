# App Roku S.A Player — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer o app Roku (source comprada) logar e exibir branding pelo painel de revenda do cliente (`streamapps.dev/saplayer/api/auth.php`), com código de revendedor + usuário + senha e vínculo por MAC, igual ao Android — sem tocar no Android nem no painel.

**Architecture:** Uma camada de rede nova em BrightScript (`PanelClient.brs`) encapsula o protocolo do painel (XOR+Base64, UA `smart-tv`, 3 fluxos). O boot passa a fazer poll por MAC pra branding/auto-login; a tela de login ganha o campo "Código do revendedor" e passa a exibir o MAC; o sistema de código velho (zedplayer) é removido. O contrato é blindado por um harness Python (`tools/panel_probe.py`) que roda contra o painel ao vivo, e o BrightScript é validado por `brighterscript` (compile/lint).

**Tech Stack:** BrightScript / SceneGraph (Roku), `roUrlTransfer`, `roByteArray` (Base64), `roEVPDigest` (SHA256); Python 3 (harness de contrato); `brighterscript` (lint/compile); `zip` (empacotamento sideload).

---

## Arquivos (mapa de impacto)

- **Criar** `app/source/PanelClient.brs` — camada de protocolo do painel (crypto + MAC + 3 fluxos).
- **Modificar** `app/source/config.brs` — `cargarConfigRemota()` deixa de bater no zedplayer; branding vem do poll por MAC; default S.A Player.
- **Modificar** `app/source/main.brs:47-129` (`initGlobals`) — calcular MAC, chamar poll, decidir auto-login vs tela de login.
- **Modificar** `app/components/screens/LoginScreen/LoginScreen.xml` — add campo "Código do revendedor"; reaproveitar `codeBox` pra exibir o MAC.
- **Modificar** `app/components/screens/LoginScreen/LoginScreen.brs` — add teclado/handler do código; remover handlers do código velho; novo `onValidateLogin`.
- **Remover** `app/components/tasks/GetCodeTask.*`, `ValidateCodeTask.*`, `LoginTask.*` — sistema de código velho.
- **Reutilizar** `app/components/tasks/ConfirmUserTask.brs` — validação Xtream (`player_api.php`), sem mudança de lógica.
- **Criar** `bsconfig.json`, `package.json` — config do `brighterscript`.
- **Modificar** `tools/panel_probe.py` — harness de contrato (fluxos A/B/C ao vivo).
- **Criar** `tools/build.sh` — empacota o `.zip` sideload-ready.
- **Criar** `docs/HOMOLOGACAO.md` — checklist de teste no device pro Thiago/cliente.

**Constante compartilhada:** chave XOR `4A7B9CE32FA568D13B76C912EF458A1DB4592CF7639E3154A87DC2164E9328BF`; endpoint `https://streamapps.dev/saplayer/api/auth.php`; UA `smart-tv`; `app_type = "roku"`.

---

## Task 0: Scaffold de tooling + baseline de compilação

**Files:**
- Create: `package.json`, `bsconfig.json`

- [ ] **Step 1: Criar `package.json`**

```json
{
  "name": "roku-saplayer",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "lint": "brighterscript --project bsconfig.json --create-package false"
  },
  "devDependencies": {
    "brighterscript": "^0.72.4"
  }
}
```

- [ ] **Step 2: Criar `bsconfig.json`** (aponta pra raiz do canal, sem empacotar)

```json
{
  "rootDir": "app",
  "files": ["manifest", "source/**/*", "components/**/*"],
  "createPackage": false,
  "diagnosticFilters": [1107, 1001]
}
```
> `1107`/`1001` filtram "componente referenciado fora do projeto" e warnings de libs SceneGraph nativas. Ajustar a lista após o primeiro run (ver Step 3).

- [ ] **Step 3: Rodar baseline e registrar erros pré-existentes**

Run: `cd /root/roku-app && npx brighterscript --project bsconfig.json --create-package false 2>&1 | tail -30`
Expected: compila a source atual. Anotar diagnósticos pré-existentes num comentário do commit — qualquer erro NOVO introduzido nas tasks seguintes deve ser comparado contra esse baseline. (A source é de terceiro; pode haver warnings legados — o objetivo é **não adicionar erros novos**, não zerar os legados.)

- [ ] **Step 4: Commit**

```bash
cd /root/roku-app
git add package.json bsconfig.json
git commit -m "build: brighterscript lint/compile config + baseline"
```

---

## Task 1: Harness de contrato — fluxo A (reseller_dns) ao vivo

**Files:**
- Modify: `tools/panel_probe.py`

Esse harness é a **fonte de verdade do protocolo**: o que ele valida ao vivo é o que o BrightScript precisa reproduzir byte a byte.

- [ ] **Step 1: Escrever o harness com asserts (substitui o probe atual)**

```python
#!/usr/bin/env python3
"""Harness de contrato do painel S.A Player (auth.php). Roda contra o painel AO VIVO.
Uso:
  python3 tools/panel_probe.py reseller_dns <code>
  python3 tools/panel_probe.py poll <device_id>
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
        a = base(sys.argv[2], 'login')  # poll usa version default; ver Task 9 p/ confirmar valor exato
        r = call(a)
        print(json.dumps(r, ensure_ascii=False, indent=2)); sys.exit(0)
    if cmd == 'login':
        assert os.environ.get('PANEL_ALLOW_WRITE') == '1', 'login GRAVA no painel; rode com PANEL_ALLOW_WRITE=1 e conta de TESTE'
        a = base('roku-probe-0001', 'login')
        a.update(id_user=sys.argv[2], dns_id=sys.argv[3], username=sys.argv[4], password=sys.argv[5], auth_url=sys.argv[6])
        print(json.dumps(call(a), ensure_ascii=False, indent=2)); sys.exit(0)
    print('comando desconhecido'); sys.exit(1)
```

- [ ] **Step 2: Rodar fluxo A com revendedor ativo**

Run: `cd /root/roku-app && python3 tools/panel_probe.py reseller_dns 123`
Expected: JSON com `"success": true` e `"dns": [{"url": "http://str7.vip", ...}]`.

- [ ] **Step 3: Rodar fluxo A com revendedor expirado (caminho de erro)**

Run: `python3 tools/panel_probe.py reseller_dns 2`
Expected: `"success": false`, `"message": "Revendedor expirado"`.

- [ ] **Step 4: Conferir cálculo do MAC**

Run: `python3 tools/panel_probe.py mac roku-probe-0001`
Expected: um MAC tipo `XX:XX:XX:XX:XX:XX` (anotar o valor — vira o esperado do teste de parI no Task 2).

- [ ] **Step 5: Commit**

```bash
git add tools/panel_probe.py
git commit -m "test: harness de contrato do painel (fluxo reseller_dns ao vivo)"
```

---

## Task 2: `PanelClient.brs` — crypto + MAC (parI com o painel)

**Files:**
- Create: `app/source/PanelClient.brs`

BrightScript: Base64 via `roByteArray` (`.FromBase64String`/`.ToBase64String`), SHA256 via `roEVPDigest`, XOR byte a byte.

- [ ] **Step 1: Escrever as primitivas**

```brightscript
' Camada de protocolo do painel S.A Player (auth.php).
function panelConst() as Object
    return {
        url: "https://streamapps.dev/saplayer/api/auth.php",
        ua: "smart-tv",
        appType: "roku",
        keyHex: "4A7B9CE32FA568D13B76C912EF458A1DB4592CF7639E3154A87DC2164E9328BF"
    }
end function

' hex string -> roByteArray
function panelKeyBytes() as Object
    ba = CreateObject("roByteArray")
    ba.FromHexString(panelConst().keyHex)
    return ba
end function

' XOR de um roByteArray com a chave repetida -> roByteArray
function panelXorBytes(data as Object) as Object
    key = panelKeyBytes()
    klen = key.Count()
    out = CreateObject("roByteArray")
    for i = 0 to data.Count() - 1
        out.Push(data[i] xor key[i mod klen])
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

' device id -> MAC igual ao do painel: SHA256, 12 hex, 1o byte & 0xFC
function panelDeviceMac(deviceId as String) as String
    digest = CreateObject("roEVPDigest")
    digest.Setup("sha256")
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(deviceId)
    hex = digest.Process(ba)          ' retorna hex string
    h = LCase(Left(hex, 12))
    firstByte = (HexToInt(Left(h, 2)) and 252)   ' 0xFC
    macHex = Right("0" + IntToHex(firstByte), 2) + Mid(h, 3)
    mac = ""
    for i = 1 to 11 step 2
        if mac <> "" then mac = mac + ":"
        mac = mac + Mid(macHex, i, 2)
    end for
    return UCase(mac)
end function

function HexToInt(h as String) as Integer
    return Val("&H" + h)
end function

function IntToHex(n as Integer) as String
    digits = "0123456789ABCDEF"
    return Mid(digits, (n \ 16) + 1, 1) + Mid(digits, (n mod 16) + 1, 1)
end function
```

- [ ] **Step 2: Compilar (sem erro novo)**

Run: `cd /root/roku-app && npx brighterscript --project bsconfig.json --create-package false 2>&1 | grep -iE "PanelClient|error" | head`
Expected: nenhum `error` apontando pra `PanelClient.brs`.

- [ ] **Step 3: Validar a parI do MAC contra a referência Python**

A função `panelDeviceMac` deve produzir o MESMO MAC que `tools/panel_probe.py mac <id>` (ambos = SHA256→12hex→&0xFC). Conferir manualmente: o algoritmo é idêntico linha a linha. Registrar no commit o MAC esperado de `roku-probe-0001` (do Task 1 Step 4) como referência.
> Se houver acesso ao interpretador `brs` (node) num passo futuro, criar um teste que executa `panelDeviceMac` e compara com o valor Python. Por ora a parI é garantida por equivalência de algoritmo + o teste ao vivo do Task 9 (o painel aceitar o MAC prova a igualdade na prática).

- [ ] **Step 4: Commit**

```bash
git add app/source/PanelClient.brs
git commit -m "feat: PanelClient crypto (XOR+Base64) e MAC (SHA256) do painel"
```

---

## Task 3: `PanelClient.brs` — HTTP + 3 fluxos

**Files:**
- Modify: `app/source/PanelClient.brs`

> `roUrlTransfer` é síncrono via `roMessagePort`. Estas funções rodam dentro de uma Task node (thread separada), nunca na render thread.

- [ ] **Step 1: POST cru com UA smart-tv**

```brightscript
' Faz POST {"data": payload} e devolve o objeto decriptado, ou invalid.
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
```

- [ ] **Step 2: Os 3 fluxos**

```brightscript
' Fluxo A: codigo do revendedor -> lista de DNS
function panelResellerDns(deviceId as String, code as String) as Object
    return panelPost({ app_device_id: deviceId, version: "reseller_dns", id_user: code })
end function

' Fluxo B: valida/registra login (GRAVA no painel, vincula o MAC ao revendedor)
function panelLogin(deviceId as String, code as String, dnsId as String, user as String, pass as String, authUrl as String) as Object
    return panelPost({ app_device_id: deviceId, version: "login", id_user: code, dns_id: dnsId, username: user, password: pass, auth_url: authUrl })
end function

' Fluxo C: poll por MAC -> branding + portal + auto-login
function panelPoll(deviceId as String) as Object
    return panelPost({ app_device_id: deviceId, version: "login" })
end function
```
> Nota: o `version` exato do poll (fluxo C, sem credenciais) será confirmado no Task 9 Step 1 contra o painel ao vivo; ajustar a string aqui se necessário (o `auth.php` cai no bloco default quando não é `reseller_dns`/`login`/`logout`).

- [ ] **Step 3: Compilar**

Run: `cd /root/roku-app && npx brighterscript --project bsconfig.json --create-package false 2>&1 | grep -iE "PanelClient.*error" | head`
Expected: vazio.

- [ ] **Step 4: Commit**

```bash
git add app/source/PanelClient.brs
git commit -m "feat: PanelClient HTTP + fluxos reseller_dns/login/poll"
```

---

## Task 4: Boot por MAC + branding dinâmico

**Files:**
- Modify: `app/source/config.brs:1-55`
- Modify: `app/source/main.brs:47-69`

- [ ] **Step 1: Reescrever `cargarConfigRemota()` pra usar o poll por MAC**

Substituir o corpo (linhas 1-55 de `config.brs`) por:

```brightscript
function cargarConfigRemota() as Object
    deviceId = CreateObject("roDeviceInfo").GetChannelClientId()
    mac = panelDeviceMac(deviceId)

    ensureGlobalAssetFields()

    poll = panelPoll(deviceId)
    configArray = []

    if poll <> invalid
        ' Branding SEMPRE vem do painel (mesmo MAC novo recebe default do painel)
        applyPanelBranding(poll)

        ' Auto-login SO quando ha portal real (urls != vazio). mac_registered
        ' volta true mesmo sem cadastro, entao NAO serve de criterio.
        portal = poll.urls
        if portal <> invalid and GetInterface(portal, "ifArray") <> invalid and portal.Count() > 0
            for each u in portal
                if u <> invalid and u <> ""
                    configArray.Push({ serverURL: u, appName: pollAppName(poll), version: "4.5", api_key: "46270abd00c39663cde5d450ff83cbb8" })
                end if
            end for
        else if portal <> invalid and Type(portal) = "roString" and portal <> ""
            configArray.Push({ serverURL: portal, appName: pollAppName(poll), version: "4.5", api_key: "46270abd00c39663cde5d450ff83cbb8" })
        end if
    end if

    ' Fallback offline / poll falhou: assets S.A Player embutidos + sem auto-login.
    if poll = invalid
        applyGlobalAssetDefaults()
    end if

    ' configArray vazio => sem auto-login => app abre na LoginScreen (com branding do painel ja aplicado).
    ' A lista de DNS do login vem do fluxo A (codigo do revendedor), NAO da lista global do poll.
    return configArray
end function

function pollAppName(poll as Object) as String
    if poll.app_name <> invalid and poll.app_name <> "" then return poll.app_name
    return "S.A Player"
end function

' Mapeia os campos do painel para os globais de branding ja usados pelo app
sub applyPanelBranding(poll as Object)
    version = mid(str(int(rnd(0) * 10000)), 2)
    if poll.img_logo <> invalid and poll.img_logo <> ""
        m.global.logo = addCacheBuster(poll.img_logo, version)
        m.global.logologin = addCacheBuster(poll.img_logo, version)
        m.global.logomenu = addCacheBuster(poll.img_logo, version)
    end if
    if poll.img_bg <> invalid and poll.img_bg <> ""
        m.global.fondo = addCacheBuster(poll.img_bg, version)
    end if
    if poll.app_name <> invalid and poll.app_name <> ""
        m.global.titulo = poll.app_name
    end if
end sub
```
> `applyGlobalAssetDefaults()` e `ensureGlobalAssetFields()` já existem na source (mantêm o default). Garantir que o asset default empacotado seja o **logo S.A Player** (Task 7).

- [ ] **Step 2: Expor o MAC nos globais (em `main.brs:initGlobals`)**

Após a linha `m.global.setField("rokuUniqueID", getDeviceESN())` (main.brs:69), adicionar:

```brightscript
    m.global.AddField("deviceMac", "string", true)
    m.global.setField("deviceMac", panelDeviceMac(getDeviceESN()))
```

- [ ] **Step 3: Compilar**

Run: `cd /root/roku-app && npx brighterscript --project bsconfig.json --create-package false 2>&1 | grep -iE "config.brs.*error|main.brs.*error" | head`
Expected: vazio.

- [ ] **Step 4: Commit**

```bash
git add app/source/config.brs app/source/main.brs
git commit -m "feat: boot faz poll por MAC (branding do revendedor + default S.A Player)"
```

---

## Task 5: LoginScreen — campo Código + exibir MAC + remover código velho

**Files:**
- Modify: `app/components/screens/LoginScreen/LoginScreen.xml`
- Modify: `app/components/screens/LoginScreen/LoginScreen.brs`

- [ ] **Step 1: Add campo "Código do revendedor" no XML**

Em `LoginScreen.xml`, dentro do `layoutGroup id="grp"`, ANTES do `userEditBox`, adicionar um campo no mesmo padrão (copiando a estrutura do `userEditBox`):

```xml
                <Poster id ="codeEditBox" uri="pkg:/images/login/user-edit.png">
                    <textEditBox id = "codeTextEditBox" hintText = " Codigo do revendedor" hintTextColor = "#313233" clearOnDownKey = "false" backgrounduri = "pkg:/images/login/transparent.png" />
                </Poster>
```

E adicionar um terceiro `LoginKeyboard id="codeKeyboard" visible="false"` dentro do `keyBox`, irmão de `userKeyboard`/`passKeyboard`.

- [ ] **Step 2: Reaproveitar `codeBox` pra exibir o MAC**

Em `LoginScreen.xml`, no painel `codeBox` (Sistema de Códigos), trocar os textos:
- `codeInstructionLabel.text` → `"MAC do seu aparelho — informe ao seu revendedor:"`
- `activationCodeLabel.text` → mantém `"--------"` (preenchido em runtime)
- `codeStatusLabel` → remover ou esvaziar.
E **remover** o `regenerateButton` ("Novo Código") do XML.

- [ ] **Step 3: No `LoginScreen.brs init()`, exibir o MAC e bindar o novo campo**

- Adicionar `"codeEditBox"`, `"codeTextEditBox"`, `"codeKeyboard"` no `mBind([...])` (linhas 3-6).
- Adicionar observação do teclado do código (espelhar `userKeyboard`):
```brightscript
    m.codeKeyboard.textEditBox.voiceEnabled = true
    m.codeKeyboard.observeFieldScoped("continue", "doNext")
    m.codeKeyboard.observeFieldScoped("left", "doLeft")
    m.codeKeyboard.observeFieldScoped("right", "doRight")
    m.codeKeyboard.observeField("focusedChild", "onFocusChain")
    m.codeKeyboard.ObserveField("text", "OnKeyboardTextChanged")
```
- Exibir o MAC:
```brightscript
    m.codeBox.visible = true
    m.activationCodeLabel.text = m.global.deviceMac
```

- [ ] **Step 4: Remover o sistema de código velho do `.brs`**

Apagar de `LoginScreen.brs`: criação de `m.getCodeTask`/`m.validateCodeTask` (linhas ~111-114), `m.regenerateButton.observeField(...)` (linha ~109), e as subs `generateActivationCode`, `onRegenerateCode`, `onCodeGenerated`, `onCodeValidated`, `onValidateCodeError`, `autoLogin` (linhas ~129-201). Substituídas pelo MAC estático + poll do boot.

- [ ] **Step 5: Remover as tasks velhas do projeto**

```bash
cd /root/roku-app
git rm app/components/tasks/GetCodeTask.xml app/components/tasks/ValidateCodeTask.xml app/components/tasks/LoginTask.xml
```
> Conferir antes com `grep -rl "GetCodeTask\|ValidateCodeTask\|LoginTask" app/` que nenhuma OUTRA tela referencia essas tasks. Se referenciar, limpar a referência no mesmo commit.

- [ ] **Step 6: Compilar**

Run: `cd /root/roku-app && npx brighterscript --project bsconfig.json --create-package false 2>&1 | grep -iE "LoginScreen.*error" | head`
Expected: vazio.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: LoginScreen com campo Codigo + exibe MAC; remove sistema de codigo velho"
```

---

## Task 6: Wiring do login (Código → DNS → Login → Xtream)

**Files:**
- Modify: `app/components/screens/LoginScreen/LoginScreen.brs` (`onValidateLogin`)
- Create: `app/components/tasks/PanelLoginTask.xml` + `.brs`

> A rede tem que rodar em Task node (fora da render thread). Criamos `PanelLoginTask` que faz reseller_dns + login e devolve o resultado.

- [ ] **Step 1: Criar `PanelLoginTask.xml`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<component name="PanelLoginTask" extends="Task">
    <script type="text/brightscript" uri="PanelLoginTask.brs"/>
    <script type="text/brightscript" uri="pkg:/source/PanelClient.brs"/>
    <interface>
        <field id="code" type="string"/>
        <field id="user" type="string"/>
        <field id="pass" type="string"/>
        <field id="result" type="assocarray"/>
        <field id="run" type="boolean" alwaysNotify="true" onChange="start"/>
    </interface>
</component>
```

- [ ] **Step 2: Criar `PanelLoginTask.brs`**

```brightscript
sub init()
    m.top.functionName = "run"
end sub

sub run()
    deviceId = CreateObject("roDeviceInfo").GetChannelClientId()
    out = { success: false, message: "Falha desconhecida", dns: invalid }

    dnsResp = panelResellerDns(deviceId, m.top.code)
    if dnsResp = invalid or dnsResp.success <> true
        if dnsResp <> invalid and dnsResp.message <> invalid then out.message = dnsResp.message
        m.top.result = out : return
    end if

    ' usa a 1a DNS do revendedor (igual Android: valida user/senha contra ela)
    firstDns = dnsResp.dns[0]
    authUrl = firstDns.url
    loginResp = panelLogin(deviceId, m.top.code, firstDns.id, m.top.user, m.top.pass, authUrl)
    if loginResp = invalid or loginResp.success <> true
        if loginResp <> invalid and loginResp.message <> invalid then out.message = loginResp.message
        m.top.result = out : return
    end if

    out.success = true
    out.dns = dnsResp.dns
    out.serverURL = authUrl
    m.top.result = out
end sub
```

- [ ] **Step 3: Reescrever `onValidateLogin` no `LoginScreen.brs`**

```brightscript
sub onValidateLogin()
    code = m.codeTextEditBox.text
    user = m.userTextEditBox.text
    pass = m.passTextEditBox.text
    if code = "" or user = "" or pass = ""
        m.codeStatusLabel.text = tr("Preencha codigo, usuario e senha")
        return
    end if

    m.panelLoginTask = createObject("roSGNode", "PanelLoginTask")
    m.panelLoginTask.code = code
    m.panelLoginTask.user = user
    m.panelLoginTask.pass = pass
    m.panelLoginTask.observeField("result", "onPanelLoginResult")
    m.panelLoginTask.run = true
end sub

sub onPanelLoginResult()
    res = m.panelLoginTask.result
    if res = invalid or res.success <> true
        msg = "Login invalido"
        if res <> invalid and res.message <> invalid then msg = res.message
        m.codeStatusLabel.text = tr(msg)
        return
    end if

    ' Popula servidores do revendedor e guarda credenciais (padrao da source)
    servers = []
    for each d in res.dns
        if d.url <> invalid and d.url <> ""
            servers.Push({ serverURL: d.url, appName: "S.A Player", version: "4.5", api_key: "46270abd00c39663cde5d450ff83cbb8" })
        end if
    end for
    m.global.setField("config_activa", servers)
    m.global.config = servers[0]
    regWrite("userTV", m.userTextEditBox.text, servers[0].appName)
    regWrite("passTV", m.passTextEditBox.text, servers[0].appName)

    ' Reusa o ConfirmUserTask (validacao Xtream) e segue o fluxo existente de sucesso
    m.top.success = true
end sub
```
> O fluxo de "sucesso" (`m.top.success`) já é observado pela MainScene/LoginScreenLogic existente, que dispara `ConfirmUserTask` e a navegação pra grade. Conferir `LoginScreenLogic.brs` e reusar o mesmo gatilho — NÃO criar navegação nova.

- [ ] **Step 4: Compilar**

Run: `cd /root/roku-app && npx brighterscript --project bsconfig.json --create-package false 2>&1 | grep -iE "error" | grep -iE "LoginScreen|PanelLoginTask" | head`
Expected: vazio.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: wiring do login (codigo->DNS->login->Xtream) via PanelLoginTask"
```

---

## Task 7: Fallback de branding offline S.A Player (splash + assets embutidos)

**Files:**
- Modify: `app/images/` (logo/splash default), `app/manifest`

> Descoberta na homologação ao vivo: o **branding default vem do próprio painel** (poll devolve `app_name`/`img_logo`/`img_bg` mesmo pra MAC novo). O cliente controla a marca neutra no painel dele. Portanto NÃO hardcodar "S.A Player" no app — só garantir um **fallback decente** quando o poll falha (sem internet) e a **splash** do canal.

- [ ] **Step 1: Splash + logo fallback S.A Player**

Substituir a splash (`manifest`: `splash_screen_*`) e o `pkg:/images/logologin.png`/`logo.png` (usados por `applyGlobalAssetDefaults` quando o poll falha) pela arte **S.A Player** (fornecida pelo cliente ou extraída do Android).

Run (candidatos de arte do Android pra reuso):
`find /root/appfinal_extract -iname "*logo*" -o -iname "*splash*" -o -iname "*ic_launcher*" | head -20`

- [ ] **Step 2: `pollAppName` fallback**

Confirmar que `pollAppName` (Task 4) retorna `"S.A Player"` só quando o poll não traz `app_name`. (Caso normal: usa o nome que o painel mandar.)

- [ ] **Step 3: Compilar + commit**

```bash
cd /root/roku-app
npx brighterscript --project bsconfig.json --create-package false 2>&1 | grep -i error | head
git add -A
git commit -m "feat: branding default S.A Player (logo + nome)"
```

---

## Task 8: Empacotamento sideload-ready

**Files:**
- Create: `tools/build.sh`

- [ ] **Step 1: Criar `tools/build.sh`**

```bash
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
OUT="out/saplayer-roku.zip"
mkdir -p out
rm -f "$OUT"
cd app
zip -r -q "../$OUT" manifest source components images fonts locale json \
    -x "*.bak" -x "*.DS_Store"
cd ..
echo "Pacote: $OUT"
unzip -l "$OUT" | tail -5
```

- [ ] **Step 2: Gerar o pacote**

Run: `cd /root/roku-app && chmod +x tools/build.sh && ./tools/build.sh`
Expected: `out/saplayer-roku.zip` criado, com `manifest` na raiz do zip (não dentro de subpasta — requisito do sideload Roku).

- [ ] **Step 3: Commit**

```bash
git add tools/build.sh
git commit -m "build: script de empacotamento sideload Roku"
```

---

## Task 9: Homologação ao vivo + checklist de device

**Files:**
- Create: `docs/HOMOLOGACAO.md`

- [ ] **Step 1: Confirmar o `version` do poll (fluxo C) ao vivo**

Run: `cd /root/roku-app && python3 tools/panel_probe.py poll roku-probe-0001`
Expected: resposta do painel pro MAC novo (provavelmente "sem playlist"/branding default). Anotar o shape real (`img_logo`, `img_bg`, `app_name`, `dns`/`urls`) e **ajustar `panelPoll`/`applyPanelBranding`** se os nomes de campo diferirem. Se "login" não for o `version` certo pro poll, testar com outro valor e fixar.

- [ ] **Step 2: Login ponta a ponta (com conta de TESTE do cliente)**

Pré-requisito: cliente fornece **código de revendedor ativo + usuário/senha de teste**.
Run: `PANEL_ALLOW_WRITE=1 python3 tools/panel_probe.py login <code> <dns_id> <user> <pass> <auth_url>`
Expected: `"success": true`. Confirma o fluxo B (registro/vínculo de MAC) ponta a ponta antes do device.
> Sem a conta de teste, este passo fica pendente — registrar em HOMOLOGACAO.md.

- [ ] **Step 3: Escrever `docs/HOMOLOGACAO.md`** (checklist pro device)

```markdown
# Homologação — App Roku S.A Player

## Pré-requisitos
- Roku em modo desenvolvedor (Home x3, Up x2, Right, Left, Right, Left, Right).
- IP do Roku + senha do dev server.
- Código de revendedor ATIVO + usuário/senha de teste (do cliente).

## Sideload
1. Acessar `http://<IP_DO_ROKU>` → Development Application Installer.
2. Upload `out/saplayer-roku.zip` → Install.

## Casos de teste
- [ ] App abre mostrando branding **S.A Player** (MAC novo, sem cadastro).
- [ ] Tela de login mostra o **MAC do aparelho** embaixo.
- [ ] Login com **código + usuário + senha** de teste → entra na grade.
- [ ] Conferir no painel que o **MAC foi vinculado** ao revendedor.
- [ ] Cadastrar o MAC no painel manualmente, reabrir o app → **auto-login** + branding do revendedor (logo/fundo).
- [ ] Código inválido → mensagem "Revendedor não encontrado".
- [ ] Revendedor expirado → mensagem "Revendedor expirado".
```

- [ ] **Step 4: Commit**

```bash
git add docs/HOMOLOGACAO.md tools/panel_probe.py
git commit -m "docs: checklist de homologacao + poll confirmado ao vivo"
```

---

## Desvios na execução (vs. plano original)

- **Task 5/6:** em vez de criar um `PanelLoginTask` separado, os fluxos do painel (reseller_dns + login) foram integrados DENTRO do `LoginTask` existente (que já validava Xtream e dispara o caminho de sucesso). Menos código novo, reusa toda a navegação de sucesso. O `LoginTask` ganhou os campos `code`/`errorMsg` e o include `PanelClient.brs`.
- **Ordem de validação:** valida user/senha via Xtream ANTES de chamar o `login` do painel — assim não registra credencial inválida (não consome slot de plano à toa).
- **Tasks removidas:** só `GetCodeTask` + `ValidateCodeTask` (código velho zedplayer). `LoginTask` foi **mantido e estendido** (não removido — é o validador ativo).
- **Branding default:** veio a confirmação ao vivo de que o painel serve o branding mesmo pra MAC novo, então o app NÃO hardcoda "S.A Player"; usa o que o painel manda e cai no logo embutido só offline.

## Notas de verificação (limites honestos)

- **Validável aqui:** contrato de rede (probe Python ao vivo, fluxos A/B/C), compilação BrightScript (`brighterscript`), empacotamento `.zip`.
- **Só no device:** render da UI, navegação, players de vídeo, auto-login visual. Depende de Roku físico em modo dev + conta de teste do cliente (Task 9).
- **Pendências externas:** logo/arte S.A Player oficial (cliente) e credencial de revendedor de teste ativo (cliente).
