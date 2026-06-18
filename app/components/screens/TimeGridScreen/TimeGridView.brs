sub init()
    mBind(["channelList", "group", "spinner", "loadingOverlay", "loadingMsg", "title", "info", "blending", "categoryList", "Video", "VideoLoading","InfoBar","TimerHint","Hint",
		   "HideBar", "ShowBar", "showInfo", "TitleInfo", "posterInfo", "TimerInfo", "TitleProgram", "progressBar",
		   "progressBarBack", "infoTimer", "TimerBar", "showAdult", "progressBarBackInfo", "progressBarInfo",
		   "TimerProgram", "stbSignal", "description", "descProgram", "rectLoading", "GroupGuia", "tituloCat", "optionDialog", "previewFrame", "aoVivoBadge", "previewLogo", "browseDim"])

    ' Inicializar campos globales si no existen
    if m.global.hasField("live") = false then
        m.global.addFields({live: []})
    end if

    ' Cargar favoritos guardados
    loadSavedFavorites()

    ' Variables para manejo de reconexión y buffer
    m.retryCount = 0
    m.maxRetries = 5
    m.retryDelay = 3 ' segundos
    m.bufferingStuckCount = 0

    ' Configuración de monitoreo de reproducción
    m.playbackMonitor = createObject("roSGNode", "Timer")
    m.playbackMonitor.repeat = true
    m.playbackMonitor.duration = 5 ' Verifica cada 5 segundos
    m.playbackMonitor.observeField("fire", "checkPlaybackStatus")
    m.playbackMonitor.control = "start"

    getScene().FindNode("overhang").visible = false
    applySceneBackground(getScene())

    ' (sem debug para publicação)
    ' LOGO REMOVIDA do painel de info: nao ha mais m.poster.

    m.top.observeField("content", "onTimeGridViewContentChange")

	' Lista vertical de canais (substitui a antiga grade EPG)
	m.channelList.observeField("itemSelected", "OnChannelRowSelected")
	m.channelList.observeField("itemFocused", "OnChannelRowFocused")

    m.blending.width = getScreenSize().width
	m.blending.height = getScreenSize().height

    ' InfoBar Epg
	m.InfoBar.width = getScreenSize().width
	m.InfoBar.translation = [0,getScreenSize().height]

    m.Video.observeField("state","controlvideoplay")

    ' PREVIA do canal SEM a UI nativa do Roku. O Video cru vem com enableUI=true (padrao):
    ' o Roku desenha a barra/scrim nativa DENTRO da telinha pequena -> nos canais 4K/FHD
    ' (que re-bufferizam) isso aparece como a "mancha preta" na area de selecao do canal
    ' (em tela cheia some porque a barra fica no rodape de 1080p e a UI fica escondida).
    ' enableUI=false mata a mancha; a previa ja tem UI propria (videoLoading/stbSignal).
    ' (Os antigos enableBuffering/bufferingParams NAO existem no node Video -> so geravam
    '  warning no log e nao faziam nada; removidos.)
    m.Video.enableUI = false
    ' Video AO VIVO em TELA CHEIA sempre (atras dos paineis). A mancha era o downscale do 4K/FHD
    ' na previa pequena; em tela cheia nao reduz -> sem mancha. (Sem maxVideoDecodeResolution: em
    ' tela cheia ele limitaria a qualidade.)

	m.TimerHint.observeField("fire", "hideHint")
	m.TimerBar.observeField("fire", "hideShowBar")

    m.showInfo = true
	m.Hint.text = tr("Press Up/Down to Change Channels")
	m.Hint.visible = false

	m.videoLoading.text = tr("Loading...")

	' GroupGuia agora usa coords ABSOLUTAS (filhos posicionados direto no XML).
	m.GroupGuia.width = getScreenSize().width
	m.GroupGuia.translation = [0,0]

	' Titulo da coluna de categorias (posicao fixa no XML em [50,118]).
	m.tituloCat.text = tr("Lista D. Canais")
	' Overlay de "Carregando canais..." visivel ao entrar (some quando os canais chegam)
	if m.loadingMsg <> invalid then m.loadingMsg.text = tr("Carregando canais...")
	if m.loadingOverlay <> invalid then m.loadingOverlay.visible = true
	spin = m.top.findNode("loadingSpin")
	if spin <> invalid then spin.control = "start"
	expandMenu()
