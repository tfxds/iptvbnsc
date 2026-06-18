'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
Sub init()
    mBind(["settingLabel", "menu", "title", "message", "checklist", "MainMenu", "pinWidget", "MainInfo", "titlePin", "bottomPin", "delete", "radiolist", "bgSettings", "headerLogo", "headerTitle", "headerSub", "menuGlassRing", "menuGlassFill", "infoDivider"])

	'getScene().FindNode("overhang").visible = false
    getScene().backgroundColor = "0x0a1326FF"
    getScene().backgroundUri = ""

	screen = getScreenSize()
	m.bgSettings.width = screen.width
	m.bgSettings.height = screen.height
	m.bgSettings.translation = [0, 0]

	' Header novo (logo do REVENDEDOR + titulo) substitui o "Configurações" solto
	m.settingLabel.visible = false
	m.headerLogo.uri = getGlobalLogoMenu()
	m.headerTitle.text = tr("CONFIGURAÇÕES")
	m.headerSub.text = tr("Ajustes do aplicativo e da sua conta")
	m.focused_menu_item = -1
	
    ' create buttons
    button = []
	if regread("lock", m.global.config.appName) = "0000"
        button.push({title : tr("Alterar PIN"), "list_selection": "pkg:/images/list_selection.png", "list_selection_focus": "pkg:/images/list_selection_focus.png", icon: "pkg:/images/icons/lock_open.png", description : tr("Altere seu pin para proteger seu conteúdo e configurações adultos.")})
    else
        button.push({title : tr("Alterar PIN"), "list_selection": "pkg:/images/list_selection.png", "list_selection_focus": "pkg:/images/list_selection_focus.png", icon: "pkg:/images/icons/lock_close.png", description : tr("Altere seu pin para proteger seu conteúdo e configurações adultos.")})
	end if	
    button.push({title : tr("Ocultar categorias de canais"), "list_selection": "pkg:/images/list_selection.png", "list_selection_focus": "pkg:/images/list_selection_focus.png", icon: "pkg:/images/icons/hide_icon.png", description : tr("Selecione todas as categorias que deseja proteger com um código de segurança para controlar conteúdo adulto.")})
    button.push({title : tr("Ocultar categorias de filmes"), "list_selection": "pkg:/images/list_selection.png", "list_selection_focus": "pkg:/images/list_selection_focus.png", icon: "pkg:/images/icons/hide_icon.png", description : tr("Selecione todas as categorias que deseja proteger com um código de segurança para controlar conteúdo adulto.")})
    button.push({title : tr("Ocultar categorias de séries"), "list_selection": "pkg:/images/list_selection.png", "list_selection_focus": "pkg:/images/list_selection_focus.png", icon: "pkg:/images/icons/hide_icon.png", description : tr("Selecione todas as categorias que deseja proteger com um código de segurança para controlar conteúdo adulto.")})
    button.push({title : tr("Classificar lista de conteúdo"), "list_selection": "pkg:/images/list_selection.png", "list_selection_focus": "pkg:/images/list_selection_focus.png", icon: "pkg:/images/icons/sort.png", description : tr("Classifique a lista de conteúdo para melhorar a exibição do conteúdo.")})
    button.push({title : tr("Formato de fluxo"), "list_selection": "pkg:/images/list_selection.png", "list_selection_focus": "pkg:/images/list_selection_focus.png", icon: "pkg:/images/icons/format-live.png", description : tr("Formato de transmissão para canais ao vivo.")})		
	button.push({title : tr("Remover conta do dispositivo"), "list_selection": "pkg:/images/list_selection.png", "list_selection_focus": "pkg:/images/list_selection_focus.png", icon: "pkg:/images/icons/unlink.png", description : tr("Remover conta deste dispositivo Isso apagará todos os dados deste dispositivo relacionados a esta conta.")})
    
    parentContent = createObject("roSgNode", "contentNode")

    for each item in button 
        childContent = parentContent.createChild("listFields")
        childContent.title = item.title
        childContent.list_selection = item.list_selection
        childContent.list_selection_focus = item.list_selection_focus
        childContent.icon = item.icon
        childContent.description = item.description
    end for
	
	m.menu.content = parentContent
	
	m.MainMenu.height = m.menu.boundingRect().height + 100
    ' Menu LOGADO abaixo do header (nao mais centralizado na vertical) e sem o gap interno
    ' do settingLabel (some o [60,80] -> [40,20]). Card de vidro (ring+fill) atras pra nao
    ' ficar flutuando no gradiente.
    m.menu.translation = [ 40, 20 ]
    menuTop = 215
    m.MainMenu.translation = [ 90 , menuTop ]

    menuH = m.menu.boundingRect().height
    glassX = 110
    glassY = menuTop + 8
    glassW = 575
    glassH = menuH + 28
    m.menuGlassRing.translation = [ glassX - 4, glassY - 4 ]
    m.menuGlassRing.width = glassW + 8
    m.menuGlassRing.height = glassH + 8
    m.menuGlassFill.translation = [ glassX, glassY ]
    m.menuGlassFill.width = glassW
    m.menuGlassFill.height = glassH

	m.MainInfo.translation = [ getScreenSize().width - m.MainInfo.width - 40 , (getScreenSize().height - m.MainInfo.height) / 2 ]
	
	m.title.translation = [ (m.MainInfo.boundingRect().width - m.title.width) / 2 , 20 ]
	m.infoDivider.translation = [ (m.MainInfo.boundingRect().width - m.infoDivider.width) / 2 , 92 ]
	m.infoDivider.visible = true

	m.message.translation = [ (m.MainInfo.boundingRect().width - m.message.width) / 2 , 700 ]
	
	m.titlePin.translation = [ (m.MainInfo.boundingRect().width - m.titlePin.boundingRect().width) / 2 , 150 ]
	m.pinWidget.translation = [ (m.MainInfo.boundingRect().width - m.pinWidget.boundingRect().width) / 2 , 220 ]
	m.delete.translation = [ (m.MainInfo.boundingRect().width - m.delete.boundingRect().width) / 2 , 220 ]
	m.bottomPin.translation = [ (m.MainInfo.boundingRect().width - m.bottomPin.boundingRect().width) / 2 , 700 ]
	
	m.checklist.translation = [ m.MainInfo.boundingRect().width / 4  , 130 ]
	m.radiolist.translation = [ m.MainInfo.boundingRect().width / 4  , 130 ]
	
    m.menu.observeField("itemSelected", "on_menu_item_selected")
    m.menu.observeField("itemFocused", "on_menu_item_focused")
    m.checklist.observeField("checkedState", "on_checked_state_update")
	m.radiolist.observeField("checkedItem", "on_checked_Item_update")
	
    m.category = CreateObject("roSGNode", "CategorylistTask")
	m.category.ObserveField("finish", "OnCategorylist")
    m.category.control = "run"
	
	m.menu.setFocus(true)
	
