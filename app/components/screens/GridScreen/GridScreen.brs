'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub Init()
	mBind(["markupList", "markupGrid", "listContainer", "searchBox", "searchKeyboard", "logo", "openMenu", "closeMenu", "pointer", "filteredList", "contentLabel", "header", "countPill", "countLabel"])

	' Cobre o fundo com o gradiente em tela cheia (sem a colagem de posteres do painel).
	' bgGradient (primeiro filho) ja cobre; mantemos o backgroundColor escuro como fallback.
	getScene().backgroundColor = "0x070c16"

	' WHITELABEL: o titulo de marca fixo "S.A PLAYER" (era a logo do topo esquerdo do
	' painel lateral) foi removido por pedido do cliente — nao mostrar marca fixa aqui.
	if m.logo <> invalid then m.logo.visible = false

    m.top.ObserveField("visible", "onVisibleChange")
	m.markupList.ObserveField("content", "onCategoryContentChange")
	m.markupGrid.ObserveField("content", "onGridContentChange")
	m.searchKeyboard.ObserveField("text", "OnKeyboardTextChanged")

    m.centerY = (getScreenSize().height - m.pointer.height) / 2
	m.pointer.translation = [ 504 , m.centerY ]
	m.markupList.SetFocus(true)

end sub

sub OnVisibleChange() ' invoked when GridScreen change visibility
    if m.top.visible = true and not m.filteredList.visible
        m.markupGrid.SetFocus(true) ' set focus to rowList if GridScreen visible
	else
        m.filteredList.SetFocus(true) ' set focus to rowList if GridScreen visible
    end if
end sub

sub onCategoryContentChange()
	' nada extra por enquanto; placeholder para futuros ajustes visuais
end sub

sub onGridContentChange()
	' Atualiza o contador de titulos do cabecalho.
	count = 0
	if m.markupGrid.content <> invalid then count = m.markupGrid.content.getChildCount()
	if count = 1 then
		m.countLabel.text = "1 titulo"
	else
		m.countLabel.text = count.toStr() + " titulos"
	end if
end sub

sub OnKeyboardTextChanged(event as Object)
	' (sem debug para publicacao)
	searchText = event.GetData()
    m.searchBox.text = searchText
	if searchText.IsEmpty()
	   	focusSearchBox(true)
	else
	    focusSearchBox()
	end if
end sub

sub expandMenu()
    m.top.jumpToItem =  m.top.categorySelected
	m.openMenu.control = "start"
    m.markupGrid.SetFocus(false)
	if m.searchKeyboard.visible then
		m.searchKeyboard.setFocus(true)
	else
		m.markupList.setFocus(true)
	end if
	m.pointer.uri = "pkg:/images/icons/left.png"
	m.pointer.translation = [ 504 , m.centerY ]
end sub

sub collapseMenu()
	m.closeMenu.control = "start"
	if m.searchKeyboard.visible then
		m.searchKeyboard.setFocus(false)
		m.filteredList.SetFocus(true)
	else
		m.markupList.setFocus(false)
		m.filteredList.SetFocus(false)
		m.markupGrid.SetFocus(true)
	end if
	m.pointer.uri = "pkg:/images/icons/right.png"
	m.pointer.translation = [ 474 , m.centerY ]
end sub

sub openKeyboard()
    m.markupList.setFocus(false)
	m.markupList.visible = "false"
	focusSearchBox(true)
	m.searchKeyboard.setFocus(true)
	m.searchKeyboard.visible = "true"
end sub

sub focusSearchBox(animate=false)
    m.searchBox.active = "false"
    if not animate return
    m.searchBox.active = "true"
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press then
        if key = "left" and not m.searchKeyboard.isInFocusChain() and not m.markupList.hasFocus() then
		    expandMenu()
            handled = true
        else if key = "right" and not ( m.markupGrid.hasFocus() or m.filteredList.hasFocus() ) then
		    collapseMenu()
            handled = true
        else if key = "up" and m.markupList.itemFocused = 0 and m.markupList.hasFocus() then
			openKeyboard()
            handled = true
		else if key = "down" and not m.markupList.hasFocus() then
            if m.searchBox.isInFocusChain() then
			    m.markupList.setFocus(true)
			    m.searchBox.setFocus(false)
            end if
            handled = true
		else if key = "OK" then
		    handled = true
		else if key = "back" then
			if m.searchKeyboard.isInFocusChain() and m.searchKeyboard.visible then
				m.searchKeyboard.setFocus(false)
			    m.searchKeyboard.visible = "false"
				focusSearchBox()
			    m.markupList.setFocus(true)
				m.markupList.visible = "true"
			    handled = true
			else if ( m.markupGrid.hasFocus() or m.filteredList.hasFocus() )
		        expandMenu()
                handled = true
			end if
        end if
    end if

    return handled
end function
