'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
sub init()
    m.video = m.top.FindNode("video")
    m.title = m.top.FindNode("title")
    m.epSubtitle = m.top.FindNode("epSubtitle")
    m.controlsGradient = m.top.FindNode("controlsGradient")
    m.loadingGroup = m.top.FindNode("loadingGroup")
    m.transportControls = m.top.FindNode("transportControls")
    m.LoadingBar = m.top.FindNode("LoadingBar")
    m.progressBar = m.top.FindNode("progressBar")
    m.stateIcon = m.top.FindNode("stateIcon")
    m.leftProgressLabel = m.top.FindNode("leftProgressLabel")
    m.rightProgressLabel = m.top.FindNode("rightProgressLabel")
    m.action = m.top.FindNode("action")

    ' Botoes da barra (estilo Netflix)
    m.btnFocus = m.top.FindNode("btnFocus")
    m.btnPrevEp = m.top.FindNode("btnPrevEp")
    m.btnMinus = m.top.FindNode("btnMinus")
    m.btnPlay = m.top.FindNode("btnPlay")
    m.btnPlus = m.top.FindNode("btnPlus")
    m.btnNextEp = m.top.FindNode("btnNextEp")
    m.buttonsBuilt = false
    m.buttons = []
    m.focusIndex = 0
    ' Foco da barra de controles: "bar" (arrasta a bolinha, padrao Netflix) ou "buttons"
    ' (navega ⏮ −10 ⏯ +10 ⏭). ↑ vai pros botoes, ↓ volta pra barra.
    m.focusMode = "bar"

    ' Fase 3/4: bandeja de episodios + card de autoplay
    m.epTray = m.top.FindNode("epTray")
    m.epTrayTitle = m.top.FindNode("epTrayTitle")
    m.nextCard = m.top.FindNode("nextCard")
    m.nextThumb = m.top.FindNode("nextThumb")
    m.nextLabelTitle = m.top.FindNode("nextLabelTitle")
    m.nextLabelCount = m.top.FindNode("nextLabelCount")
    ' A bandeja NAO recebe foco do SceneGraph (ver openTray) -> nos dirigimos a selecao na
    ' mao. Por isso nao observamos rowItemSelected aqui (a selecao e tratada no OnKeyEvent).
    m.trayOpen = false
    m.trayIndex = 0

    ShowLoadingFacade(true)

    m.video.width = getScreenSize().width
    m.video.height = getScreenSize().height

    m.LoadingBar.translation = [getScreenSize().width/2 - 250/2, getScreenSize().height/2 + 250/2]
    m.transportControls.translation = [200, getScreenSize().width]
    m.controlsGradient.width = getScreenSize().width
    m.controlsGradient.height = getScreenSize().height

    ' animations
    m.showTCAnimation = m.top.findNode("showTCAnimation")
    m.transportControlsInterpolator = m.top.findNode("transportControlsInterpolator")
    m.gradientInterpolator = m.top.findNode("gradientInterpolator")
    ' controls hiding timer
    m.transportControlsTimer = m.top.findNode("transportControlsTimer")
    m.transportControlsTimer.ObserveFieldScoped("fire", "HideTransportControls")
    m.top.ObserveFieldScoped("focusedChild", "OnFocusChange")

    m.video.ObserveFieldScoped("state", "OnVideoStateChanged")
    m.video.observeField("position", "OnSavePosition")
    m.video.ObserveFieldScoped("duration", "OnDurationChanged")
    m.video.ObserveFieldScoped("progressPosition", "OnPositionChanged")
    m.video.observeField("contentIndex", "onVideoChanged")
    ' Ultimo indice de episodio visto -> detecta TROCA real (skip/auto-advance) vs 1o load.
    m.lastEpIndex = -1
    ' Indice de episodio ESPERADO (setado no skip/bandeja). Trava o OnSavePosition de gravar
    ' com o indice ANTIGO enquanto o contentIndex nao alcanca o destino (anti-corrida do skip).
    m.expectedEpIndex = -1

    ' SCRUB (arrastar o tempo pela barra). ff/rew movem a bolinha com aceleracao; commita o
    ' seek apos ~1.2s parado ou no OK. m.direction != invalid trava o OnPositionChanged de
    ' sobrescrever a barra durante o arrasto.
    m.scrubbing = false
    m.scrubTarget = 0
    m.scrubStep = 15
    m.scrubCommitTimer = createObject("roSGNode", "Timer")
    m.scrubCommitTimer.duration = 1.2
    m.scrubCommitTimer.repeat = false
    m.scrubCommitTimer.observeField("fire", "commitScrub")

    m.fullTimeString = "0"
    m.screenHeight = getScreenSize().height
