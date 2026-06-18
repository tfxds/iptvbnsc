'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub ShowSettingScreen()
    m.SettingScreen = CreateObject("roSGNode", "SettingScreen")
	m.SettingScreen.ObserveField("pin","confirmPin")
    m.confirmPin = createObject("roSGNode", "WritePinTask")
    m.confirmPin.tipo = "1"
    m.confirmPin.observeField("state","confirmed")
	
    ShowScreen(m.SettingScreen) ' show SettingScreen
end sub

sub confirmPin() 
    if m.SettingScreen.pin.len() = 4 then
        m.confirmPin.section = m.global.config.appName
        m.confirmPin.pin = m.SettingScreen.pin
        m.confirmPin.observeField("state","confirmed")
        m.confirmPin.control = "RUN"
    end if
end sub

sub confirmed()
    if m.confirmPin.state = "stop" then 
        if m.confirmPin.result = "change" then
            getScene().FindNode("titlePin").text = tr("Enter Current Pin")
			m.confirmPin.tipo = "1"
            m.SettingScreen.pin = ""
            m.top.getscene().FindNode("bottomPin").text = tr("Pin changed successfully")
			getScene().FindNode("bottomPin").color = "#04af00"
			if m.confirmPin.pin <> "0000"
			    getScene().FindNode("menu").content.GetChild(0).icon = "pkg:/images/icons/lock_close.png"
			else
                getScene().FindNode("menu").content.GetChild(0).icon = "pkg:/images/icons/lock_open.png"			
			end if
        else if m.confirmPin.result = "run" then
            getScene().FindNode("titlePin").text = tr("Enter New Pin")
			m.confirmPin.tipo = "2"
            m.SettingScreen.pin = ""
            getScene().FindNode("bottomPin").text = ""
			getScene().FindNode("bottomPin").color = "#ffffff"
        else 
            getScene().FindNode("titlePin").text = tr("Enter Current Pin")
			m.confirmPin.tipo = "1"
            m.SettingScreen.pin = ""
            getScene().FindNode("bottomPin").text = tr("Incorrect Pin, try again")
			getScene().FindNode("bottomPin").color = "#ff0000"
        end if
    end if
end sub

