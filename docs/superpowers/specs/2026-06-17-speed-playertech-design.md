# Speed PlayerTech — App Roku (design)

Data: 2026-06-17
Base: cópia do app Roku saplayer em `/root/roku-app-cliente2` (manifest 4.4.94), isolada do
canal saplayer publicado/aprovado. Objetivo: transformar a cópia no app **Speed PlayerTech**
(cliente SpeedTech/BNSC), com backend próprio, marca própria e home redesenhada.

## Escopo

Duas fases independentes, cada uma buildável e testável.

### Fase 1 — Marca + backend ("virar Speed PlayerTech")

**1.1 Assets default de marca** (a lógica de branding por revenda já existe; só trocar os
embutidos em `source/assets.brs` → `getDefaultAssets()`):

| Asset | Default embutido (marca) | Com revendedor no painel |
|---|---|---|
| `logologin` (tela de login) | **SpeedTech (fundo branco)** | **TRAVA na marca — não pega do revendedor** |
| `logomenu` / `logo` (home/menu) | SpeedTech (fallback) | pega `img_logo` do revendedor |
| `fondo` (fundo geral) | `bg.png` | pega `img_bg` do revendedor |
| nome de exibição (`titulo`) | "Speed PlayerTech" | pega `app_name` do revendedor |

**Mudança de comportamento** em `source/config.brs` → `applyPanelBranding(poll)`: hoje
sobrescreve `logo`, `logologin` e `logomenu` com `img_logo` do revendedor. Passa a
sobrescrever **só `logo` e `logomenu`**; `logologin` fica fixo na marca Speed PlayerTech.

**Arquivos de imagem** a adicionar em `app/images/`:
- `bg.png` (fundo, fonte: `/root/roku-app-cliente2/bg.png`, 1280×720)
- logo login: `icon-512x512.png` (logo c/ fundo branco) e/ou `SpeedTech.png` (wide, transparente)
- ícone/poster do canal Roku (tamanhos exigidos pela Roku: FHD 540×405, HD 290×218, SD 246×140)

**1.2 Backend** → `source/PanelClient.brs` → `panelConst().url` aponta pra instância BNSC
em `https://streamplayer.gerenciapro.top/bnsc` (painel "SA Player" confirmado nesse domínio).
- Path exato do `auth.php` do app: **a confirmar** ao vivo (o painel web está em `/bnsc`; a
  rota que o app consome fica em path próprio). Validar `keyHex` e `api_key` — provavelmente
  iguais por ser o mesmo software; testar `poll` ao vivo antes de fechar.
- `appName` interno (namespace de registry/PIN/credenciais): trocar de "S.A Player" para
  "SpeedPlayerTech" (não colidir com credenciais salvas do saplayer no mesmo aparelho).

**1.3 Manifest** (`app/manifest`): `title=Speed PlayerTech`; resetar versão (ex.: build 1) por
ser canal novo; splash/ícones próprios.

### Fase 2 — Home redesenhada (layout do print Vizzion)

Criar **HomeScreen nova** ao lado do `MenuScreen` atual (não reescrever por cima — risco baixo,
o menu antigo segue como fallback/comparação). Layout aprovado via mockup
(`mockup_home.png`):

- **Sidebar vertical à esquerda**: logo do **revendedor** no topo → itens
  `Pesquisar · Início · TV ao vivo · Filmes · Séries · Listas · Configurações · Atualizar lista`
  → item ativo em pílula gradiente roxo→azul → rodapé "Mac ativado (DNS)" + endereço MAC.
- **Conteúdo à direita** (linhas roláveis tipo RowList):
  - **Continuar assistindo** — filmes em andamento, **por aparelho** (progresso salvo no
    registry local do Roku; barra de progresso no card landscape).
  - **Séries assistidas** — por aparelho (registry local).
  - **Últimos lançamentos** — da API de VOD/Séries do painel, ordenado pelos mais recentes.
- Fundo: `fondo` (bg.png default, ou o do revendedor).
- Reaproveitar componentes de card e a lógica de catálogo já existentes no app.

**Persistência "continuar assistindo"** (por aparelho): gravar no registry (namespace do app)
`{streamId, tipo, posição, duração, título, poster, timestamp}` ao sair do player; ler na
montagem da Home pra montar as duas primeiras linhas (filmes e séries).

## Fora de escopo (YAGNI)
- Sincronização de progresso entre aparelhos (decidido: por aparelho).
- Mexer no canal saplayer original (`/root/roku-app`) — intocado.
- Publicar na Roku agora (gerar chave de assinatura própria fica pra quando for publicar).

## Riscos / a validar
- Path e chave do `auth.php` da instância BNSC (validar ao vivo antes da Fase 1.2).
- API de catálogo: confirmar que o app já expõe "VOD/Séries ordenado por mais recente" para
  a linha "Últimos lançamentos".
- Logo do revendedor pode vir clara ou escura — a sidebar precisa funcionar com ambas.