end sub

' Monta a lista de botoes conforme SERIE (com prev/next episodio) ou FILME (so seek+play).
' Roda uma vez (na 1a vez que os controles aparecem), quando o content ja esta setado.
sub buildButtons()
    isSeries = (m.video.content <> invalid and m.video.content.GetChildCount() > 0)
    m.buttons = []
    if isSeries
        m.btnPrevEp.visible = true
        m.btnNextEp.visible = true
        m.buttons.Push({ action: "prevep", iconX: 660 })
        m.buttons.Push({ action: "minus", iconX: 810 })
        m.buttons.Push({ action: "play",  iconX: 960 })
        m.buttons.Push({ action: "plus",  iconX: 1110 })
        m.buttons.Push({ action: "nextep", iconX: 1260 })
        m.focusIndex = 2
    else
        m.btnPrevEp.visible = false
        m.btnNextEp.visible = false
        m.buttons.Push({ action: "minus", iconX: 810 })
        m.buttons.Push({ action: "play",  iconX: 960 })
        m.buttons.Push({ action: "plus",  iconX: 1110 })
        m.focusIndex = 1
    end if
    m.buttonsBuilt = true
end sub

' Posiciona o realce ATRAS do botao focado (centralizado no icone 64x64).
sub positionFocus()
    if m.buttons.Count() = 0 then return
    if m.focusIndex < 0 then m.focusIndex = 0
    if m.focusIndex > m.buttons.Count()-1 then m.focusIndex = m.buttons.Count()-1
    iconX = m.buttons[m.focusIndex].iconX
    ' icone em [iconX,-78] 64x64 -> centro (iconX+32,-46); foco 220x108 centralizado.
    m.btnFocus.translation = [iconX + 32 - 110, -46 - 54]
    m.btnFocus.visible = true
end sub

sub restartHideTimer()
    m.transportControlsTimer.control = "stop"
    m.transportControlsTimer.control = "start"
end sub

sub activateFocused()
    if m.buttons.Count() = 0 then return
    act = m.buttons[m.focusIndex].action
    if act = "minus"
        seekBy(-10)
    else if act = "plus"
        seekBy(10)
    else if act = "play"
        togglePlay()
    else if act = "prevep"
        skipEpisode(-1)
    else if act = "nextep"
        skipEpisode(1)
    end if
end sub

' SCRUB estilo Netflix: cada ⏩/⏪ joga a bolinha pra frente/tras pela barra; segurando/
' apertando seguido, o passo ACELERA (15 -> 30 -> 45... ate 90s) -> voa pela timeline. Mostra
' o tempo de destino ao vivo e commita o seek sozinho apos ~1.2s parado (ou no OK).
sub startOrContinueScrub(dir as Integer)
    if m.video = invalid or m.video.duration <= 0 then return
    if not m.scrubbing
        m.scrubbing = true
        m.scrubTarget = m.video.position
        m.scrubStep = 15
        m.direction = "scrub"      ' trava OnPositionChanged de sobrescrever a barra
        ShowTransportControls()
        m.transportControlsTimer.control = "stop"
    else
        m.scrubStep = m.scrubStep + 15
        if m.scrubStep > 90 then m.scrubStep = 90
    end if
    nt = m.scrubTarget + (dir * m.scrubStep)
    if nt < 0 then nt = 0
    if nt > m.video.duration then nt = m.video.duration
    m.scrubTarget = nt
    ' move a bolinha + atualiza os tempos pro alvo do arrasto
    m.progressBar.progressPosition = m.scrubTarget
    UpdateTimeLabel()
    m.scrubCommitTimer.control = "stop"
    m.scrubCommitTimer.control = "start"
end sub

sub commitScrub()
    if not m.scrubbing then return
    m.scrubbing = false
    m.scrubCommitTimer.control = "stop"
    m.video.seek = m.scrubTarget
    m.direction = invalid          ' libera o OnPositionChanged
    restartHideTimer()
end sub

