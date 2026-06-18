# Spec — App Roku S.A Player (integração ao painel de revenda)

**Data:** 2026-06-08
**Projeto:** Adaptar a source Roku comprada para funcionar no painel de revenda do cliente (`streamapps.dev/saplayer`), igual ao app Android já existente.
**Status:** Aprovado para implementação.

---

## 1. Objetivo

O cliente vende um app reprodutor de listas IPTV (M3U / Xtream) em modelo **whitelabel de revenda**. Hoje ele tem o app **Android** funcionando no painel dele. Comprou uma **source Roku** que só sabe logar com usuário+senha contra outro painel (zedplayer). 

A tarefa é fazer **o app Roku falar exatamente o mesmo protocolo do painel do cliente**, sem alterar nada do lado Android e respeitando todas as regras que já existem no painel.

O app deve oferecer os **dois caminhos de vínculo** que o Android oferece:
1. **Login** — cliente digita **código do revendedor + usuário + senha** → o app valida e vincula o cliente no painel do revendedor.
2. **MAC** — o app exibe o MAC do aparelho; o revendedor cadastra esse MAC no painel e vincula a lista; o app passa a funcionar sem o cliente digitar nada.

**Branding padrão (neutro):** nome **"S.A Player"** + logo do S.A Player (mesma identidade do Android). Cada revendedor sobrescreve logo / plano de fundo / tema / nome via painel.

---

## 2. Contrato do painel (VALIDADO AO VIVO em 2026-06-08)

Endpoint: `POST https://streamapps.dev/saplayer/api/auth.php`

Regras de transporte (replicadas e testadas com sucesso):
- **Header obrigatório:** `User-Agent: smart-tv` (sem isso → cai no 404.html).
- **Corpo:** `{"data": "<base64(xor(json))>"}`.
- **Criptografia:** XOR com chave fixa de 32 bytes (`hex 4A7B…28BF`), repetida sobre o payload, depois Base64. Simétrica (mesma função encripta e decripta).
- **Resposta:** `{"data": "<base64(xor(json))>"}` — decripta com a mesma rotina.
- Campos obrigatórios em todo payload: `app_device_id`, `app_type`, `version`.

O `version` seleciona o fluxo:

### Fluxo A — `reseller_dns` (lê DNS do revendedor) — read-only
Entrada: `id_user` = código do revendedor.
Saída: `{ success, reseller_id, dns: [ { id, title, url } ] }`.
Erros tratados: "Revendedor não encontrado", "Revendedor expirado", "Nenhuma DNS liberada".

**Teste ao vivo:** code `123` → DNS `http://str7.vip` ✅ · code `11/TECTV/25` (ativos) → DNS certo ✅ · code `2`/`200` (expirados) → "Revendedor expirado" ✅ · UA errado → bloqueado ✅.

### Fluxo B — `login` (valida user/senha e registra/vincula) — ESCRITA na produção
Entrada: `id_user`, `dns_id`, `username`, `password`, `auth_url`.
O painel: valida que a DNS pertence ao revendedor, checa o limite do plano do revendedor, e faz **upsert na tabela `playlist` pelo `mac_address`** (vincula o cliente ao revendedor).
Saída: dados da sessão / sucesso.
> Não testado ao vivo de propósito (grava MAC real e consome slot de plano). Será testado com um código de revendedor de teste ativo fornecido pelo cliente, ou contra cópia local do painel.

### Fluxo C — poll padrão (qualquer outro `version`, ex.: `login`/consulta) — branding por MAC
O painel calcula o MAC a partir do `app_device_id` (`SHA256(app_device_id)` → 12 primeiros hex → 1º byte `& 0xFC` → formato `AA:BB:...`), carrega as playlists desse MAC e devolve **portal (`urls`/`dns`), branding (`img_logo`, `img_bg`), `theme`, `app_name`, suporte/WhatsApp**. Branding por revendedor com fallback para o `config` global (S.A Player).

---

## 3. Arquitetura atual da source (o que já existe)

- **`source/main.brs` → `initGlobals()`**: no boot chama `cargarConfigRemota()`, guarda a lista de servidores em `m.global.config_activa`, e o ativo em `m.global.config`. **Já lê** `getDeviceESN()` = `roDeviceInfo.GetChannelClientId()` → `m.global.rokuUniqueID` (este será o `app_device_id`).
- **`source/config.brs` → `cargarConfigRemota()`**: bate em `https://roku.zedplayer.pp.ua/api2.php?cliente=admin` (painel velho), monta `[{serverURL, appName, version, api_key}]` e o branding global (logo/fondo/logomenu/logologin/tiles). **É o ponto central a reescrever.**
- **`components/tasks/ConfirmUserTask.brs`**: percorre `m.global.config_activa` e valida user/senha via `serverURL + "/player_api.php?username=…&password=…"` (`user_info.auth = 1`). Credenciais ficam no registry (`userTV`/`passTV` por `appName`).
- **`components/screens/LoginScreen/`**: tela com **usuário + senha** + teclados + botão LOGIN (`onValidateLogin`), e um **"Sistema de Códigos" próprio** (painel `codeBox`/`activationCodeLabel` + botão "Novo Código", tasks `GetCodeTask`/`ValidateCodeTask`/`LoginTask`) que conversa com o painel velho. **Esse sistema de código velho será removido/substituído.**
- Pontos que tocam `config_activa`/`serverURL`: `main.brs`, `config.brs`, `ConfirmUserTask.brs`, `SearchTask.brs`, `LoginTask.xml`.

