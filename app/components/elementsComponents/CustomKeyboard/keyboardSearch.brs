'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub init()
    'm.modes = [ "NameLower", "NameUpper", "FullLower", "FullUpper", "CityStateUpper", "CityStateLower", "Zip" ]
    m.top.keyGrid.keyDefinitionUri="pkg:/json/keyboardSearch.json"

    ' TODO: Get a background image from UX and palette colors to demonstrate how to customize keyboard colors
    'keyboardPalette = createObject("roSGNode", "RSGPalette")
    'keyboardPalette.colors = { "FocusColor": "0x00CCCCFF", "PrimaryTextColor": "0xFFFF00FF", "SecondaryItemColor": "0xFE1E1E1FF", "FocusItemColor": "0xFFFF00FF", "KeyboardColor": "0x00CCCC80", "InputFieldColor":"0x00CCCC80" }
    'm.top.palette = keyboardPalette
end sub