end sub

' Función para cargar favoritos guardados
sub loadSavedFavorites()
    ' Leer favoritos guardados del registro
    savedFavorites = regRead("live", ReadManifest().title)
    ' (sem debug para publicação)

    if savedFavorites <> invalid and savedFavorites <> ""
        ' Convertir JSON a objeto
        favoritesList = ParseJSON(savedFavorites)
        if favoritesList <> invalid and type(favoritesList) = "roArray"
            m.global.live = favoritesList
            ' (sem debug para publicação)
        else
	                ' (sem debug para publicação)
            m.global.live = []
        end if
    else
        ' (sem debug para publicação)
        m.global.live = []
    end if
end sub
' Función para verificar si un elemento está en la lista de favoritos
function IsMyListItem(listType as String, itemId as String) as Boolean
    if m.global.hasField(listType) = false or m.global[listType] = invalid then
        return false
    end if

    favList = m.global[listType]
    if type(favList) <> "roArray" then return false

    for each item in favList
        if item <> invalid and item.id = itemId then
            return true
        end if
    end for

    return false
end function

' Función para convertir un nodo de contenido a JSON
function ContentNodeToJson(node as Object) as Object
    if node = invalid then return invalid

    json = {}
    ' Propiedades básicas
    json.id = node.id
    json.title = node.title

    ' Propiedades adicionales importantes
    if node.hdposterurl <> invalid then json.hdposterurl = node.hdposterurl
    if node.url <> invalid then json.url = node.url
    if node.streamUrl <> invalid then json.streamUrl = node.streamUrl
    if node.description <> invalid then json.description = node.description

    ' Propiedades específicas para reproducción
    if node.stream <> invalid then json.stream = node.stream
    if node.streamFormat <> invalid then json.streamFormat = node.streamFormat

    return json
end function

sub controlvideoplay()
    vurl = "<sem content>"
    if m.Video.content <> invalid
        if m.Video.content.url <> invalid and m.Video.content.url <> "" then
            vurl = m.Video.content.url
        else if m.Video.content.streamUrls <> invalid and m.Video.content.streamUrls.Count() > 0 then
            vurl = m.Video.content.streamUrls[0]
        end if
    end if
    ? "[SAPLAYER VIDEO] state="; m.Video.state; " errCode="; m.Video.errorCode; " errMsg="; m.Video.errorMsg; " url="; vurl
    if (m.Video.state = "error")
        ' HEVC/H.265 (canais "4K"/FHD) da errCode -5: o Roku NAO decodifica HEVC dentro de
        ' MPEG-TS (so em fMP4). Provado: .ts, .m3u8 e master playlist com CODECS todos deram
        ' -5. Solucao = proxy de remux no servidor (ffmpeg -c copy TS->fMP4 com tag hvc1), que
        ' o Roku abre. No -5 a gente reaponta o canal pro proxy. H.264 toca direto no .ts e
        ' nem chega aqui. So pro painel bnscdn (outros provedores nao sao afetados).
        if m.Video.errorCode = -5 and m.triedHls <> true and m.currentPlayingId <> invalid and m.global.config <> invalid and m.global.config.serverURL <> invalid and Instr(1, m.global.config.serverURL, "bnscdn.top") > 0
            m.triedHls = true
            proxyUrl = "http://2.25.197.72:8090/r/" + tostr(m.currentPlayingId) + "/index.m3u8"
            newC = m.Video.content.Clone(true)
            newC.url = proxyUrl
            newC.streamFormat = "hls"
            m.retryCount = 0
            m.bufferingStuckCount = 0
            m.videoLoading.text = tr("Cargando...")
            m.videoLoading.visible = true
            ? "[SAPLAYER HEVC] reroteando canal "; m.currentPlayingId; " -> proxy remux"
            m.onProxy = true   ' agora tocando pelo proxy -> habilita retry no "finished" (cold start)
            m.proxyTries = 0
            m.Video.content = newC
            m.Video.control = "play"
            m.Video.visible = true
            return
        end if
        if m.retryCount < m.maxRetries
            m.retryCount = m.retryCount + 1
            m.videoLoading.text = tr("Reconectando ") + m.retryCount.toStr() + "/" + m.maxRetries.toStr() + " (cod " + m.Video.errorCode.toStr() + ")"
            m.videoLoading.visible = true

            ' Crear temporizador de reintento con retraso progresivo
            m.reconnectTimer = createObject("roSGNode", "Timer")
            m.reconnectTimer.duration = m.retryDelay * m.retryCount ' Aumenta el tiempo entre intentos
            m.reconnectTimer.control = "start"
            m.reconnectTimer.observeField("fire", "attemptReconnect")
        else
            m.retryCount = 0
            m.Video.control = "stop"
            m.stbSignal.visible = true
            m.rectLoading.visible = true
            m.videoLoading.text = tr("Sinal perdido (erro ") + m.Video.errorCode.toStr() + ")"
            m.videoLoading.visible = true
            m.Video.visible = false
        end if
    else if m.Video.state = "playing"
        m.retryCount = 0  ' Reinicia contador de intentos cuando la reproducción es exitosa
        m.bufferingStuckCount = 0
        m.videoLoading.visible = false
    else if m.Video.state = "buffering"
        m.stbSignal.visible = false
        m.rectLoading.visible = false
        m.videoLoading.text = tr("Cargando...")
        m.videoLoading.visible = true
    else if m.Video.state = "finished"
        ' Proxy (HEVC 4K) "termina" na HORA no cold start (ffmpeg ainda nao gerou o 1o segmento)
        ' -> o Roku desiste. RE-TENTA a MESMA url do proxy a cada 5s (ffmpeg aquece e os segmentos
        ' ficam prontos). Sem isso o canal 4K travava no carregamento e nunca abria.
        if m.onProxy = true and m.proxyTries < 6
            m.proxyTries = m.proxyTries + 1
            m.videoLoading.text = tr("Preparando 4K...") + " " + m.proxyTries.toStr()
            m.videoLoading.visible = true
            m.stbSignal.visible = false
            m.proxyRetryTimer = createObject("roSGNode", "Timer")
            m.proxyRetryTimer.duration = 5
            m.proxyRetryTimer.control = "start"
            m.proxyRetryTimer.observeField("fire", "attemptReconnect")
        else
            m.Video.control = "stop"
            m.Video.visible = false
        end if
    else if m.video.state = "stopped"
        m.rectLoading.visible = false
        m.videoLoading.visible = false
        m.stbSignal.visible = false
    end if
