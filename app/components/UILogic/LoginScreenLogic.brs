'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub ShowLoginScreen()
    m.LoginScreen = CreateObject("roSGNode", "LoginScreen")
	m.LoginScreen.ObserveField("success","ShowLoginMenuScreen")
	m.LoginScreen.observeField("status", "LoginDone")
    ShowScreen(m.LoginScreen) ' show LoginScreen
end sub

sub LoginDone()
    'Dbg("Validate Login Done", m.LoginScreen.status)
    if m.LoginScreen.status = "Disabled" then
		WarningScreenLogic("Disabled")
		m.global.isExitApp = true
    else if m.LoginScreen.status = "Banned" then
        WarningScreenLogic("Banned")
		m.global.isExitApp = true
    else if m.LoginScreen.status = "Expired" then
        WarningScreenLogic("Expired")
		m.global.isExitApp = true
    else if m.LoginScreen.status = "Active" then
	    m.LoginScreen.success = true
		m.global.isExitApp = false
		'getScene().backgroundColor = getTheme().backgroundColor
		'getScene().backgroundUri = "pkg:/images/bg-main.jpg"
    end if 
end sub

sub ShowLoginMenuScreen(event as Object)
	Dbg("Show Menu ", event.GetData())
    if event.GetData() <> invalid then
        m.dialog = createObject("roSGNode", "Dialog")
        m.dialog.title = tr("SUCESSO!")
        m.dialog.optionsDialog = true
		m.dialog.buttons = [tr("OK")]
        m.dialog.message = tr("Suas Credencias São Válidas")
        m.dialog.observeField("buttonSelected", "showExitButton")
        getScene().dialog = m.dialog
    end if
	CloseScreen(m.LoginScreen)
	ShowMenuScreen()
	getScene().FindNode("clock").repeat = true
    getScene().FindNode("clock").control = "start"
end sub

