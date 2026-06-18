# Mapeamento completo da UI — S.A Player (Roku)

> Lido arquivo por arquivo (XML + .brs de cada tela e cada componente de item).
> Objetivo: deixar o app mais **amigável** e consertar o layout. Comparação
> "como está hoje" × "como deveria ser pra ficar fácil pro usuário final".

## Telas (fluxo)

```
Splash → LoginScreen → MenuScreen (dashboard) → {
    Filmes/Séries  → GridScreen → DetailsScreen → (Séries) EpisodesScreen → Player
    TV ao vivo      → TimeGridScreen (grade EPG + player no cantinho)
    Busca           → SearchScreen
    Favoritos       → MyListScreen
    Config          → SettingsScreen (PIN)
    Conta           → AccountScreenDialog
}
```

---

## 1. LoginScreen  — `components/screens/LoginScreen/`
**Como está:** logo grande à esquerda, caixa de login à direita com 3 campos
(código revendedor / usuário / senha) + botão. MAC do aparelho no rodapé esquerdo.
Layout todo por matemática manual (`m.fullWidth*0.5*0.75`...).
- **Problemas de amigabilidade:**
  - Sobras em espanhol/branding errado: `text="¡BIENVENIDO!"`, rodapé fixo
    `"ALFA TV 2025®"`, fonte `Hadyan.otf`.
  - Texto de boas-vindas e rodapé usam `loginTitulo()` (ok), mas o default e o
    rodapé hardcoded de "ALFA TV" aparecem antes do branding carregar.
  - Nenhuma dica visual de "qual campo é qual" além do hintText.

## 2. MenuScreen (dashboard)  — `components/screens/MenuScreen/` + `ItemComponents/{HeroMenuItem,NavMenuItem,HeaderActionItem}`
**Como está:** 3 fileiras — header (Busca/Favoritos/Usuário/Config),
hero (3 tiles grandes: TV/Filmes/Séries) e nav (6 itens).
- **Problemas:**
  - `navGrid` tem 6 itens, e **4 são placeholders sem destino real**:
    Multi-Tela, Ver Anteriores (catchup), Rádio, Gravações. O usuário clica e
    cai em tela vazia / sem dado → frustra.
  - `HeaderActionItem`: `LayoutGroup` horizontal com `translation=[w/2, h/2]` e
    **sem `horizAlignment="center"`** → ícone+texto começam no centro e vazam pra
    direita (desalinhado dentro do botão).
  - Relógio/validade/resolução no rodapé ok, mas `resolutionLabel` ("1920 x 1080")
    não agrega nada pro usuário final.

## 3. GridScreen (Filmes/Séries)  — `components/screens/GridScreen/` + `ItemComponents/MarkupGridItem`
**Como está:** sidebar de categorias à esquerda (com busca) + grade 6×5 de pôsteres.
- **Card = `MarkupGridItem`** (é ESTE o "letras fora do lugar dos cards"):
  - `itemSize="[280,350]"` na grade, **mas o pôster é `320×425` escalado 0.85**
    (≈272×361). A barra de título fica em `y=383` DENTRO do maskGroup 320×425 →
    posição relativa à célula 280×350 fica deslocada.
  - Centralização do título é feita **duas vezes**: o `ScrollingLabel` já tem
    `horizAlign="center"` dentro de um retângulo de 320 com `maxWidth=240`, e o
    código ainda faz `m.posterText.translation = [centerY, 0]` por cima → empurra
    o texto pra fora.
  - Estrelas de avaliação sobrepõem o pôster (poluição visual).
- **Resultado:** títulos cortados/tortos, espaçamento inconsistente.

## 4. DetailsScreen  — `components/screens/DetailsScreen/`
**Como está:** backdrop + título (`ScrollingLabel` em `[793,200]`),
ano/gêneros lá na **esquerda** (`[243,*]`) longe do resto, descrição,
elenco/diretor, e lista de botões (`[813,270]`).
- **Problemas:** informação espalhada (ano/gênero longe do título), sobras
  "Copyright XoceUnder", tudo posicionado por coordenada fixa.

## 5. EpisodesScreen  — `components/screens/EpisodesScreen/`
**Como está:** lista de temporadas à esquerda + lista de episódios à direita.
- **Faltando:** "Continuar assistindo" (retomar de onde parou) — o Thiago pediu;
  hoje a série reabre do começo.

## 6. TimeGridScreen (TV ao vivo)  — `components/screens/TimeGridScreen/` + `ItemComponents/TimeGridChannelItem`
**Como está (é o MAIOR problema de amigabilidade):**
- É uma **grade EPG** (programação por horário). O vídeo toca numa **caixinha de
  600×325 no canto superior direito** (`[1260,50]`).
- Pra ver em **tela cheia** o usuário precisa apertar o botão **PLAY** do controle
  (não o OK) e ainda com o foco na grade. `OK` num canal sem catch-up só
  abre/fecha a barra de info — **não dá fullscreen**.
- Isso é o oposto do que VIZZION/MAGIC/ASSIST/etc fazem: seleciona canal → abre
  em tela cheia na hora; OK alterna info; ↑/↓ troca de canal.
- Já corrigido nesta rodada: bug do `maximizeVideo()` que setava `width/height="0"`
  (vídeo sumia ao "maximizar"). Falta o gesto ser natural (OK = tela cheia).
- Reconexão fica repetindo em canal offline (cosmético, dá pra suavizar).

## 7. SettingsScreen  — `components/screens/SettingsScreen/`
**Como está:** menu à esquerda (`bg_dark.png`) + painel à direita com
checklist/radio/pinpad. Funcional, visual datado (posters `bg_dark.png`,
coordenadas fixas `[105,300]`).

## 8. Itens de lista — `MarkupListItem` (categorias)
ScrollingLabel + ícone de "selecionado". Ok, mas usa `rounded-$$RES$$.9.png`
e cores fixas.

---

## Padrões transversais (afetam tudo)
- **Sobras de idioma/branding:** comentários e strings em espanhol; `tr()` com
  textos espanhóis; "XoceUnder"/"ALFA TV 2025" espalhados.
- **Layout por coordenada absoluta** (pouco `LayoutGroup`), difícil de manter e
  quebra em telas diferentes.
- **Fontes misturadas:** Montserrat (Black/Bold), Largebold, Lato, Hadyan,
  System fonts — sem consistência.
- **Paleta:** azul `0x1a6a9a`/`0x00d4ff` no menu, vermelho `0xdb4d3a` no player,
  cinzas variados. Sem token central de cor (o painel manda cor? hoje não usa).

---

## Prioridade sugerida (do que mais incomoda o usuário → menos)
1. **TV ao vivo: OK = tela cheia** (e seleção de canal abre grande). [maior ganho]
2. **Cards de Filmes/Séries:** título alinhado, sem estrela poluindo, tamanho
   batendo com a célula.
3. **Menu:** esconder/!ativar os 4 itens-placeholder do nav; centralizar botões
   do header.
4. **Login:** tirar sobras "ALFA TV/¡BIENVENIDO!", deixar branding limpo.
5. **Detalhes:** reagrupar info (título+ano+gênero juntos).
6. **Continuar assistindo** em séries.
7. **Polimento visual** (fontes/cores consistentes, Config).
```
