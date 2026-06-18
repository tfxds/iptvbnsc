# Player estilo Netflix — Filmes e Séries (S.A Player / Roku)

Data: 2026-06-10
Status: aprovado (direção) — implementação por fases

## Objetivo

Reformular o player de **Filmes e Séries** com controles visíveis e navegáveis
(estilo Netflix): play/pausa, recuar/avançar 10s, **pular episódio** (próximo/anterior),
**bandeja de episódios** e **autoplay com contagem** no fim do episódio.
Pedido do Andrade (cliente/testador).

## Blast radius (mapeado)

| Player | Componente | Usado em | Afetado |
|--------|-----------|----------|---------|
| `VideoPlayer` (Player.xml/brs) | criado só por `VideoPlayerLogic.ShowVideoScreen` | **Filmes e Séries** | **SIM** |
| `Video` (nativo Roku) | `VideoLiveLogic` | Canais ao vivo | não |
| `VideoScreenDeep` | `VideoPlayerDeepLogic` | Deep link | não |

Conclusão: a reformulação fica **isolada em Filmes/Séries**. Canais ao vivo não mudam.

## Mapa do estado atual (resumo do que existe)

- **RenderlessVideo** (`enableUI=false`): decoder real. Campos relevantes: `position`,
  `progressPosition`, `duration`, `seek`, `seekdelta`, `state`, `control`,
  `contentIndex`, `nextContentIndex`, `contentIsPlaylist`, `FFRewCount`, `activeButton`.
  Tem `OnKeyEvent` próprio (tem o foco) → trata hold-to-seek, OK=pausa, replay=-20s.
- **Player.xml/brs**: overlay `transportControls` que sobe de baixo e some em 5s
  (`transportControlsTimer`). Mostra título, `stateIcon` (indicador play/pausa — NÃO é
  botão), barra de progresso + tempos, `action` (ícone +10/-10/ff). **Sem botões
  navegáveis.** `OnKeyEvent` do Player fica parcialmente sombreado pelo do RenderlessVideo.
- **VideoPlayerLogic.ShowVideoScreen(rowContent, selectedItem, isSeries)**:
  - Filme → `content = rowContent.GetChild(selectedItem)` (nó único).
  - Série → `contentIsPlaylist = true`. Dois formatos HOJE (inconsistentes):
    - via **EpisodesScreen** → episódios de **UMA temporada** (do selecionado em diante).
    - via **Detalhes > Play** → **TODAS** as temporadas concatenadas.
  - Faz resume (diálogo "Continuar"), derruba decoder anterior, dialog de erro em `finished`.
- **onVideoChanged** já atualiza o título quando `contentIndex` muda (base p/ próximo ep.).
- Fim de playlist hoje → `state="finished"` → **diálogo de erro + fecha** (precisa virar
  fluxo programado de autoplay/fim).

## Design (alvo)

### Layout (controles sobem de baixo, auto-hide 5s)

Série:
```
 ✕  Nome da Série
    T01 : E03 · Título do episódio
  ⏯   ⏪10   ⏩10                      ⊞ Episódios      ⏭ Próximo ep.
  ──────────────────────────────────────────────────────────────────
  00:12:45  ▮▮▮▮▮▮▮▮▮▮▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯  -00:33:10
```
Filme: só `⏪10  ⏯  ⏩10` + barra (sem Episódios/Próximo).

### Modelo de foco/teclas (quando overlay visível)
- `←/→` movem o foco entre os botões; `OK` ativa o botão focado.
- `↑` esconde o overlay; `back` esconde (e, já escondido, fecha o player).
- `↓` abre a **bandeja de episódios** (série).
- Overlay escondido: 1ª tecla apenas mostra (não age) — mantém o comportamento atual.
- Botão default ao abrir = `⏯` (play/pausa).

### Botões e ações
- `⏪10` → `seek = max(0, position-10)`
- `⏯` → pausa/resume
- `⏩10` → `seek = min(duration, position+10)`
- `⏭ Próximo ep.` (série) → vai pro próximo índice do playlist
- `⊞ Episódios` (série) → abre bandeja
- `✕`/back → fecha

### Playlist unificado da série (decisão-chave)
Padronizar `ShowVideoScreen` (série) para um **playlist plano com TODOS os episódios de
TODAS as temporadas**, cada item com metadados: `seasonNum`, `episodeNum`, `episodeTitle`,
e o já existente `seriesPoster`/`seriesId`. `contentIndex` inicia no episódio selecionado
(índice absoluto). Isso faz próximo/anterior, bandeja e virada de temporada funcionarem
de um único lugar. Os dois caminhos (EpisodesScreen e Detalhes>Play) passam a alimentar o
mesmo formato.

### Bandeja de episódios (`↓` ou `⊞`)
Lista horizontal dos episódios da **temporada atual**; card do episódio atual marcado.
Selecionar um episódio → pula pra ele no playlist (ajusta `contentIndex`). Trocar de
temporada na bandeja fica para fase posterior (v1 = temporada atual; a virada entre
temporadas acontece no autoplay/Próximo).

### Autoplay no fim do episódio
Ao chegar perto do fim (ou `state` de transição de faixa), mostrar **card "Próximo
episódio"** no canto inferior direito com contagem de **8s**:
- `OK`/contagem zera → emenda no próximo índice.
- `back`/`↑` → cancela e fica na tela final.
- Próximo índice cruza a fronteira de temporada naturalmente (playlist é plano).
- Se for o **último episódio da série** → card "Você terminou a série" + voltar.

### Título
`onVideoChanged` passa a montar `T{season} : E{episode} · {episodeTitle}` a partir dos
metadados do item atual do playlist (com o nome da série no topo).

## Fases de implementação

1. **Barra de botões navegável** (série/filme branch) — foco, ←/→, OK; fia nos seek/pausa
   atuais e no `nextContentIndex` do playlist. Ícone novo "próximo episódio".
2. **Playlist unificado da série** (todos episódios + metadados) + título `Txx:Eyy`.
3. **Bandeja de episódios** (`↓`/⊞) — lista da temporada atual + saltar pra episódio.
4. **Autoplay card** (contagem 8s) + virada de temporada + fim de série.

Cada fase compila limpo (0 BS1003/1045/1147), builda e sobe versão (v63+), testável isolada.

## Fora de escopo (YAGNI por ora)
- Seleção de áudio/legenda (Netflix tem, mas não foi pedido).
- Troca de temporada dentro da bandeja (virada via Próximo/autoplay cobre o caso).
- "Pular abertura/intro" (não há marcação de intro nos metadados Xtream).
- Qualquer mudança no player de **Canais ao vivo** ou **deep link**.
