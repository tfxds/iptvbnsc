# Homologação — App Roku S.A Player

## O que já foi validado AO VIVO (sem device, contra o painel real)
- **Protocolo** (`auth.php`): XOR+Base64 + UA `smart-tv` — criptografia byte-perfeita.
  - Fluxo A (`reseller_dns`): código ativo → DNS; expirado → erro. ✅
  - **Login Xtream**: credencial real de revendedor → `auth=1 status=Active`. ✅
  - Fluxo B (`login`): registrou MAC ("Login salvo com sucesso"). ✅
  - Fluxo C (`poll`): após registro, retornou o portal (get.php m3u_plus) — dados do auto-login. ✅
  - `logout`: limpou o MAC de teste ("cleared_count:1") — base deixada como estava. ✅
  - **MAC**: o painel devolveu o mesmo MAC que o app calcula (`SHA256`) — parI ponta a ponta. ✅
- Teste reversível feito com conta **desativada** (code 575) + register→logout, sem afetar cliente ativo.
- **XOR** do BrightScript provado em 65536/65536 pares.
- **Compilação** BrightScript: 0 erros novos sobre o baseline da source.
- **Pacote**: `out/saplayer-roku.zip` (manifest na raiz, pronto pra sideload).

> Logo, o ciclo COMPLETO (código→DNS→login→registro→portal→logout) está provado contra o painel real. Falta só rodar a UI num Roku físico.

## Pré-requisitos pro teste no device
- Roku em **modo desenvolvedor** (Home×3, Up×2, Right, Left, Right, Left, Right → habilitar).
- IP do Roku + senha do dev server.
- **Do cliente**: um **código de revendedor ATIVO** + **usuário/senha de teste** válidos nesse revendedor.
- (Opcional) arte oficial **S.A Player** em alta pra splash/ícone do canal.

## Sideload
1. Acessar `http://<IP_DO_ROKU>` → Development Application Installer.
2. Upload `out/saplayer-roku.zip` → **Install**.

## Casos de teste
- [ ] App abre mostrando **branding S.A Player** (MAC novo, sem cadastro).
- [ ] Tela de login mostra os 3 campos: **Código do revendedor / Usuário / Senha**.
- [ ] Embaixo aparece o **MAC do aparelho** ("informe ao seu revendedor").
- [ ] Login com **código + usuário + senha** de teste → entra na grade (canais/filmes/séries).
- [ ] Conferir no painel que o **MAC foi vinculado** ao revendedor.
- [ ] Cadastrar o MAC no painel manualmente, reabrir o app → **auto-login** + branding (logo/fundo) do revendedor.
- [ ] Código **inválido** → mensagem "Revendedor não encontrado".
- [ ] Revendedor **expirado** → mensagem "Revendedor expirado".
- [ ] Usuário/senha errados → "Usuário ou senha inválidos" (sem vincular no painel).

## Teste de login ao vivo (antes do device, opcional)
Com conta de teste do cliente, validar o fluxo B (registro/vínculo) ponta a ponta:
```
PANEL_ALLOW_WRITE=1 python3 tools/panel_probe.py login <code> <dns_id> <user> <pass> <auth_url>
```
Esperado: `"success": true`.

## Ajustes que provavelmente precisam de tuning NO device
- Navegação de foco do teclado entre os 3 campos (código→usuário→senha→login) — lógica implementada seguindo o padrão da source, mas só dá pra calibrar visualmente no aparelho.
- Posição/tamanho do label do MAC e dos campos na tela.
- Splash/ícone do canal (trocar pela arte oficial S.A Player se o cliente enviar).