End Sub

' Handle menu item focus
function OnCategorylist(event as object) as void
	list = event.GetRoSGNode()
	m.top.setField("channelCategory", list.live)
	m.top.setField("moviesCategory", list.movies)
	m.top.setField("seriesCategory", list.series)
end function

' Handle menu item selected
function on_menu_item_selected(event as object) as void
    select_menu_item(event.getData())
end function

' Handle menu item focus
function on_menu_item_focused(event as object) as void
    focus_menu_item(event.getData())
end function

' Select a menu item
function select_menu_item(item as integer) as void
    ' Parental
    if item = 0
        m.pinwidget.setFocus(true)
		m.titlePin.text = tr("Enter Current Pin")
		if regread("lock", m.global.config.appName) = "0000" then m.bottomPin.text = tr("O PIN padrão é 0000 para alterar")
    ' Hide Live
    else if item = 1
        m.checklist.setFocus(true)
    ' Hide movies
    else if item = 2
        m.checklist.setFocus(true)
    ' Hide Series
    else if item = 3
        m.checklist.setFocus(true)
    ' Sort
    else if item = 4
        m.radiolist.setFocus(true)
    ' Stream Format
    else if item = 5
        m.radiolist.setFocus(true)
    ' Remove
    else if item = 6
        m.look = createObject("roSGNode", "PinDialog")
        m.look.title = tr("Enter Pin")
        m.look.pinPad.secureMode  = false
        m.look.pinPad.pinLength   = "4"
		if regread("lock", m.global.config.appName) = "0000" then m.look.message = tr("Default pin is 0000 to change it in account settings")
        m.look.buttons = [tr("OK")]
        m.look.observeField("buttonSelected","onVerifyRemoveAccount")
        m.look.setFocus(true)
	    getScene().dialog = m.look
    ' Unhandled
    else
        print "Unhandled setting menu item selected: " + item.toStr()
    end if