sub seekBy(delta as Integer)
    np = m.video.position + delta
    if np < 0 then np = 0
    if m.video.duration > 0 and np > m.video.duration then np = m.video.duration
    m.video.seek = np
end sub

sub togglePlay()
    if m.video.state = "playing"
        m.video.control = "pause"
    else
        m.video.control = "resume"
    end if
end sub

' Pula episodio dentro do playlist da serie (Roku: nextContentIndex + skipcontent).
sub skipEpisode(dir as Integer)
    if m.video.content = invalid then return
    cnt = m.video.content.GetChildCount()
    if cnt <= 0 then return
    idx = m.video.contentIndex
    ni = idx + dir
    if ni < 0 or ni > cnt - 1 then return
    m.expectedEpIndex = ni   ' trava saves com o indice antigo ate o contentIndex alcancar
    m.video.nextContentIndex = ni
    m.video.control = "skipcontent"
    ' Marca o episodio DESTINO na hora, usando o indice que JA conheco (ni) -> nao depende
    ' do contentIndex atualizar nem do onVideoChanged disparar (era o ponto que falhava:
    ' pular pro EP2 e sair nao atualizava o "recentemente assistido").
    markCurrentEpisode(ni)
end sub

sub OnSavePosition()
    if m.video.content = invalid then return
    ' ANTI-CORRIDA DO SKIP: ao pular de episodio o contentIndex demora um tiquinho pra
    ' atualizar. Nesse meio o save disparava com o indice ANTIGO e regravava o episodio
    ' anterior por cima do destino (continue-watching "voltava" pro episodio de antes).
    ' Enquanto o contentIndex nao alcanca o destino esperado, NAO grava.
    if m.expectedEpIndex <> invalid and m.expectedEpIndex >= 0 and m.video.content.GetChildCount() > 0 and m.video.contentIndex <> m.expectedEpIndex then return
    if int(m.video.position) MOD 2 = 0 and m.video.position > 10 then
        m.savePositionToReg = createObject("roSGNode", "WriteVideoPosition")
        m.savePositionToReg.section = "VideoPosition"
        if m.video.content.GetChildCount() <> 0
            ' Episodio ATUAL do playlist (nao o 0) -> "assistindo agora" salva o episodio
            ' certo (com skip/auto-advance o contentIndex muda; antes gravava sempre o 1o).
            sidx = m.video.contentIndex
            if sidx < 0 or sidx > m.video.content.GetChildCount() - 1 then sidx = 0
            contentItem = m.video.content.GetChild(sidx)
        else
            contentItem = m.video.content
        end if
        if contentItem = invalid then return

        ID = contentItem.id
        m.savePositionToReg.id = ID
        m.savePositionToReg.pos = m.video.position - 10
        m.savePositionToReg.control = "RUN"

        ' Capa: pra serie/episodio usa a capa da SERIE, nao a do episodio (que costuma
        ' vir vazia/screenshot). NAO da pra confiar no mediaType aqui: os episodios passam
        ' por Clone(false) (CloneChildren) que APAGA campos customizados (mediaType vira
        ' invalid) -> o gate antigo "if mt = episode" nunca passava e caia na capa do
        ' episodio. Solucao: o global currentSeriesPoster so tem valor em SERIE (filme
        ' limpa no ShowVideoScreen). Tem valor => usa a capa da serie, ponto.
        posterUrl = contentItem.hdPosterURL
        titleVal = contentItem.title
        seriesKey = ""
        if m.global.currentSeriesPoster <> invalid and m.global.currentSeriesPoster <> ""
            posterUrl = m.global.currentSeriesPoster
            ' DEDUP por serie: todos os episodios colapsam em UMA entrada (a ultima vista).
            ' Chave = id da serie (fallback na capa, que tambem e unica por serie).
            if m.global.currentSeriesId <> invalid and m.global.currentSeriesId <> ""
                seriesKey = m.global.currentSeriesId
            else
                seriesKey = m.global.currentSeriesPoster
            end if
            ' Mostra o NOME DA SERIE na entrada (nao o titulo do episodio).
            if m.global.currentSeriesTitle <> invalid and m.global.currentSeriesTitle <> "" then titleVal = m.global.currentSeriesTitle
        else if contentItem.seriesPoster <> invalid and contentItem.seriesPoster <> ""
            posterUrl = contentItem.seriesPoster
        end if
        cwEntry = {
            id: ID,
            title: titleVal,
            contentType: contentItem.contentType,
            mediaType: contentItem.mediaType,
            hdPosterURL: posterUrl,
            url: contentItem.url,
            pos: m.video.position - 10,
            length: m.video.duration
        }
        if seriesKey <> "" then cwEntry.seriesKey = seriesKey
        saveContinueWatchingEntry(cwEntry)
    end if