end sub

sub attemptReconnect()
    m.videoLoading.text = tr("Reconectando...")
    m.Video.control = "play"
    m.Video.visible = true
end sub

sub checkPlaybackStatus()
    if m.Video.state = "buffering"
        m.bufferingStuckCount = m.bufferingStuckCount + 1

        ' Si está atascado en buffering demasiado tiempo, intenta recuperar
        if m.bufferingStuckCount > 6 ' 30 segundos
            m.bufferingStuckCount = 0
            m.videoLoading.text = tr("Optimizando conexión...")
            m.Video.control = "stop"
            m.Video.control = "play"
        end if
    else
        m.bufferingStuckCount = 0
    end if
end sub

sub expandMenu()
	m.channelList.SetFocus(false)
    m.categoryList.setFocus(true)
    ' Coluna ATIVA (categorias) acesa, inativa (canais) escurecida -> da pra saber onde esta.
    m.categoryList.opacity = 1.0
    m.channelList.opacity = 0.5
end sub

sub collapseMenu()
    m.categoryList.setFocus(false)
	m.channelList.SetFocus(true)
    ' Coluna ATIVA (canais) acesa, inativa (categorias) escurecida.
    m.categoryList.opacity = 0.5
    m.channelList.opacity = 1.0
end sub

' Indice do canal atualmente focado na lista vertical.
function getFocusedChannelIndex() as Integer
    idx = m.channelList.itemFocused
    if idx = invalid or idx < 0 then idx = 0
    return idx
end function

