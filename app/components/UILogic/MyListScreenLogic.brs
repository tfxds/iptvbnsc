'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
sub ShowMyListScreen()
    m.MyListScreen = CreateObject("roSGNode", "MyListScreen")
    m.MyListScreen.ObserveField("itemSelected", "OnMyListScreenItemSelected")
    ShowScreen(m.MyListScreen) ' show GridScreen
	m.MyListScreen.screenlabel = CapitalizeFirstLetter(m.global.titleSection)
end sub

sub OnMyListScreenItemSelected(event as Object)
    grid = event.GetRoSGNode()
    m.selectedIndex = event.GetData()
    rowContent = grid.content.Clone(true)
    m.selectedRow = m.selectedIndex
    info = rowContent.GetChild(m.selectedIndex)

    if info.mediaType = "live"
        ShowVideoLiveScreen(rowContent, m.selectedIndex)
    else if info.mediaType = "series" and info.seriesId <> invalid and info.seriesId <> ""
        ' Continuar Assistindo de SERIE: reconstroi o playlist completo da serie e retoma
        ' no episodio salvo (proximo/anterior + autoplay). Filme cai no else (toca direto).
        ResumeSeriesFromContinue(info)
    else
        ShowDetailsScreen(rowContent, m.selectedIndex)
    end if
end sub

' Carrega a serie inteira (get_series_info via seriesItemLoaderTask, a MESMA task do
' DetailsScreen) pra reconstruir o playlist e retomar no episodio que estava assistindo.
sub ResumeSeriesFromContinue(info as Object)
    if m.cwLoading = true then return   ' evita disparo duplo se clicar 2x
    m.cwLoading = true
    m.cwHandled = false   ' libera o processamento do contentView pra ESTA nova carga
    m.cwReturnRefresh = true   ' ao fechar o player, recarrega o "recentemente assistido" (episodio novo)
    m.cwSeriesEpisodeId = ""
    if info.episodeId <> invalid then m.cwSeriesEpisodeId = AnyToString(info.episodeId)
    m.cwSeriesPoster = info.hdPosterURL
    m.cwSeriesTitle = info.seriesTitle
    m.cwSeriesTask = CreateObject("roSGNode", "seriesItemLoaderTask")
    m.cwSeriesTask.content = CreateObject("roSGNode", "ContentNode")
    m.cwSeriesTask.id = AnyToString(info.seriesId)
    m.cwSeriesTask.ObserveField("contentView", "OnCwSeriesLoaded")
    m.cwSeriesTask.control = "run"
end sub

sub OnCwSeriesLoaded(event as Object)
    ' PROCESSA UMA VEZ SO. A seriesItemLoaderTask notifica "contentView" mais de uma vez
    ' (visto no log: [CWDBG resume] disparando 3x seguidas). Sem cortar aqui, o ShowVideoScreen
    ' rodava varias vezes -> varios VideoPlayer criados/derrubados brigando pelo UNICO decoder
    ' do Roku = tela/botoes travados com o video ainda tocando. Pior: um disparo atrasado da
    ' task RECONSTROI o player no meio do episodio (trava no meio). Desobserva + para a task +
    ' flag de re-entrada no 1o disparo mata os dois casos.
    if m.cwHandled = true then return
    m.cwHandled = true
    if m.cwSeriesTask <> invalid
        m.cwSeriesTask.unobserveField("contentView")
        m.cwSeriesTask.control = "stop"
    end if
    m.cwLoading = false
    seriesNode = event.GetData()
    if seriesNode = invalid then return

    ' Capa/titulo da SERIE (player + "assistindo agora"). Prioriza o salvo; cai na resposta.
    if m.cwSeriesPoster <> invalid and m.cwSeriesPoster <> ""
        m.global.currentSeriesPoster = m.cwSeriesPoster
    else if seriesNode.hdPosterURL <> invalid
        m.global.currentSeriesPoster = seriesNode.hdPosterURL
    end if
    m.global.currentSeriesId = AnyToString(m.cwSeriesTask.id)
    if m.cwSeriesTitle <> invalid and m.cwSeriesTitle <> "" then m.global.currentSeriesTitle = m.cwSeriesTitle

    ' Playlist PLANO de todas as temporadas; acha o indice do episodio salvo (resume).
    children = []
    startIdx = 0
    absIdx = 0
    for each season in seriesNode.GetChildren(-1, 0)
        epClones = CloneChildren(season)
        for each ec in epClones
            if AnyToString(ec.id) = m.cwSeriesEpisodeId then startIdx = absIdx
            children.Push(ec)
            absIdx = absIdx + 1
        end for
    end for

    if children.Count() = 0 then return
    node = CreateObject("roSGNode", "ContentNode")
    node.Update({ children: children }, true)
    ? "[CWDBG resume] currentSeriesId="; m.global.currentSeriesId; " startIdx="; startIdx; " totalEps="; children.Count(); " epIdProcurado="; m.cwSeriesEpisodeId
    ShowVideoScreen(node, startIdx, true)
end sub
