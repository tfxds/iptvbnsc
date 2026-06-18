' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainScene.xml using relative path.

sub ShowSearchScreen()
    m.SearchScreen = CreateObject("roSGNode", "SearchScreen")
    m.SearchScreen.ObserveField("rowItemSelected", "OnSearchScreenItemSelected")
    'm.SearchScreen.ObserveField("currentText", "OnKeyboardInputsTextChanged")
    ShowScreen(m.SearchScreen) ' show GridScreen
end sub

sub OnSearchScreenItemSelected(event as Object)
    grid = event.GetRoSGNode()
    ' extract the row and column indexes of the item the user selected
    m.selectedIndex = event.GetData()
    ' the entire row from the RowList will be used by the Video node
    rowContent = grid.content.GetChild(m.selectedIndex[0])
    m.selectedRow = m.selectedIndex[0]
    info = rowContent.GetChild(m.selectedIndex[1])
    ' Busca UNIFICADA: a fileira mistura tipos. Antes de abrir, alinha o tipo/prefixo
    ' GLOBAL ao item escolhido -> a serie precisa de m.global.play = "/series/.../" pra
    ' montar a URL dos episodios (seriesItemLoaderTask usa m.global.play); filme idem.
    if info.mediaType = "live"
        m.global.contentType = "live"
        m.global.play = "/live/" + m.global.user + "/" + m.global.pass + "/"
        ShowVideoLiveScreen(rowContent, m.selectedIndex[1])
    else if info.mediaType = "series"
        m.global.contentType = "series"
        m.global.play = "/series/" + m.global.user + "/" + m.global.pass + "/"
        ShowDetailsScreen(rowContent, m.selectedIndex[1])
    else
        m.global.contentType = "movie"
        m.global.play = "/movie/" + m.global.user + "/" + m.global.pass + "/"
        ShowDetailsScreen(rowContent, m.selectedIndex[1])
    end if
end sub