end function


' Focus a menu item
function focus_menu_item(item as integer) as void
    reset()
	content = m.menu.content.GetChild(item)
    m.focused_menu_item = item
    ' Parental
    if item = 0
        m.title.text = content.title
        m.message.text = content.description
		m.titlePin.text = tr("Insira o PIN atual")
		m.pinwidget.visible = true
		if regread("lock", m.global.config.appName) = "0000" then m.bottomPin.text = tr("O PIN padrão é 0000 para alterar")
    ' Hide Live
    else if item = 1
        checked_state = []
        ' Set title
        m.title.text = content.title
        m.message.text = content.description
        ' Clear content
        m.checklist.content.removeChildrenIndex(m.checklist.content.getChildCount(), 0)
        ' Add items
        for each lang_item in m.top.channelCategory
            lang_enabled = false
			if m.global.channelCategory <> invalid
			    for each code in m.global.channelCategory
                    if lang_item.code = code
                        lang_enabled = true
                    end if
                end for
			end if	
            checked_state.push(lang_enabled)
            ' Add code to checklist
            check_item = m.checklist.content.createChild("ContentNode")
            name = clean(lang_item.name)
            check_item.title = name
            check_item.hideicon = false
        end for
        ' Set checklist state
        m.checklist.checkedState = checked_state
        m.checklist.visible = true
    ' Hide Movies
    else if item = 2
        checked_state = []
        ' Set title
        m.title.text = content.title
        m.message.text = content.description
        ' Clear content
        m.checklist.content.removeChildrenIndex(m.checklist.content.getChildCount(), 0)
        ' Add lang items
        for each lang_item in m.top.moviesCategory
            lang_enabled = false
			if m.global.moviesCategory <> invalid
                for each lang in m.global.moviesCategory
                    if lang_item.code = lang
                        lang_enabled = true
                    end if
                end for
			end if
            checked_state.push(lang_enabled)
            ' Add lang to checklist
            check_item = m.checklist.content.createChild("ContentNode")
            name = clean(lang_item.name)
            check_item.title = name
            check_item.hideicon = false
        end for
        ' Set checklist state
        m.checklist.checkedState = checked_state
        m.checklist.visible = true
    ' Hide Series
    else if item = 3
        checked_state = []
        ' Set title
        m.title.text = content.title
        m.message.text = content.description
        ' Clear content
        m.checklist.content.removeChildrenIndex(m.checklist.content.getChildCount(), 0)
        ' Add lang items
        for each lang_item in m.top.seriesCategory
            lang_enabled = false
			if m.global.seriesCategory <> invalid
                for each lang in m.global.seriesCategory
                    if lang_item.code = lang
                        lang_enabled = true
                    end if
                end for
			end if
            checked_state.push(lang_enabled)
            ' Add lang to checklist
            check_item = m.checklist.content.createChild("ContentNode")
            name = clean(lang_item.name)
            check_item.title = name
            check_item.hideicon = false
        end for
        ' Set checklist state
        m.checklist.checkedState = checked_state
        m.checklist.visible = true
    ' Sort
    else if item = 4
        ' Set title
        m.title.text = content.title
        m.message.text = content.description
        ' Clear content
        m.radiolist.content.removeChildrenIndex(m.radiolist.content.getChildCount(), 0)
        ' Add sort items
        items = []
        items.push( { code : "auto" , "title": "Automatic" } )
        items.push( { code : "name" , "title": "Sort by alphabet" } )
        items.push( { code : "id" , "title": "Sort by last" } )
        for each sort in items
            radio_item = m.radiolist.content.createChild("ContentNode")
            radio_item.title = tr(sort.title)
        end for
        ' Set selected item - MODIFICADO: Por defecto "Sort by last" (más recientes)
        if m.global.sort = invalid or m.global.sort = ""
            ' Por defecto seleccionar "Sort by last" (más recientes)
            m.radiolist.checkedItem = 2
            m.global.sort = "id"
            regWrite("sort", "id", m.global.config.appName)
        else
            ' Buscar la opción guardada
            for sort = 0 to items.count() - 1
                if m.global.sort = items[sort].code
                    m.radiolist.checkedItem = sort
                    exit for
                end if
            end for
        end if
        ' Show sort list
        m.radiolist.visible = true
    ' Stream Format
    else if item = 5
        ' Set title
        m.title.text = content.title
        m.message.text = content.description
        ' Clear content
        m.radiolist.content.removeChildrenIndex(m.radiolist.content.getChildCount(), 0)
        ' Add format items
        items = []
        items.push( { code : "hls" , "title": "M3u8 Streaming" } )
        items.push( { code : "ism" , "title": "Smooth Streaming" } )

        for each format in items
            radio_item = m.radiolist.content.createChild("ContentNode")
            radio_item.title = tr(format.title)
        end for
        ' Set selected item
        if m.global.streamFormat = "hls"
            m.radiolist.checkedItem = 0
        else
            for format = 0 to items.count() - 1
                if m.global.streamFormat = items[format].code
                    m.radiolist.checkedItem = format
                end if
            end for
        end if
        ' Show format list
        m.radiolist.visible = true
    ' Remove
    else if item = 6
        m.title.text = content.title
        m.message.text = content.description
		m.delete.visible = true
    ' Unhandled
    else
        print "Unhandled setting menu item focused: " + item.toStr()
    end if
