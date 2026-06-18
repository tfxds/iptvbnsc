' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

sub ShowDeepVideoScreen(content as Object)

    m.videoPlayer = CreateObject("roSGNode", "VideoScreenDeep") ' create new instance of video node for each playback
    m.videoPlayer.content = content.Clone(true)
    'm.videoPlayer.contentIsPlaylist = true ' enable video playlist (a sequence of videos to be played)
    ShowScreen(m.videoPlayer) ' show video screen
    'm.videoPlayer.control = "play" ' start playback
    'm.videoPlayer.ObserveField("state", "OnVideoPlayerStateChange")
	m.videoPlayer.observeField("close", "OnVideoScreenClose")
    m.videoPlayer.ObserveField("visible", "OnVideoVisibleChange")

end sub

sub OnVideoVisibleChange() ' invoked when video node visibility is changed
    if m.videoPlayer.visible = false and m.top.visible = true
        m.videoPlayer.SetFocus(true) ' return focus to details screen
    end if
end sub

sub OnVideoPlayerStateChange() ' invoked when video state is changed
    state = m.videoPlayer.state
    ' close video screen in case of error or end of playback
    if state = "error" or state = "finished"
        CloseScreen(m.videoPlayer)
    end if
end sub

sub OnVideoScreenClose(event as Object) ' invoked once videoScreen's close field is changed
    videoScreen = event.GetRoSGNode()
    close = event.GetData()
    if close = true
        CloseScreen(videoScreen) ' remove videoScreen from scene and close it
        screen = GetCurrentScreen()
        screen.SetFocus(true) ' return focus to DetailsScreen
        if m.deepLinkDetailsScreen <> invalid
            content = videoScreen.content
            if content <> invalid
                m.deepLinkDetailsScreen.content = content.clone(true)
            end if
        end if
    end if
end sub