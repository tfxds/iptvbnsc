'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub init()
    m.top.keyGrid.keyDefinitionUri="pkg:/json/SearchKeyboard.json"
    m.top.keyGrid.horizWrap = true
    m.top.keyGrid.vertWrap = true
	m.top.hideTextBox = true
    ' TODO: Get a background image from UX and palette colors to demonstrate how to customize keyboard colors
    'keyboardPalette = createObject("roSGNode", "RSGPalette")
    'keyboardPalette.colors = { "FocusColor": "0x00CCCCFF", "PrimaryTextColor": "0xFFFF00FF", "SecondaryItemColor": "0xFE1E1E1FF", "FocusItemColor": "0xFFFF00FF", "KeyboardColor": "0x00CCCC80", "InputFieldColor":"0x00CCCC80" }
    'm.top.palette = keyboardPalette
end sub

sub modeChanged()
    updateMode(m.top.mode)
end sub

sub updateMode(mode as String)
    m.currMode = mode
    if m.currMode <> m.top.keyGrid.mode
        m.top.keyGrid.mode = m.currMode
    end if
end sub

function keySelected(key as string) as boolean
    '? "KEY SELECTED: "; key
	'? "CurrMode ";m.currMode
    if (m.currMode = "ABC123Shift")
        updateMode("ABC123Lower")
    end if
	handled = false
    if (key = "shift")
        updateMode("ABC123Shift")
	    handled = true
    else if (key = "capslock")
        if (m.currMode = "ABC123Upper")
            updateMode("ABC123Lower")
        else if (m.currMode = "ABC123Lower")
            updateMode("ABC123Upper")
        else if (m.currMode = "SymbolsLower")
            updateMode("SymbolsUpper")
        else if (m.currMode = "SymbolsUpper")
            updateMode("SymbolsLower")
        else if (m.currMode = "AccentsLower")
            updateMode("AccentsUpper")
        else if (m.currMode = "AccentsUpper")
            updateMode("AccentsLower")
        end if
	    handled = true
    else if (key = "abc123")
        updateMode("ABC123Lower")
	    handled = true
    else if (key = "symbols")
        updateMode("SymbolsLower")
	    handled = true
    else if (key = "accents")
        updateMode("AccentsLower")
	    handled = true
    else if (key = "close")
	    m.top.keyClose = true
	    handled = true
    else if (key = "left")
        cursorPosition = m.top.textEditBox.cursorPosition
        if cursorPosition > 0
            m.top.TextEditBox.cursorPosition = cursorPosition - 1
        end if
	    handled = true
    else if (key = "right")
        cursorPosition = m.top.textEditBox.cursorPosition
        m.top.TextEditBox.cursorPosition = cursorPosition + 1
	    handled = true
    end if
    return handled
end function