end function

' Reset the title and message
function reset() as void
    m.title.text = ""
    m.message.text = ""
	m.titlePin.text = ""
	m.bottomPin.text = ""
	m.bottomPin.color = "#FFFFFF"
	m.pinwidget.visible = false
    m.checklist.visible = false
	m.radiolist.visible = false
	m.delete.visible = false
    m.focused_menu_item = -1
end function

' Handle checklist checked state change
function on_checked_state_update() as void
    if m.focused_menu_item = 1
        json = m.top.channelCategory
		code_global = m.global.channelCategory
    else if m.focused_menu_item = 2
        json = m.top.moviesCategory
		code_global = m.global.moviesCategory
    else if m.focused_menu_item = 3
        json = m.top.seriesCategory
		code_global = m.global.seriesCategory
    end if
    if json.count() <> m.checklist.checkedState.count()
        return
    end if
    ' Check if all was selected prior to modification
    all_selected = false
    for each code in code_global
        if code = "all"
            all_selected = true
        end if
    end for
    ' Initialize the counter
    trueCount = 0
    ' selects assets on array elements
    for each item in m.checklist.checkedState
        if item = true then
            trueCount += 1
        end if
    end for
    ' Uncheck others if all is selected
    if m.checklist.checkedState[0] and not all_selected
		'm.focused = false
        checkedState = [true]
        for index = 1 to json.count() - 1
            checkedState[index] = false
        end for
        m.checklist.checkedState = checkedState
    else if all_selected and trueCount <> 1
        checkedState = m.checklist.checkedState
        checkedState[0] = false
        m.checklist.checkedState = checkedState
    else if all_selected
        checkedState = m.checklist.checkedState
        m.checklist.checkedState = checkedState
    end if
    ' Create list of enabled
    category = []
    for index = 0 to json.count() - 1
        if m.checklist.checkedState[index]
            category.push(json[index].code)
        end if
    end for
    if m.focused_menu_item = 1 and m.checklist.hasFocus()
        m.global.channelCategory = category
		regWrite("channelCategory", FormatJSON(category), m.global.config.appName)
    else if m.focused_menu_item = 2 and m.checklist.hasFocus()
        m.global.moviesCategory = category
		regWrite("moviesCategory", FormatJSON(category), m.global.config.appName)
    else if m.focused_menu_item = 3 and m.checklist.hasFocus()
        m.global.seriesCategory = category
		regWrite("seriesCategory", FormatJSON(category), m.global.config.appName)
    end if