' Reproduz o canal de um indice da lista.
' previewMode = true -> primeira vez, abre a telinha de previa.
sub playChannelAtIndex(channelIndex as Integer)
    if m.channelList.content = invalid then return
    channel = m.channelList.content.GetChild(channelIndex)
    if channel = invalid then return

    program = invalid
    if channel.GetChildCount() > 0
        program = channel.GetChild(0)
    end if

    m.OnChannelContent = buildPlayableChannel(channel, program)
    m.Video.content = m.OnChannelContent
    m.currentPlayingId = channel.id

    m.retryCount = 0
    m.bufferingStuckCount = 0
    m.triedHls = false   ' canal novo -> permite a tentativa HLS (fallback HEVC) de novo
    m.onProxy = false : m.proxyTries = 0   ' canal novo -> zera estado do retry do proxy
    m.Video.control = "play"
    m.Video.visible = true
    ' Video em tela cheia atras dos paineis (browse) -> esconde decoracoes da previa antiga.
    if m.previewFrame <> invalid then m.previewFrame.visible = false
    if m.aoVivoBadge <> invalid then m.aoVivoBadge.visible = false
    if m.previewLogo <> invalid then m.previewLogo.visible = false
    if m.browseDim <> invalid then m.browseDim.visible = true
    m.top.rowItemSelected = [channelIndex, 0]
end sub

' Clique (OK) num item da lista de canais.
' 1o OK no canal -> previa pequena. 2o OK no MESMO canal -> tela cheia.
sub OnChannelRowSelected(event as Object)
    channelIndex = event.GetData()
    if channelIndex = invalid then return
    if m.channelList.content = invalid then return
    channel = m.channelList.content.GetChild(channelIndex)
    if channel = invalid then return

    ' OK no MESMO canal que ja esta na previa -> abre em TELA CHEIA.
    if m.currentPlayingId <> invalid and m.currentPlayingId = channel.id
        if m.Video.state = "playing" or m.Video.state = "buffering"
            maximizeVideo()
            m.top.rowItemSelected = [channelIndex, 0]
            return
        end if
    end if

    playChannelAtIndex(channelIndex)
end sub

' Foco mudou na lista de canais -> atualiza o painel de info do programa.
sub OnChannelRowFocused(event as Object)
    channelIndex = event.GetData()
    if channelIndex = invalid then return
    UpdateItemDetails(channelIndex)
end sub

Sub onTimeGridViewContentChange()
	m.channelList.visible = true
	' Paineis (lista/categorias) por cima do video tela-cheia + escurecimento pra legibilidade.
	if m.GroupGuia <> invalid then m.GroupGuia.visible = true
	if m.browseDim <> invalid then m.browseDim.visible = true
	' Canais chegaram -> some o overlay de carregando
	if m.loadingOverlay <> invalid then m.loadingOverlay.visible = false
	' Video agora e tela cheia atras dos paineis -> nao usa mais a moldura da previa pequena.
	if m.previewFrame <> invalid then m.previewFrame.visible = false
    if m._isContentFocusResetDone = true then return
    content = m.channelList.content
    if content = invalid then return
    if content.getChildCount() = 0 then return
	m.channelList.jumpToItem = 0
	m._isContentFocusResetDone = true
End Sub

' Atualiza o painel lateral (Group: title/info/description) com o canal focado
' e o programa atual (se houver EPG carregada como filhos do canal).
sub UpdateItemDetails(channelIndex as Integer)
    content = m.channelList.content
    if content = invalid then return
    channel = content.GetChild(channelIndex)
    if channel = invalid then return

    program = currentProgramOf(channel)

    m.title.text = channel.title
    ' (Sem logo de previa: o video toca em tela cheia atras dos paineis.)
    if m.previewLogo <> invalid then m.previewLogo.visible = false
    '** LOGO REMOVIDA: nao seta mais m.poster.uri (poster nao existe no painel de info).
	m.progressBar.width = 0
	m.progressBarBack.visible = false
	m.info.text  = tr("No Data Available")
	m.infoTimer.text = ""
	m.description.text = ""
    if program <> invalid  then
        m.progressBarBack.visible = true
        m.info.text  = program.title
        m.infoTimer.text = secondsToTime(evalInteger(program.playStart),true,true) + " - " + secondsToTime(evalInteger(program.playStop),true,true)
        m.description.text  = program.description
	end if
end sub

' Retorna o programa "no ar agora" do canal, ou o primeiro programa se nao houver
' marcacao de horario; invalid se o canal nao tem EPG.
function currentProgramOf(channel as Object) as Object
    if channel = invalid then return invalid
    if channel.GetChildCount() = 0 then return invalid
    now = CreateObject("roDateTime").AsSeconds()
    for each program in channel.GetChildren(-1, 0)
        if program <> invalid and program.playStart <> invalid and program.playStop <> invalid
            if program.playStart <= now and program.playStop >= now then
                return program
            end if
        end if
    end for
    return channel.GetChild(0)