end sub

sub onVideoChanged()
    if m.video.content = invalid then return
    index = m.video.contentIndex
    ' contentIndex alcancou o episodio real -> libera o OnSavePosition (fim da anti-corrida).
    m.expectedEpIndex = index
    ' Marca SO em AVANCO (auto-advance pro proximo episodio). Quando o playlist chega no FIM
    ' e o Roku volta o contentIndex pro 0 (wrap/cleanup de fim de playlist), NAO remarcar o
    ' episodio 0 por cima -> era exatamente isso que fazia o "recentemente assistido" voltar
    ' pro 1o episodio depois de assistir o ultimo (visto no log: index 1 -> 0 sozinho).
    ' Skip manual (next/prev) e bandeja ja marcam explicitamente no proprio handler, entao
    ' nao dependem desse auto-mark. Ignora tambem o 1o disparo (load/resume).
    if m.lastEpIndex <> invalid and m.lastEpIndex >= 0 and index > m.lastEpIndex
        markCurrentEpisode()
    end if
    m.lastEpIndex = index
    if m.video.content.GetChildCount() <> 0
        child = m.video.content.GetChild(index)
        ' SERIE: titulo = nome da serie; subtitulo = titulo do episodio atual.
        if m.global.currentSeriesTitle <> invalid and m.global.currentSeriesTitle <> ""
            m.title.text = m.global.currentSeriesTitle
        end if
        if child <> invalid then m.epSubtitle.text = child.title
    else
        ' FILME: titulo = nome do filme; sem subtitulo.
        m.title.text = m.video.content.title
        m.epSubtitle.text = ""
    end if
end sub

' Grava o episodio ATUAL no "recentemente assistido" imediatamente (force, ignora 60s),
' usado ao TROCAR de episodio. Posicao = 0 (episodio recem-iniciado); o OnSavePosition
' (a cada 2s) vai atualizando a posicao real conforme assiste. So serie (tem playlist).
sub markCurrentEpisode(forceIdx = -1 as Integer)
    if m.video.content = invalid then return
    if m.video.content.GetChildCount() = 0
        return
    end if
    seriesKey = ""
    if m.global.currentSeriesId <> invalid and m.global.currentSeriesId <> ""
        seriesKey = m.global.currentSeriesId
    else if m.global.currentSeriesPoster <> invalid and m.global.currentSeriesPoster <> ""
        seriesKey = m.global.currentSeriesPoster
    end if
    if seriesKey = ""
        return
    end if
    idx = forceIdx
    if idx < 0 then idx = m.video.contentIndex
    if idx < 0 or idx > m.video.content.GetChildCount() - 1 then idx = 0
    ep = m.video.content.GetChild(idx)
    if ep = invalid then return

    posterUrl = ep.hdPosterURL
    if m.global.currentSeriesPoster <> invalid and m.global.currentSeriesPoster <> "" then posterUrl = m.global.currentSeriesPoster
    titleVal = ep.title
    if m.global.currentSeriesTitle <> invalid and m.global.currentSeriesTitle <> "" then titleVal = m.global.currentSeriesTitle

    cwEntry = {
        id: ep.id,
        title: titleVal,
        contentType: ep.contentType,
        mediaType: ep.mediaType,
        hdPosterURL: posterUrl,
        url: ep.url,
        pos: 0,
        length: m.video.duration,
        seriesKey: seriesKey
    }
    saveContinueWatchingEntry(cwEntry, true)
end sub

sub OnFocusChange()
    ' Mantem o FOCO no Player (m.top) -> o Player.brs trata as teclas (barra de botoes).
    ' Antes dava SetFocus no video (RenderlessVideo), que comia as teclas e impedia
    ' qualquer botao navegavel.
    if m.top.HasFocus()
        if m.video.content <> invalid
            if m.video.content.GetChildCount() <> 0
                if m.global.currentSeriesTitle <> invalid and m.global.currentSeriesTitle <> "" then m.title.text = m.global.currentSeriesTitle
                child = m.video.content.GetChild(m.video.contentIndex)
                if child <> invalid then m.epSubtitle.text = child.title
            else
                m.title.text = m.video.content.title
                m.epSubtitle.text = ""
            end if
        end if
    end if
