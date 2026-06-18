'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub ShowEpisodesScreen(content as Object, selectedItem as Integer)
    ' create instance of the EpisodesScreen
    m.episodesScreen = CreateObject("roSGNode", "EpisodesScreen")
    ' observe selectedItem field so we can know which episode is selected
    m.episodesScreen.ObserveField("selectedItem", "OnEpisodesScreenItemSelected")
    ' populate episodeScreen with content based on which serial was chosen
    seriesNode = content.GetChild(selectedItem)
    m.episodesScreen.content = seriesNode
    ' Guarda a capa/id/titulo da SERIE -> "assistidos" salva a capa certa (nao a do
    ' episodio) e DEDUPLICA por serie (1 entrada por serie, nao 1 por episodio).
    if seriesNode <> invalid
        if seriesNode.hdPosterURL <> invalid then m.global.currentSeriesPoster = seriesNode.hdPosterURL
        if seriesNode.id <> invalid then m.global.currentSeriesId = AnyToString(seriesNode.id)
        if seriesNode.title <> invalid then m.global.currentSeriesTitle = seriesNode.title
    end if
    ShowScreen(m.episodesScreen)
end sub

sub OnEpisodesScreenItemSelected(event as Object)
    episodes = event.GetRoSGNode()
    ' [linha, coluna] = [temporada, episodio]
    selectedIndex = event.GetData()

    ' FASE 2 (playlist unificado): em vez de mandar so a TEMPORADA selecionada, monto um
    ' playlist PLANO com TODOS os episodios de TODAS as temporadas e comeco no episodio
    ' escolhido. Assim o "proximo" cruza a virada de temporada (antes parava no fim da
    ' temporada). O ShowVideoScreen corta a partir do indice inicial (CloneChildren).
    fullSeries = episodes.content
    children = []
    startIdx = 0
    absIdx = 0
    si = 0
    for each season in fullSeries.GetChildren(-1, 0)
        epClones = CloneChildren(season)
        if si = selectedIndex[0] then startIdx = absIdx + selectedIndex[1]
        for each ec in epClones
            children.Push(ec)
            absIdx = absIdx + 1
        end for
        si = si + 1
    end for

    if children.Count() = 0
        ' fallback de seguranca: comportamento antigo (so a temporada).
        rowContent = fullSeries.GetChild(selectedIndex[0])
        ShowVideoScreen(rowContent, selectedIndex[1], true)
    else
        node = CreateObject("roSGNode", "ContentNode")
        node.Update({ children: children }, true)
        ShowVideoScreen(node, startIdx, true)
    end if
    m.selectedIndex = m.episodesScreen.jumpToEpisode
end sub