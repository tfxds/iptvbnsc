'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
sub ShowVideoScreen(rowContent as Object, selectedItem as Integer, isSeries = false as Boolean)
    m.isSeries = isSeries
    ' Capa do "assistidos": SERIE usa a capa da SERIE (global setado pelo caller, sobrevive
    ' ao Clone(false) que apaga campos customizados como mediaType/seriesPoster). FILME nao
    ' pode herdar a capa da serie anterior -> limpa o global aqui. Assim o Player nao precisa
    ' do mediaType (que se perde no clone): se o global tem valor, e serie; senao, filme.
    if isSeries = false
        m.global.currentSeriesPoster = ""
        m.global.currentSeriesId = ""
        m.global.currentSeriesTitle = ""
    end if
    ' CRITICO (trocar direto de um filme pro outro): derruba EXPLICITAMENTE o player
    ' anterior ANTES de criar o novo. Roku tem 1 decoder so e libera de forma assincrona;
    ' sem isso, o filme novo tentava bufferizar com o decoder do antigo ainda preso ->
    ' "travada na tela de carregamento". Para + solta content + desobserva o no antigo.
    if m.videoPlayer <> invalid
        m.videoPlayer.control = "stop"
        m.videoPlayer.content = invalid
        m.videoPlayer.unobserveField("visible")
        m.videoPlayer.unobserveField("closeVideo")
        m.videoPlayer = invalid
    end if
    m.videoPlayer = CreateObject("roSGNode", "VideoPlayer") ' create new instance of video node for each playback
	if isSeries
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
		m.id = m.videoPlayer.content.GetChild(0).id
		m.length = m.videoPlayer.content.GetChild(0).length
		m.videoPlayer.contentIsPlaylist = true ' enable video playlist (a sequence of videos to be played)
	else
	    m.videoPlayer.content = rowContent.GetChild(selectedItem)
	    m.id = m.videoPlayer.content.id
		m.length = m.videoPlayer.content.length
	end if	

    m.resume = createObject("roSGNode", "ResumeVideo")
    m.resume.section = "VideoPosition"
    m.resume.id = m.id
    m.resume.control = "RUN"
    m.resume.observeField("state","resume")
	
    m.videoPlayer.ObserveField("visible", "OnVideoVisibleChange")
    m.videoPlayer.ObserveField("closeVideo", "OnVideoScreenClose")

end sub

sub OnVideoScreenClose(event as Object) ' invoked once videoScreen's close field is changed
    videoScreen = event.GetRoSGNode()
    close = event.GetData()
    if close = true
	    m.videoPlayer.control = "stop" ' stop playback
        ' CRITICO: liberar o content do Video -> solta o decoder. Sem isso, sair do filme
        ' pelo BACK deixava o decoder preso e o PROXIMO filme ficava so carregando (Roku
        ' tem 1 decoder so). O caminho por visibilidade ja fazia isso; o do back nao.
        m.videoPlayer.content = invalid
        CloseScreen(videoScreen) ' remove videoScreen from scene and close it
        screen = GetCurrentScreen()
        screen.SetFocus(true) ' return focus to DetailsScreen
        ' in case of series we shouldn't change focus on DetailsScreen
        ' (a tela atual pode ser MyListScreen/VideoPlayer, que NAO tem jumpToItem ->
        '  set falha e gera warning no log; so seta quando o campo existir).
        if m.isSeries = false and screen <> invalid and screen.hasField("jumpToItem")
            screen.jumpToItem = m.selectedIndex
        end if
        refreshRecentlyWatchedIfNeeded(screen)
    end if
end sub

' Voltou pro "recentemente assistido" depois de assistir (serie aberta de la) -> recarrega a
' lista pra refletir o episodio atual. Sem isso so atualizava FECHANDO o app (a tela carrega
' o conteudo 1x e nao relê o registro ao reentrar).
sub refreshRecentlyWatchedIfNeeded(screen as Object)
    if m.cwReturnRefresh <> true then return
    if m.MyListScreen = invalid or screen = invalid then return
    if not screen.isSameNode(m.MyListScreen) then return
    m.cwReturnRefresh = false
    m.global.menuNavMode = "recordings"
    RunMyListTask()
end sub

sub OnVideoVisibleChange() ' invoked when video node visibility is changed
    if m.videoPlayer.visible = false and m.top.visible = true
        ' the index of the video in the video playlist that is currently playing.
        currentIndex = m.videoPlayer.contentIndex
        m.videoPlayer.control = "stop" ' stop playback
        'clear video player content, for proper start of next video player
        m.videoPlayer.content = invalid
        screen = GetCurrentScreen()
        screen.SetFocus(true) ' return focus to details screen
        newIndex = m.selectedIndex
        if m.isSeries = true
           m.isSeries = false
        else
           newIndex += currentIndex
        end if
        ' navigate to the last played item (so se a tela tiver jumpToItem; MyListScreen nao tem)
        if screen <> invalid and screen.hasField("jumpToItem") then screen.jumpToItem = newIndex
        refreshRecentlyWatchedIfNeeded(screen)
    end if
end sub

sub resume()
    if m.resume.state = "stop"
        ' Retoma se posicao salva >= 60s e nao esta perto do fim. Se o length for
        ' desconhecido (itens de Continuar Assistindo sem duration) NAO bloqueia o resume.
        lengthVal = 0
        if m.length <> invalid then lengthVal = m.length
        canResume = (m.resume.pos >= 60)
        if lengthVal > 0 and m.resume.pos >= (lengthVal * 0.9) then canResume = false
        if canResume then
            m.dialog = createObject("roSGNode", "Dialog")
            m.dialog.title = "Continuar assistindo"
            m.dialog.optionsDialog = true
            resumePos = "Continuar de " + GetDurationStringStandard(m.resume.pos)
            m.dialog.buttons = [resumePos,"Recomeçar"]
            m.top.getScene().dialog = m.dialog
            m.dialog.observeField("buttonSelected","resumeSelected")
        else
            ShowScreen(m.videoPlayer) ' show video screen
            m.videoPlayer.control = "play" ' start playback
        end if
    end if
end sub

sub resumeSelected()
    if m.dialog.buttonSelected = 0 then
        ShowScreen(m.videoPlayer) ' show video screen
	    m.videoPlayer.seek = m.resume.pos
        m.videoPlayer.control = "play" ' start playback
    else
        ShowScreen(m.videoPlayer) ' show video screen
        m.videoPlayer.control = "play" ' start playback
    end if
    m.dialog.close = true
end sub 
