'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub Init()
    mBind(["loadingIndicator", "overhang", "clock", "timeServer"])

    applySceneBackground(m.top)

    ' Tela de carregamento: quando o poll (initGlobals) traz o branding do revendedor, atualiza
    ' o fundo e a logo do topo. So OBSERVA os globais ja existentes -> nao mexe no arranque.
    m.global.observeField("fondo", "onBrandingReady")
    m.global.observeField("logo", "onBrandingReady")
    if m.overhang <> invalid then m.overhang.logoUri = getGlobalLogo()


    '** Menu principal, imagen logo debe ser .logo

'**	m.overhang.logoUri = m.global.logo
'**m.overhang.visible = false
    
    InitScreenStack()
	go()
	m.clock.observeField("fire","updateTime")
	m.timeServer.observeField("fire", "serverTime")
	
	m.loadingIndicator.width = getScreenSize().width
	m.loadingIndicator.height = getScreenSize().height
end sub

sub serverTime()
	m.global.timeServer = m.global.timeServer + 1
	'Dbg("Time Server ", m.global.timeServer)
end sub

sub go()
    'Dbg("Run GO")    
    m.confirm = createObject("roSGNode", "ConfirmUserTask")
    m.confirm.control = "RUN"
    m.confirm.observeField("state", "done") 
end sub

sub done()
    'Dbg("Run Done")
    if m.confirm.state = "stop" then
        if m.confirm.auth = "1" then
	        m.timeServer.repeat = true
            m.timeServer.control = "start"
            if m.confirm.status = "Disabled" then
		        m.clock.repeat = false
                m.clock.control = "stop"
				WarningScreenLogic("Disabled")
				m.global.isExitApp = true
            else if m.confirm.status = "Banned" then
		        m.clock.repeat = false
                m.clock.control = "stop"
                WarningScreenLogic("Banned")
				m.global.isExitApp = true
            else if m.confirm.status = "Expired" then
		        m.clock.repeat = false
                m.clock.control = "stop"
                WarningScreenLogic("Expired")
				m.global.isExitApp = true
            else if m.confirm.status = "Active" then
                ShowMenuScreen()
				m.global.isExitApp = false
            end if   
        else
            ShowLoginScreen()
        end if
    end if
end sub

sub updateTime()
	Dbg("Update Time")
	m.clock.duration = 300
end sub

' Branding do revendedor chegou (via poll) -> atualiza fundo + logo do topo na tela de carregamento.
sub onBrandingReady()
    applySceneBackground(m.top)
    if m.overhang <> invalid then m.overhang.logoUri = getGlobalLogo()
end sub

' Modal de SAIR customizado (overlay proprio, mesmo visual do modal de conta) no lugar
' do Dialog nativo (sem estilo). Empilha como filho da cena e assume o foco.
sub showExitApp()
    if m.exitDlg <> invalid then return   ' ja aberto -> evita duplicar
    m.exitDlg = createObject("roSGNode", "ExitScreenDialog")
    m.exitDlg.observeField("action", "onExitDialogAction")
    m.top.appendChild(m.exitDlg)
    m.exitDlg.setFocus(true)
end sub

sub onExitDialogAction()
    if m.exitDlg = invalid then return
    if m.exitDlg.action = "exit"
        m.top.close = true
    else
        ' Cancelar / BACK -> fecha o overlay e devolve o foco a tela atual.
        m.top.removeChild(m.exitDlg)
        m.exitDlg = invalid
        cur = GetCurrentScreen()
        if cur <> invalid then cur.setFocus(true)
    end if
end sub

sub showExitButton()
    m.top.dialog.close = true
end sub

' The OnKeyEvent() function receives remote control key events
function OnkeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press
        ' handle "back" key press
        if key = "back"
            numberOfScreens = m.screenStack.Count()
			Dbg("Back",numberOfScreens)
			if numberOfScreens <> 3 and numberOfScreens <> 4 and numberOfScreens <> 5 and numberOfScreens <> 6
			   getScene().FindNode("overhang").visible = true
			   applySceneBackground(m.top)
			   if m.global.contentTask <> invalid
			       m.global.contentTask.control = "stop" 
			   end if 
			end if 
            if numberOfScreens > 1 and not m.global.isExitApp then
                CloseScreen(invalid)
                result = true
			else
			    showExitApp()
                result = true
            end if
        end if
    end if
    ' The OnKeyEvent() function must return true if the component handled the event,
    ' or false if it did not handle the event.
    return result
end function