end function

' Atualiza a barra de info de tela cheia (InfoBar) com o canal focado.
sub viewPrograma()
    content = m.channelList.content
    if content = invalid then return
    channel = content.GetChild(getFocusedChannelIndex())
    if channel = invalid then return
    program = currentProgramOf(channel)
    m.TitleInfo.text = channel.title.ToStr()
    m.posterInfo.uri = channel.hdposterurl
	m.progressBarInfo.width = 0
	m.progressBarBackInfo.visible = false
	m.TitleProgram.text  = tr("No Data Available")
	m.TimerProgram.text = ""
	m.descProgram.text = ""
    if program <> invalid  then
	     m.progressBarBackInfo.visible = true
	    m.TitleProgram.text  = program.title
		m.TimerProgram.text = secondsToTime(program.playStart,true,true)+ " - " +secondsToTime(program.playStop,true,true)
		m.descProgram.text  = program.description
	end if
	m.TimerInfo.text = getCurrentTime(false)
	m.TimerInfo.translation = [getScreenSize().width - 220, 25]
end sub

Sub hideHint()
    m.Hint.visible = false
	m.TimerHint.control = "stop"
End Sub

Sub hideShowBar()
    m.Hint.visible = true
	m.showInfo = true
	m.HideBar.control = "start"
    m.TimerHint.control = "start"
	m.TimerBar.control = "stop"
End Sub

Sub hideBar()
    m.Hint.visible = false
	m.showInfo = false
	m.TimerHint.control = "stop"
	m.TimerBar.control = "start"
End Sub

Sub showBar()
    m.Hint.visible = true
	m.showInfo = true
    m.TimerHint.control = "start"
	m.TimerBar.control = "stop"
End Sub

Sub InfoShow()
    if m.showInfo
	    viewPrograma()
        m.ShowBar.control = "start"
        hideBar()
    else
        m.HideBar.control = "start"
        showBar()
    End if
End Sub

function shouldPlayCatchup(program as Object) as Boolean
    if program = invalid then return false
    if program.playStop = invalid or program.playStart = invalid then return false
    now = CreateObject("roDateTime").AsSeconds()
    return program.playStop < (now - 120)
end function

function buildPlayableChannel(channel as Object, program as Object) as Object
    playable = channel.Clone(true)
    if program <> invalid and shouldPlayCatchup(program)
        catchupUrl = buildCatchupStreamUrl(channel.id, program.playStart, program.playStop)
        if catchupUrl <> ""
            playable.url = catchupUrl
        end if
    end if
    ' Roku da "no valid bitrates" (errCode -5) quando o .m3u8 e uma MEDIA playlist
    ' (sem #EXT-X-STREAM-INF/BANDWIDTH), como nos paineis Xtream. Fix: fornecer
    ' streamUrls + streamBitrates com valor REAL (>0; 0 = "invalido") e LIMPAR url,
    ' senao o Roku prioriza url e ignora os dados manuais.
    ' Live = .ts (MPEG-TS continuo). Sem manipulacao: Roku auto-detecta e toca,
    ' como os apps que funcionam. (HLS/.m3u8 desse painel da -5 no valid bitrates.)
    return playable
end function

' Toca o canal atualmente focado na lista (usado na troca por up/down em tela cheia).
sub playvideo()
    channelIndex = getFocusedChannelIndex()
    if m.channelList.content = invalid then return
    channel = m.channelList.content.GetChild(channelIndex)
    if channel = invalid then return

    program = invalid
    if channel.GetChildCount() > 0
        program = channel.GetChild(0)
    end if
    m.videocontent = buildPlayableChannel(channel, program)
    m.currentPlayingId = channel.id

    m.retryCount = 0
    m.bufferingStuckCount = 0
    m.triedHls = false   ' canal novo -> permite a tentativa HLS (fallback HEVC) de novo
    m.onProxy = false : m.proxyTries = 0   ' canal novo -> zera estado do retry do proxy
    m.Video.content = m.videocontent
    m.Video.control = "play"
    m.Video.visible = true
    ' Troca de canal em TELA CHEIA -> sem decoracoes de previa.
    if m.previewFrame <> invalid then m.previewFrame.visible = false
    if m.aoVivoBadge <> invalid then m.aoVivoBadge.visible = false
    if m.previewLogo <> invalid then m.previewLogo.visible = false