end function

' Handle radiolist checked item change
function on_checked_item_update(event as object) as void
    if m.focused_menu_item = 4
        if event.getData() = 0
			m.global.sort = "auto"
			regWrite("sort", "auto", m.global.config.appName)
        else if event.getData() = 1
			m.global.sort = "name"
			regWrite("sort", "name", m.global.config.appName)
        else if event.getData() = 2
			m.global.sort = "id"
			regWrite("sort", "id", m.global.config.appName)
        end if
    else if m.focused_menu_item = 5
        if event.getData() = 0
			m.global.streamFormat = "hls"
			regWrite("streamFormat", "hls", m.global.config.appName)
        else if event.getData() = 1
			m.global.streamFormat = "ism"
			regWrite("streamFormat", "ism", m.global.config.appName)
        end if
    end if
end function

sub onVerifyRemoveAccount()
	if m.look.buttonSelected = 0 and m.look.pin.len() = 4 then
       'print "ok button pressed"
        m.confirmPin = createObject("roSGNode", "PinTask")
        m.confirmPin.section = m.global.config.appName
        m.confirmPin.pin = m.look.pin
        m.confirmPin.observeField("state","removeAccount")
        m.confirmPin.control = "RUN"
    end if
end sub

sub removeAccount()
    if m.confirmPin.state = "stop" then 
        if m.confirmPin.result then
		   ' Remover conta = limpa o registro no painel (libera a vaga) + credenciais locais.
		   ' Em TASK (assincrono) -> nao travar a UI no POST sincrono.
		   devId = m.global.rokuUniqueID
		   if devId <> invalid and devId <> ""
		       t = createObject("roSGNode", "PanelLogoutTask")
		       t.deviceId = devId
		       getScene().appendChild(t)
		       t.control = "run"
		   end if
		   regDelete("userTV", m.global.config.appName)
		   regDelete("passTV", m.global.config.appName)
		   regDelete("forceLogin", m.global.config.appName)
		   getScene().close = true
        else
            m.look.title = tr("Incorrect Pin, try again")
            m.look.pin = ""
			m.look.setFocus(true)
        end if
    end if
end sub

' Handle keys
function onKeyEvent(key as string, press as boolean) as boolean
    ' Checklist / Radiolist
    if m.checklist.hasFocus() or m.radiolist.hasFocus()
        ' Set main settings menu focus
        if press and (key = "left" or key = "back")
            m.menu.setFocus(true)
            return true
        end if
    ' Menu
    else if m.menu.hasFocus()
        ' Activate
        if press and key = "right"
            if m.menu.itemFocused = 0
			    m.pinWidget.setFocus(true)
                return true
            else if m.menu.itemFocused = 1
                m.checklist.setFocus(true)
                return true
            else if m.menu.itemFocused = 2
                m.checklist.setFocus(true)
                return true
            else if m.menu.itemFocused = 3
                m.checklist.setFocus(true)
                return true
            else if m.menu.itemFocused = 4
                m.radiolist.setFocus(true)
                return true
            else if m.menu.itemFocused = 5
                m.radiolist.setFocus(true)
                return true
            else if m.menu.itemFocused = 6
                m.look = createObject("roSGNode", "PinDialog")
                m.look.title = tr("Enter Pin")
                m.look.pinPad.secureMode  = false
                m.look.pinPad.pinLength   = "4"
                if regread("lock", m.global.config.appName) = "0000" then m.look.message = tr("Default pin is 0000 to change it in account settings")
                m.look.buttons = [tr("OK")]
                m.look.observeField("buttonSelected","onVerifyRemoveAccount")
                m.look.setFocus(true)
                getScene().dialog = m.look
                return true
            end if
        end if
	else if (m.pinWidget.visible = true) and (m.menu.hasFocus() = false)	
        ' Activate
        if press and key = "left"
            if m.menu.itemFocused = 0
			    m.menu.setFocus(true)
                return true
            end if
        end if
    end if
    return false
end function