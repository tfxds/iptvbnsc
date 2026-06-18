'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub WarningScreenLogic(node as object)
    m.WarningScreen = CreateObject("roSGNode", node) ' create task for feed retrieving
    ShowScreen(m.WarningScreen) ' show RegScreen
end sub