end sub

sub ShowLoadingFacade(show as Boolean)
    m.loadingGroup.visible = show
end sub

sub OnVideoStateChanged(event as Object)
    state = event.GetData()
    if state = "buffering"
        ShowLoadingFacade(true)
    else if state = "playing"
        ShowTransportControls()
        ShowLoadingFacade(false)
    end if
    if state = "paused"
        m.transportControlsTimer.control = "stop"
        SetPlayIcon("pkg:/images/player/play.png")
    else
        m.transportControlsTimer.control = "start"
        SetPlayIcon("pkg:/images/player/pause.png")
    end if
    if state = "error"
        dialog = createObject("roSGNode", "Dialog")
        dialog.title = "Erro na reprodução"
        dialog.optionsDialog = true
        dialog.message = m.video.errorMsg
        m.top.getscene().dialog = dialog
        m.top.closeVideo = true
    else if state = "finished"
        ' Fim do FILME ou do ultimo episodio da serie (playlist) -> fecha LIMPO, sem
        ' popup de erro (antes "finished" caia no dialog de erro).
        m.top.closeVideo = true
    end if
end sub

sub OnDurationChanged(event as Object)
    m.progressBar.length = event.GetData()
    m.fullTimeString = int(event.GetData())
    UpdateTimeLabel()
end sub

sub OnPositionChanged(event as Object)
    if m.direction = invalid
        m.progressBar.progressPosition = event.GetData()
        UpdateTimeLabel()
    end if
    updateNextCard()
end sub

' FASE 4: nos ultimos 20s de um episodio que TEM proximo, mostra o card de autoplay.
' (o playlist do Roku ja emenda sozinho no fim; o card e o aviso + OK pra ja).
sub updateNextCard()
    if m.trayOpen then m.nextCard.visible = false : return
    ' Nao sobrepor a barra de controles: com a barra visivel, esconde o card.
    if m.transportControls.opacity > 0 then m.nextCard.visible = false : return
    if m.video.content = invalid then m.nextCard.visible = false : return
    cnt = m.video.content.GetChildCount()
    if cnt <= 1 then m.nextCard.visible = false : return   ' filme/episodio unico
    idx = m.video.contentIndex
    if idx >= cnt - 1 then m.nextCard.visible = false : return   ' ultimo da serie
    if m.video.duration <= 0 then m.nextCard.visible = false : return
    remaining = m.video.duration - m.video.position
    if remaining <= 20 and remaining > 0
        nxt = m.video.content.GetChild(idx + 1)
        if nxt <> invalid then m.nextLabelTitle.text = nxt.title
        if m.global.currentSeriesPoster <> invalid and m.global.currentSeriesPoster <> "" then m.nextThumb.uri = m.global.currentSeriesPoster
        m.nextLabelCount.text = "Em " + Int(remaining).ToStr() + "s · OK para já"
        m.nextCard.visible = true
    else
        m.nextCard.visible = false
    end if
end sub

' FASE 3: bandeja de episodios (abre com seta pra baixo ou via foco no proximo).
sub openTray()
    if m.video.content = invalid or m.video.content.GetChildCount() <= 1 then return
    buildTrayContent()
    m.nextCard.visible = false
    m.transportControlsTimer.control = "stop"
    OnTransportControlsShow(false)   ' esconde a barra enquanto a bandeja esta aberta
    m.epTray.visible = true
    m.epTrayTitle.visible = true
    ' IMPORTANTE: NAO damos foco no RowList. Se a bandeja ficasse com o foco, a tecla
    ' "cima" era engolida pelo RowList (1 linha) e nunca chegava no OnKeyEvent do Player
    ' -> o seletor "travava" embaixo e nao dava mais pra voltar pros botoes. Aqui o foco
    ' continua no Player (m.top) e nos dirigimos a bandeja na mao (animateToItem no OnKey).
    m.trayIndex = m.video.contentIndex
    m.epTray.jumpToRowItem = [0, m.trayIndex]
    m.trayOpen = true
