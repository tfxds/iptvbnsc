'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
sub ShowVideoLiveScreen(rowContent as Object, selectedItem as Integer)
    m.videoPlayer = CreateObject("roSGNode", "Video") ' create new instance of video node for each playback
    ' we can't set index of content which should start firstly in playlist mode.
    ' for cases when user select second, third etc. item in the row we use the following workaround
    if selectedItem <> 0 ' check if user select any but first item of the row
        childrenClone = CloneChildren(rowContent, selectedItem)
        ' create new parent node for our cloned items
        rowNode = CreateObject("roSGNode", "ContentNode")
        rowNode.Update({ children: childrenClone }, true)
        m.videoPlayer.content = rowNode ' set node with children to video node content
    else
        ' if playback must start from first item we clone all row node
        m.videoPlayer.content = rowContent.Clone(true)
    end if
    m.videoPlayer.contentIsPlaylist = true ' enable video playlist (a sequence of videos to be played)
    ' Player AO VIVO igual ao de filme/serie: TELA CHEIA + SEM a UI nativa do Roku. A UI
    ' embutida (enableUI=true, padrao do Video cru) desenha uma barra/scrim preto que em
    ' canais de alta taxa (4K/FHD) fica REAPARECENDO a cada re-buffer -> "mancha preta
    ' piscando". O player de filme nao tem isso porque usa RenderlessVideo (enableUI=false);
    ' aqui replicamos. Nao mexe em decoder/playback (so esconde a UI embutida).
    m.videoPlayer.enableUI = false
    m.videoPlayer.width = getScreenSize().width
    m.videoPlayer.height = getScreenSize().height
    ShowScreen(m.videoPlayer) ' show video screen
    m.videoPlayer.control = "play" ' start playback
    m.videoPlayer.ObserveField("state", "OnVideoLiveStateChange")
    m.videoPlayer.ObserveField("visible", "OnVideoLiveVisibleChange")
end sub

sub OnVideoLiveStateChange() ' invoked when video state is changed
    state = m.videoPlayer.state
    ' close video screen in case of error or end of playback
    if state = "error" or state = "finished"
        CloseScreen(m.videoPlayer)
    end if
end sub

sub OnVideoLiveVisibleChange() ' invoked when video node visibility is changed
    if m.videoPlayer.visible = false and m.top.visible = true
        m.videoPlayer.control = "stop" ' stop playback
        'clear video player content, for proper start of next video player
        m.videoPlayer.content = invalid
        screen = GetCurrentScreen()
        screen.SetFocus(true) ' return focus to details screen
    end if
end sub