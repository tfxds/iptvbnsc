'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub init()
    'getScene().backgroundUri = "pkg:/images/bg-main.jpg"

	mBind(["Title", "Description", "Buttons"])
    m.Title.text = tr("Your Account has been Expired")
	m.Description.text = tr("Your account has expired for some reason, to see what your reason was, contact your provider and you will get help to restore your account and enjoy your service again.")
		
	' create buttons
	result = []
	for each button in ["Remove account link from device"]
		result.push({title : tr(button)})
	end for
	m.buttons.content = ContentList2SimpleNode(result)

    m.top.observeField("focusedChild","onFocusedChildChange")
	m.top.observeField("buttonSelected", "onButtonSelected")
	
		
end sub

sub onFocusedChildChange()
    if m.top.hasFocus()
        m.buttons.setFocus(true)
		m.top.visible = true	
    end if
end sub

sub onButtonSelected()
    if m.top.buttonSelected = 0
		regDelete("userTV", m.global.config.appName)
		regDelete("passTV", m.global.config.appName) 
		getScene().close = true
    end if
end sub