end sub

sub closeTray()
    m.epTray.visible = false
    m.epTrayTitle.visible = false
    m.trayOpen = false
    m.top.setFocus(true)
    ShowTransportControls()
    restartHideTimer()
end sub

sub buildTrayContent()
    root = CreateObject("roSGNode", "ContentNode")
    row = root.CreateChild("ContentNode")
    cnt = m.video.content.GetChildCount()
    for i = 0 to cnt - 1
        ep = m.video.content.GetChild(i)
        child = row.CreateChild("ContentNode")
        child.title = ep.title
        if ep.hdPosterURL <> invalid then child.hdPosterURL = ep.hdPosterURL
    end for
    m.epTray.content = root
end sub

' Pula pro episodio escolhido na bandeja (indice rastreado em m.trayIndex).
sub selectTrayItem()
    col = m.trayIndex
    closeTray()
    if col <> m.video.contentIndex
        m.expectedEpIndex = col   ' trava saves com o indice antigo ate o contentIndex alcancar
        m.video.nextContentIndex = col
        m.video.control = "skipcontent"
        markCurrentEpisode(col)   ' marca o episodio escolhido na bandeja na hora (indice conhecido)
    end if
end sub

sub UpdateTimeLabel()
    leftPositionSeconds = int(m.progressBar.progressPosition) * 100 / 100
    rightPositionSeconds = evalInteger(m.fullTimeString) - leftPositionSeconds
    m.leftProgressLabel.text = GetDurationStringStandard(leftPositionSeconds)
    m.progressBar.translation = [(m.leftProgressLabel.translation[0] + 20) + m.leftProgressLabel.boundingRect().width,4]
    m.rightProgressLabel.text = GetDurationStringStandard(rightPositionSeconds)
    if m.leftProgressLabel.boundingRect().width > m.rightProgressLabel.boundingRect().width
        m.progressBar.width = (1270 - (m.leftProgressLabel.boundingRect().width - m.rightProgressLabel.boundingRect().width))
    else
        m.progressBar.width = 1270
    end if
end sub

' Atualiza o icone do BOTAO play/pausa (e do indicador legado, escondido).
sub SetPlayIcon(uri as String)
    m.stateIcon.uri = uri
    if m.btnPlay <> invalid then m.btnPlay.uri = uri
end sub

sub OnTransportControlsShow(slideUp as Boolean)
    if slideUp
        m.transportControlsInterpolator.keyValue = [m.transportControls.translation, [0, m.screenHeight*0.9]]
        m.gradientInterpolator.keyValue = [m.transportControls.opacity, 1.0]
    else
        m.transportControlsInterpolator.keyValue = [m.transportControls.translation, [0, m.screenHeight]]
        m.gradientInterpolator.keyValue = [m.transportControls.opacity, 0.0]
    end if
    m.showTCAnimation.control = "start"
end sub

sub HideTransportControls()
    OnTransportControlsShow(false)
end sub

sub ShowTransportControls()
    if not m.buttonsBuilt then buildButtons()
    ' Padrao Netflix: ao revelar, foco na BARRA (scrub), sem anel de botao. Botoes via ↑.
    m.focusMode = "bar"
    if m.btnFocus <> invalid then m.btnFocus.visible = false
    OnTransportControlsShow(true)
end sub

' Sobe pra linha de botoes (mostra o anel no botao focado).
sub enterButtonsMode()
    m.focusMode = "buttons"
    positionFocus()
end sub

' Volta pra barra (scrub); esconde o anel de botao.
sub enterBarMode()
    m.focusMode = "bar"
    if m.btnFocus <> invalid then m.btnFocus.visible = false
end sub

function OnKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    ' BANDEJA aberta: o foco e do Player (nao do RowList), entao TODAS as teclas passam
    ' por aqui. Dirigimos a selecao na mao (animateToItem) -> nunca trava embaixo.
    if m.trayOpen
        cnt = m.video.content.GetChildCount()
        if key = "back" or key = "up"
            closeTray()
        else if key = "left"
            if m.trayIndex > 0
                m.trayIndex = m.trayIndex - 1
                ' RowList move via jumpToRowItem ([linha,coluna]). 'animateToItem' NAO existe
                ' no RowList -> era no-op silencioso e o anel nunca andava (nao dava pra
                ' trocar de episodio pela bandeja). jumpToRowItem move o foco/anel de fato.
                m.epTray.jumpToRowItem = [0, m.trayIndex]
            end if
        else if key = "right"
            if m.trayIndex < cnt - 1
                m.trayIndex = m.trayIndex + 1
                m.epTray.jumpToRowItem = [0, m.trayIndex]
            end if
        else if key = "OK" or key = "play"
            selectTrayItem()
        end if
        return true   ' enquanto a bandeja esta aberta, o Player consome tudo
    end if

    ' SCRUB ativo (arrastando o tempo): ⏩/⏪ e direita/esquerda movem a bolinha; OK commita;
    ' back cancela; e auto-commita sozinho apos ~1.2s parado (m.scrubCommitTimer).
    if m.scrubbing
        if key = "fastforward" or key = "right"
            startOrContinueScrub(1)
        else if key = "rewind" or key = "left"
            startOrContinueScrub(-1)
        else if key = "OK" or key = "play"
            commitScrub()
        else if key = "back"
            m.scrubbing = false
            m.scrubCommitTimer.control = "stop"
            m.direction = invalid
            ShowTransportControls()
            restartHideTimer()
        end if
        return true
    end if

    controlsVisible = (m.transportControls.opacity > 0)

    if key = "back"
        ' 1o back esconde os controles; ja escondidos, FECHA o player.
        if controlsVisible
            HideTransportControls()
        else
            m.top.closeVideo = true
        end if
        return true
    end if

    ' CARD de autoplay visivel (controles escondidos): OK/direita ja pula pro proximo.
    if (not controlsVisible) and m.nextCard.visible and (key = "OK" or key = "play" or key = "right")
        m.nextCard.visible = false
        skipEpisode(1)
        return true
    end if

    ' Seta pra baixo abre a bandeja de episodios (cards). MAS so quando NAO estou na linha de
    ' botoes -> nos botoes o ↓ deve voltar pra BARRA (seletor de tempo), nao abrir os cards.
    ' (Antes esse check roubava o ↓ dos botoes e ia direto pros cards.) Hierarquia: botoes ↑/↓
    ' barra ↑/↓ cards.
    if key = "down" and m.focusMode <> "buttons" and m.video.content <> invalid and m.video.content.GetChildCount() > 1
        openTray()
        return true
    end if

    ' Inicia o SCRUB com ⏩/⏪ (vale com a barra escondida -> ja revela e comeca a arrastar).
    if key = "fastforward"
        startOrContinueScrub(1)
        return true
    else if key = "rewind"
        startOrContinueScrub(-1)
        return true
    end if

    ' Controles escondidos: a 1a tecla so REVELA a barra (nao age), igual Netflix.
    if not controlsVisible
        ShowTransportControls()
        restartHideTimer()
        return true
    end if

    ' CONTROLES VISIVEIS. Dois modos de foco:
    '  - "bar" (padrao Netflix): ←/→ ARRASTA a bolinha do tempo, OK = play/pausa, ↑ vai pros
    '    botoes, ↓ esconde (serie ja abriu a bandeja num check anterior).
    '  - "buttons": ←/→ navega ⏮ −10 ⏯ +10 ⏭, OK ativa, ↓ volta pra barra, ↑ esconde.
    if m.focusMode = "buttons"
        if key = "left"
            if m.focusIndex > 0 then m.focusIndex = m.focusIndex - 1
            positionFocus()
            restartHideTimer()
            return true
        else if key = "right"
            if m.focusIndex < m.buttons.Count() - 1 then m.focusIndex = m.focusIndex + 1
            positionFocus()
            restartHideTimer()
            return true
        else if key = "OK" or key = "play"
            activateFocused()
            restartHideTimer()
            return true
        else if key = "down"
            enterBarMode()
            restartHideTimer()
            return true
        else if key = "up"
            HideTransportControls()
            return true
        end if
    else
        if key = "left"
            startOrContinueScrub(-1)
            return true
        else if key = "right"
            startOrContinueScrub(1)
            return true
        else if key = "OK" or key = "play"
            togglePlay()
            restartHideTimer()
            return true
        else if key = "up"
            enterButtonsMode()
            restartHideTimer()
            return true
        else if key = "down"
            HideTransportControls()
            return true
        end if
    end if
    return false
end function
