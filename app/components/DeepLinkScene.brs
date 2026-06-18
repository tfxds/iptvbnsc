'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
sub Init()
    ' set background color for scene. Applied only if backgroundUri has empty value
    mBind(["loadingIndicator", "overhang"])
	
    m.top.backgroundColor = getTheme().backgroundColor
	
    InitScreenStack()
    ShowGridScreenDeep()
    RunDeepLinkContentTask() ' retrieving content
end sub

' The OnKeyEvent() function receives remote control key events
function OnkeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press
        ' handle "back" key press
        if key = "back"
            numberOfScreens = m.screenStack.Count()
			Dbg("Back",numberOfScreens)
            if numberOfScreens > 1 then
                CloseScreen(invalid)
                result = true
            end if
        end if
    end if
    ' The OnKeyEvent() function must return true if the component handled the event,
    ' or false if it did not handle the event.
    return result
end function