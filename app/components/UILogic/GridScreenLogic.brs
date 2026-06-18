'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
sub ShowGridScreen()
    m.GridScreen = CreateObject("roSGNode", "GridScreen")
    m.GridScreen.ObserveField("itemSelected", "OnGridScreenItemSelected")
    m.GridScreen.ObserveField("itemSelectedFilter", "OnGridScreenItemSelected")
	m.GridScreen.ObserveField("categorySelected", "OnMenuSelected")
	m.GridScreen.ObserveField("keyboardText", "OnKeyboardChanged")
    ShowScreen(m.GridScreen) ' show GridScreen
	m.GridScreen.screenlabel = CapitalizeFirstLetter(m.global.titleSection)
end sub


sub OnMenuSelected(event as Object)
    m.GridScreen.content = invalid
    grid = event.GetRoSGNode()
	m.index = grid.category.GetChild(event.GetData())
	if m.index.look <> 0
        m.look = createObject("roSGNode", "PinDialog")
        m.look.title = tr("Enter Pin")
		if regread("lock", m.global.config.appName) = "0000" then m.look.message = tr("Default pin is 0000 to change it in account settings")
        m.look.observeField("pin","onVerifyPin")
        m.look.setFocus(true)
        m.top.dialog = m.look
	else
        ' Se o "Todos" ja esta em cache, filtra a pasta NO APP (instantaneo, sem rede).
        if showCachedCategory(m.index.id) then return
        m.movieTask = CreateObject("roSGNode", "MainLoaderTask")
        m.movieTask.ObserveField("content", "OnMovieContentLoaded")
        m.movieTask.category_id = m.index.id
        m.movieTask.category_title = m.index.title
        m.movieTask.control = "run"
        m.loadingIndicator.visible = true
	end if
end sub

' Tenta montar a pasta filtrando o cache "Todos" (cacheGrid_<tipo>) por categoria.
' Retorna true se conseguiu (mostrou na hora); false se nao ha cache (cai pra rede).
function showCachedCategory(catId as dynamic) as boolean
    if catId = invalid or catId = "" then return false
    if m.global.contentType = invalid then return false
    cache = m["cacheGrid_" + m.global.contentType]
    if cache = invalid then return false
    if m.GridScreen = invalid or m.GridScreen.subtype() <> "GridScreen" then return false

    ' IMPORTANTE: clonar cada filho. Passar os nos do cache direto pra outro ContentNode
    ' REPARENTA eles (tira do cache) -> a 1a troca funciona e as seguintes ficam
    ' lentas/vazias. Com clone(true) o cache fica intacto e a troca segue instantanea.
    node = CreateObject("roSGNode", "ContentNode")
    for each child in cache.GetChildren(-1, 0)
        if child.categoryId = catId then node.appendChild(child.clone(true))
    end for

    fl = getScene().FindNode("filteredList")
    if fl <> invalid then fl.visible = false
    mg = getScene().FindNode("markupGrid")
    if mg <> invalid then mg.visible = true

    m.GridScreen.content = invalid
    m.GridScreen.searchContent = invalid
    m.GridScreen.SetFocus(true)
    m.GridScreen.content = node
    m.loadingIndicator.visible = false
    return true
end function

sub onVerifyPin()
	if m.look.pin.len() = 4 then
       'print "ok button pressed"
        m.confirmPin = createObject("roSGNode", "PinTask")
        m.confirmPin.section = m.global.config.appName
        m.confirmPin.pin = m.look.pin
        m.confirmPin.observeField("state","showAdults")
        m.confirmPin.control = "RUN"
    end if
end sub

sub showAdults()
    if m.confirmPin.state = "stop" then 
        if m.confirmPin.result then
		    m.look.close = true
            if showCachedCategory(m.index.id) then return
            m.movieTask = CreateObject("roSGNode", "MainLoaderTask")
            m.movieTask.ObserveField("content", "OnMovieContentLoaded")
            m.movieTask.category_id = m.index.id
            m.movieTask.category_title = m.index.title
            m.movieTask.control = "run"
            m.loadingIndicator.visible = true
        else
            m.look.title = tr("Incorrect Pin, try again")
            m.look.pin = ""
			m.look.setFocus(true)
        end if
    end if
end sub

sub OnMovieContentLoaded()
    m.loadingIndicator.visible = false
    ' Guarda anti-crash: se a tela atual NAO for a GridScreen (ex.: o usuario foi pra
    ' Canais antes do filme terminar de carregar), ignora — senao quebra (TimeGridView
    ' nao tem searchContent/filteredList -> "Invalid value for left-side").
    if m.GridScreen = invalid or m.GridScreen.subtype() <> "GridScreen" then return

    fl = getScene().FindNode("filteredList")
    if fl <> invalid then fl.visible = false
    mg = getScene().FindNode("markupGrid")
    if mg <> invalid then mg.visible = true

    m.GridScreen.content = invalid
    m.GridScreen.searchContent = invalid
    m.GridScreen.SetFocus(true)
    m.GridScreen.content = m.movieTask.content
    ' CACHE de sessao: guarda o "Todos" (category_id vazio) pra re-entrada instantanea.
    if m.movieTask.category_id = "" and m.global.contentType <> invalid
        m["cacheGrid_" + m.global.contentType] = m.movieTask.content
    end if
end sub

sub OnKeyboardChanged(event as Object)
    searchText = event.GetData()
	grid = event.GetRoSGNode()
	if grid.content <> invalid then
    	m.searchContent = grid.content.Clone(true)
    	if m.searchContent.getChildCount() <> 0 then
    	    filteredContent = searchContent(m.searchContent, searchText)
            if filteredContent <> invalid
                mg = getScene().FindNode("markupGrid")
                if mg <> invalid then mg.visible = false
                fl = getScene().FindNode("filteredList")
                if fl <> invalid then fl.visible = true
                if m.GridScreen <> invalid then m.GridScreen.searchContent = filteredContent
            end if
	    end if
	end if
end sub

sub OnGridScreenItemSelected(event as Object)
    grid = event.GetRoSGNode()
    ' extract the row and column indexes of the item the user selected
    m.selectedIndex = event.GetData()
    ' the entire row from the RowList will be used by the Video node
	if getScene().FindNode("filteredList").visible then
        rowContent = grid.searchContent.Clone(true)
	else
        rowContent = grid.content.Clone(true)	
	end if
    m.selectedRow = m.selectedIndex
    ShowDetailsScreen(rowContent, m.selectedIndex)
end sub

function searchContent(content as Object, searchTerm as String) as Object
    searchResults = []
    for each item in content.GetChildren(- 1, 0)
		if instr(1, LCase(item.title), searchTerm) <> 0 then
            searchResults.push(item)
        end if
    end for
    contentNode = CreateObject("roSGNode", "ContentNode")
    contentNode.Update({children: searchResults}, true)
    return contentNode
end function