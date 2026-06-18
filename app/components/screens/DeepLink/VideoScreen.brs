'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub Init()
    mBind(["player"])
	
    m.player.width = getScreenSize().width
    m.player.height = getScreenSize().height
    m.player.ObserveField("state", "OnPlayerTaskStateChange")   ' close screen once exited
    m.top.ObserveField("visible", "OnVisibleChanged")
end sub

sub OnVisibleChanged(event as Object) ' invoked when VideoScreen visibility is changed
    visible = event.GetData()
    ' Video node content must be invalidated if videoScreen is closed but playerTask still running
    if visible = false and m.player <> invalid
        m.player.UnobserveField("state")
        m.player.control = "stop"
        m.player = invalid
    end if
end sub

sub OnIndexChanged() ' invoked when "startIndex" field is changed
    content = m.top.content
    ' check if content was populated
    if content <> invalid
        ' set playlist data and start task
        m.player.content = content
        m.player.control = "play"
    end if
end sub

' close videoScreen once player finished or stopped
sub OnPlayerTaskStateChange(event as Object)
    state = event.GetData()
    if (state = "none" or state = "stopped" or state = "error" or state = "finished") and m.player <> invalid
        m.player = invalid
        m.top.close = true
    end if
end sub

' The OnKeyEvent() function receives remote control key events
function OnKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press
        ' handle "back" key press
        if key = "back" and m.player <> invalid
            ' we should stop playback and close this screen when user press "back" button
            m.player.control = "stop" ' as a result OnPlayerTaskStateChange is invoked
            result = true
        end if
    end if
    return result
end function