---

## 4. Desenho da solução

Tela única de login (estilo Android): **Código do revendedor + Usuário + Senha** + botão Login, com o **MAC do aparelho exibido** embaixo para cadastro manual pelo revendedor.

### Bloco 1 — `PanelClient.brs` (novo, camada de rede)
Módulo BrightScript que encapsula o protocolo do `auth.php`:
- `panelXorB64(json)` / `panelDecode(data)` — XOR+Base64 com a chave fixa (via `roEVPCipher`/manipulação de bytes; XOR é trivial byte a byte).
- `panelDeviceMac(deviceId)` — `SHA256` (via `roEVPDigest`) → MAC idêntico ao do painel.
- `panelResellerDns(code)` — fluxo A.
- `panelLogin(code, dnsId, user, pass, authUrl)` — fluxo B.
- `panelPoll()` — fluxo C (branding + auto-login por MAC).
- Sempre injeta `User-Agent: smart-tv` e os campos `app_device_id`/`app_type`/`version`.

### Bloco 2 — MAC local
Calcular `panelDeviceMac(m.global.rokuUniqueID)` e expor em `m.global` para exibir na tela de login (reaproveitando o painel `codeBox`, trocando o código velho pelo MAC).

### Bloco 3 — LoginScreen (UI)
- Adicionar campo **"Código do revendedor"** (terceiro `textEditBox` + teclado, no mesmo padrão dos existentes).
- Reaproveitar o painel de código para mostrar **"MAC do seu aparelho: AA:BB:CC:…"** + instrução "Informe este MAC ao seu revendedor".
- Remover `GetCodeTask`/`ValidateCodeTask`/`LoginTask` e os handlers do código velho (`onRegenerateCode`, `onCodeGenerated`, `onCodeValidated`, `generateActivationCode`).
- `onValidateLogin`: novo fluxo → `panelResellerDns(code)` → preenche `m.global.config_activa` com as DNS do revendedor → `panelLogin(...)` → valida via Xtream (reaproveita `ConfirmUserTask`).

### Bloco 4 — Branding dinâmico
- `cargarConfigRemota()` deixa de bater no zedplayer fixo. No boot, chama `panelPoll()` (fluxo C por MAC):
  - se o MAC já está cadastrado → retorna portal + branding → **auto-login**, app abre direto na lista com a marca do revendedor.
  - se não → aplica branding **padrão S.A Player** e mostra a tela de login.
- Mapear os campos do painel (`img_logo`, `img_bg`, `theme`, `app_name`, `urls`) para os globais já usados (`logo`, `fondo`, `logologin`, `logomenu`, `titulo`, `config_activa`).

### Fluxo em runtime
```
abre app → calcula MAC → panelPoll() (fluxo C)
  ├─ MAC cadastrado  → branding do revendedor + auto-login → lista
  └─ MAC novo        → branding S.A Player → LoginScreen
                          → digita Código → panelResellerDns (fluxo A) → DNS da revenda
                          → digita Usuário+Senha → panelLogin (fluxo B, vincula) → ConfirmUserTask (Xtream) → lista
```

---

## 5. Restrições

- **Não alterar nada do lado Android** nem do painel — o app Roku só passa a consumir o protocolo já existente.
- Respeitar as regras do painel (expiração de revendedor, limite de plano, DNS pertencente ao revendedor) — todas já são impostas server-side; o app só exibe as mensagens.
- Chave XOR e UA são fixos e idênticos aos do Android (já confirmados).
- A criptografia/host **não** ficam hardcoded em texto plano "bonito" no código — replicam o que o Android já faz; sem expor segredo novo.

---

## 6. Plano de homologação / "testar funcionando"

1. **Camada de protocolo (feito):** validada ao vivo via `tools/panel_probe.py` (fluxo A + gate de UA + criptografia byte-perfeita). Estender o probe para simular o **fluxo C (poll/branding)** e, com credencial de teste, o **fluxo B (login)** ponta a ponta — provando o contrato que o BrightScript vai falar.
2. **Compilação:** validar o BrightScript com `brighterscript` (lint/compile) — sem device, pega erros de sintaxe/símbolo.
3. **Empacotamento:** gerar o `.zip` sideload-ready do canal.
4. **Device real:** Thiago (ou o cliente) faz sideload num Roku em modo dev e testa: boot por MAC, login por código+user+senha, branding do revendedor. Pré-requisito: **um código de revendedor ativo + usuário/senha de teste** fornecido pelo cliente.

> Limite honesto: a UI BrightScript não roda neste ambiente (sem Roku/emulador). O que dá pra garantir aqui é: contrato de rede 100% validado ao vivo, código que compila, e pacote pronto pra sideload. O teste visual final é no aparelho.

---

## 7. Fora de escopo

- Conteúdo/listas/servidores (responsabilidade do revendedor).
- Publicação na Roku Store (item opcional separado na proposta comercial).
- Qualquer mudança no painel ou no app Android.
- Banner/ads avançados além do que o poll já entrega (avaliar na implementação se o painel retorna banner pra Roku).