end sub

sub applyCatchupMode()
    m.Hint.text = tr("Select a past program and press OK to watch")
    m.Hint.visible = true
    m.TimerHint.control = "start"
    collapseMenu()
end sub

sub applyMultiMode()
    m.Hint.text = tr("Press Up/Down to Change Channels")
    m.Hint.visible = true
    m.TimerHint.control = "start"
    collapseMenu()
end sub

sub minimizeVideo()
    ' BROWSE: o video continua em TELA CHEIA (atras) e a lista/categorias aparece POR CIMA.
    ' NAO redimensiona o video pra uma janelinha (era o downscale da previa que dava a mancha
    ' em 4K/FHD). Escurece a area da lista (browseDim) pra legibilidade.
    if m.GroupGuia <> invalid then m.GroupGuia.visible = true
    if m.group <> invalid then m.group.visible = true
    if m.browseDim <> invalid then m.browseDim.visible = true
    if m.previewFrame <> invalid then m.previewFrame.visible = false
    if m.aoVivoBadge <> invalid then m.aoVivoBadge.visible = false
    if m.previewLogo <> invalid then m.previewLogo.visible = false
	m.Video.setfocus(false)
    m.channelList.setFocus(true)
    m.videoLoading.font="font:SmallBoldSystemFont"
    m.Hint.visible = false
	m.showInfo = true
	m.InfoBar.visible = false
	m.HideBar.control = "start"
    if m.top.rowItemSelected <> invalid and m.top.rowItemSelected.Count() > 0
        m.channelList.jumpToItem = m.top.rowItemSelected[0]
    end if
end sub

sub maximizeVideo()
    ' TELA CHEIA LIMPA: esconde a lista/categorias/dim. O video JA esta em tela cheia (nao
    ' precisa redimensionar nada).
    if m.previewFrame <> invalid then m.previewFrame.visible = false
    if m.aoVivoBadge <> invalid then m.aoVivoBadge.visible = false
    if m.previewLogo <> invalid then m.previewLogo.visible = false
    if m.GroupGuia <> invalid then m.GroupGuia.visible = false
    if m.group <> invalid then m.group.visible = false
    if m.browseDim <> invalid then m.browseDim.visible = false
    m.InfoBar.visible = false
    m.Hint.visible = false
    m.channelList.setFocus(false)
	m.Video.setfocus(true)
    centerx = (getScreenSize().width - m.videoLoading.BoundingRect().width) / 2
    centery = (getScreenSize().height - m.videoLoading.BoundingRect().height) / 2
    m.videoLoading.translation = [centerx,centery]
    m.videoLoading.font="font:LargeBoldSystemFont"
	m.rectLoading.translation = [centerx,centery]
end sub

' Troca de canal em TELA CHEIA (up/down). Move o foco na lista e toca o novo canal.
function moveRowFocus(stepValue as Integer) as Boolean
    if m.channelList.content = invalid then return false
    total = m.channelList.content.getChildCount()
    if total = 0 then return false
    newIndex = getFocusedChannelIndex() + stepValue
    if newIndex < 0 or newIndex >= total then return false
    m.channelList.jumpToItem = newIndex
    UpdateItemDetails(newIndex)
    m.top.rowItemSelected = [newIndex, 0]
    playvideo()
    return true
end function

sub expandOptions()
    optionsPalette = createObject("roSGNode", "RSGPalette")
    optionsPalette.colors = { "FocusColor": "0x00CCCCFF", "PrimaryTextColor": "0xFFFF00FF", "SecondaryItemColor": "0xFE1E1E1FF", "FocusItemColor": "0xFFFF00FF", "KeyboardColor": "0x00CCCC80", "InputFieldColor":"0x00CCCC80" }
	m.optionDialog.visible = true
    m.optionDialog.title = tr("Channel options")
	m.optionDialog.optionsDialog = true
	content = m.channelList.content.GetChild(getFocusedChannelIndex())
	if content = invalid then return
	if not IsMyListItem("live", content.id)
        m.optionDialog.buttons = [ tr("Add this channel to favorites"), tr("Close") ]
	else
        m.optionDialog.buttons = [ tr("Remove this channel from favorites"), tr("Close") ]
	end if
    m.optionDialog.observeFieldScoped("buttonSelected", "OptionsSelectedButton")
   ' m.optionDialog.palette = optionsPalette
	m.optionDialog.setFocus(true)
