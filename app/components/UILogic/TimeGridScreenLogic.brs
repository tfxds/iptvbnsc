'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub ShowTimeGridScreen()
    m.liveNavMode = ""
    m.GridScreen = CreateObject("roSGNode", "TimeGridView")
	m.GridScreen.ObserveField("categorySelected", "OnCategorySelected")
	m.GridScreen.observeField("categoryFocused", "onCategoryFocused")
	'm.GridScreen.observeField("pin", "confirmPin")
    ShowScreen(m.GridScreen) ' show TimeGridView
	m.loadingIndicator.visible = true
end sub

sub onCategoryFocused(event)
    grid = event.GetRoSGNode()
    selectedIndex = event.GetData()
	if selectedIndex > -1 and m.GridScreen.content = invalid
		item = grid.category.GetChild(event.GetData())
		if item.look
        	m.look = createObject("roSGNode", "PinDialog")
        	m.look.title = tr("Enter Pin")
			if regread("lock", m.global.config.appName) = "0000" then m.look.message = tr("Default pin is 0000 to change it in account settings")
        	m.look.observeField("pin","confirmPinLook")
        	m.look.setFocus(true)
        	getScene().dialog = m.look
		else
		    ShowSpinner(true)
        	m.TimeGrid = CreateObject("roSGNode", "TimeGridLoaderTask")
        	m.TimeGrid.ObserveField("content", "OnTimeGridContentLoaded")
	    	m.TimeGrid.id =  item.id
        	m.TimeGrid.control = "run"
		end if
		
	end if
end sub

sub OnCategorySelected(event as Object)
    grid = event.GetRoSGNode()
	item = grid.category.GetChild(event.GetData())
	m.catID = item.id
	if m.global.contentTask <> invalid 
	    m.global.contentTask.control = "stop" 
	end if 
	if item.look
        m.look = createObject("roSGNode", "PinDialog")
        m.look.title = tr("Enter Pin")
		if regread("lock", m.global.config.appName) = "0000" then m.look.message = tr("Default pin is 0000 to change it in account settings")
        m.look.observeField("pin","confirmPinLook")
        m.look.setFocus(true)
        getScene().dialog = m.look
	else
	    ShowSpinner(true)
        m.TimeGrid = CreateObject("roSGNode", "TimeGridLoaderTask")
        m.TimeGrid.ObserveField("content", "OnTimeGridContentLoaded")
	    m.TimeGrid.id =  m.catID
        m.TimeGrid.control = "run"
	end if
end sub

sub loadLiveCategoryById(categoryId as String)
    m.catID = categoryId
    ' OBS: NAO cacheamos o conteudo MONTADO do preload -> no preload o m.global.play
    ' ainda nao esta setado pra live, entao as URLs sairiam quebradas. Usamos o cache
    ' CRU (m.global.liveStreamsRaw) e reconstruimos aqui com a URL correta.
    ShowSpinner(true)
    m.TimeGrid = CreateObject("roSGNode", "TimeGridLoaderTask")
    m.TimeGrid.ObserveField("content", "OnTimeGridContentLoaded")
    m.TimeGrid.id = categoryId
    m.TimeGrid.control = "run"
end sub

sub OnTimeGridContentLoaded(event as Object)
    populateLiveChannels(event.getData())
end sub

' Coloca os canais na tela + dispara EPG. Usado pela rede E pelo cache (preload).
sub populateLiveChannels(content as Object)
    m.loadingIndicator.visible = false
    if content = invalid then return
    ' Guarda anti-crash: se o usuario saiu da TV ao vivo antes dos canais carregarem,
    ' a TimeGridView (e o GroupGuia) ja sairam da cena -> FindNode vira invalid.
    if m.GridScreen = invalid or m.GridScreen.subtype() <> "TimeGridView" then return
    gg = m.top.getscene().FindNode("GroupGuia")
    if gg <> invalid then gg.visible = true
    ShowSpinner(false)
    m.GridScreen.SetFocus(true)
    m.GridScreen.content = content

    if m.liveNavMode = "catchup"
        m.GridScreen.callFunc("applyCatchupMode")
    else if m.liveNavMode = "multi"
        m.GridScreen.callFunc("applyMultiMode")
    else
        m.GridScreen.callFunc("collapseMenu")
    end if
    m.liveNavMode = ""

	if content.GetChildCount() <> 0
        m.global.contentTask = CreateObject("roSGNode", "epgLoaderTask")
	    m.global.contentTask.content = m.GridScreen.content
        m.global.contentTask.control = "run"
	end if
end sub

sub confirmPinLook() 
    if m.look.pin.len() = 4 then
	    m.confirmPin = createObject("roSGNode", "PinTask")
        m.confirmPin.section = m.global.config.appName
        m.confirmPin.pin = m.look.pin
        m.confirmPin.observeField("state","showAdultsLook")
        m.confirmPin.control = "RUN"
    end if
end sub

sub showAdultsLook()
    if m.confirmPin.state = "stop" then 
        if m.confirmPin.result then
		    ShowSpinner(true)
		    getScene().dialog.close = true
            m.TimeGrid = CreateObject("roSGNode", "TimeGridLoaderTask")
            m.TimeGrid.ObserveField("content", "OnTimeGridContentLoaded")
	        m.TimeGrid.id =  m.catID
            m.TimeGrid.control = "run"
        else
            m.look.title = tr("Incorrect Pin, try again")
            m.look.pin = ""
			m.look.setFocus(true)
        end if
    end if
end sub

sub ShowSpinner(show)
	' Guarda anti-crash: spinner pode nao estar na cena (usuario saiu antes do load).
	sp = m.top.getscene().FindNode("spinner")
	if sp = invalid then return
	sp.visible = show
    if show
        sp.control = "start"
    else
        sp.control = "stop"
    end if
end sub