end sub

sub OptionsSelectedButton(event as Object)
	selectedButtonText = m.optionDialog.buttons[event.getData()]
    content = m.channelList.content.GetChild(getFocusedChannelIndex())
    if content = invalid then return
    if m.optionDialog.buttonSelected = 0 then
	    if selectedButtonText = tr("Add this channel to favorites")
		    if not IsMyListItem("live", content.id)
		        itemList = []
			    if m.global.live <> invalid and type(m.global.live) = "roArray"
			    	itemList = m.global.live
			    end if

			    ' Convertir el canal a JSON y añadirlo a la lista
			    channelJson = ContentNodeToJson(content)
			    itemList.Push(channelJson)

	    ' Actualizar la lista global
	    	    m.global.live = itemList

	    	    ' Guardar en el registro
        	    regWrite("live", FormatJSON(itemList), ReadManifest().title)
		    end if
	    else if selectedButtonText = tr("Remove this channel from favorites")
		    updatedItemList = []

		    ' Solo incluir canales que no coincidan con el ID actual
		    for each item in m.global.live
                if item.id <> content.id
				    updatedItemList.Push(item)
                end if
		    end for

		    ' Actualizar la lista global
		    m.global.live = updatedItemList

		    ' Guardar en el registro
		    regWrite("live", FormatJSON(updatedItemList), ReadManifest().title)
		end if
    end if
	m.optionDialog.visible = false
    m.optionDialog.setFocus(false)
	m.channelList.setFocus(true)
end sub

sub UnMarkItemList(content as Object)
	if content.mediatype = "movie"
        updatedItemList = []
        for each item in m.global.movie
            if item.id <> content.id
                updatedItemList.Push(item)
            end if
        end for
	    m.global.movie = updatedItemList
	    regWrite("movie", FormatJSON(updatedItemList), ReadManifest().title)
	    'print "Del to List: "; updatedItemList
	elseif content.mediatype = "series"
        updatedItemList = []
        for each item in m.global.series
            if item.id <> content.id
                updatedItemList.Push(item)
            end if
        end for
	    m.global.series = updatedItemList
	    regWrite("series", FormatJSON(updatedItemList), ReadManifest().title)
	    'print "Del to List: "; updatedItemList
	endif
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press then
	    Dbg("Press ", key)
		if key = "OK"
		    if not m.channelList.hasFocus() and m.video.hasFocus() then
				InfoShow()
			end if
            if not handled then handled = true
        else if key = "left" and not m.categoryList.hasFocus() then
		    expandMenu()
			handled = true
        else if key = "right" and not m.channelList.hasFocus() then
		    collapseMenu()
			handled = true
        else if key = "up" and not m.channelList.hasFocus() and not m.categoryList.hasFocus() then
            ' Em tela cheia (video com foco): up troca de canal.
            handled = moveRowFocus(-1)
        else if key = "down" and not m.channelList.hasFocus() and not m.categoryList.hasFocus() then
            handled = moveRowFocus(1)
        else if key = "play"
            if m.video.state <> "stopped" and m.video.state <> "none" and m.Video.state = "playing" and m.channelList.hasFocus() = true then
		       maximizeVideo()
            else
		       minimizeVideo()
            end if
            handled = true
        else if key = "options"
            if m.channelList.hasFocus() = true and m.channelList.content <> invalid and m.channelList.content.GetChild(getFocusedChannelIndex()) <> invalid
			   expandOptions()
            end if
			handled = true
        else if key = "back"
		  if (m.Video.state = "playing" or m.Video.state = "buffering") and m.channelList.hasFocus() = false
            minimizeVideo()
            handled = true
		  else if m.categoryList.hasFocus() and m.channelList.hasFocus() = false
		    collapseMenu()
            handled = true
		  else
		    ' Sai do Canais -> PARA e LIBERA o decoder do preview ao vivo. Sem liberar o
		    ' content, o decoder fica preso e o PROXIMO filme fica so carregando (Roku
		    ' tem 1 decoder so). handled fica false -> o back fecha a tela de Canais.
		    m.Video.control = "stop"
		    m.Video.content = invalid
		  end if
        end if
    end if
    return handled
end function
