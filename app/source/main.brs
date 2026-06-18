'****CONTENT MASTERS****
sub Main(args as dynamic)
    ? "===== SAPLAYER BUILD v94 :: pacote <4MB (fontes subset + imagens comprimidas + remove assets nao usados) p/ cert Roku ====="
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)
    if args.DoesExist("mediaType") and args.DoesExist("contentID")	then
		scene = screen.CreateScene("DeepLinkScene")
		scene.launchArgs = args
	else
        scene = screen.CreateScene("MainScene")
    end if
    m.global = screen.getGlobalNode()
    initGlobals()
    screen.Show()
	scene.observeField("close", m.port)
    scene.signalBeacon("AppDialogInitiate")
    scene.signalBeacon("AppDialogComplete")
    scene.signalBeacon("AppLaunchComplete")

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
		Dbg("msg.getNode(): ", msg.getNode())
		Dbg("msg.getField(): ", msg.getField())
        if msgType = "roSGNodeEvent"
		    node = msg.getField()
			Dbg("roSGNodeEvent ", node)
            if node = "close" and msg.getData()
                return
            end if
        else if msgType = "roDeviceInfoEvent"
            info = msg.GetInfo()
			Dbg("roDeviceInfoEvent ", info)
        else if msgType = "roInputEvent"
            if msg.IsInput()
                info = msg.GetInfo()
            end if
        else if msgType = "roVideoPlayerEvent" 
		    Dbg("Audio tracks available.", msg.GetInfo())
            'tracks = player.getAudioTracks()
            'print tracks.count(); " audio tracks available."
        end if
    end while
end sub


function initGlobals()

    configData = cargarConfigRemota()
    if configData = invalid or configData.Count() = 0
        ? "Error: No se pudo cargar config remota"
    end if

    ' ✅ Declarar como array
    m.global.AddField("config_activa", "array", true)
    m.global.setField("config_activa", configData)

    ' Tomamos el primero como activo. Com MAC nao cadastrado, configData vem
    ' vazio (sem auto-login) -> usa um config default p/ nao quebrar o boot.
    configActiva = configData[0]
    if configActiva = invalid or type(configActiva) <> "roAssociativeArray"
        configActiva = { serverURL: "", appName: "S.A Player", version: "4.5", api_key: "46270abd00c39663cde5d450ff83cbb8" }
    end if
    m.global.AddField("config", "assocarray", true)
    m.global.config = configActiva
    ' config_activa CONTINUA sendo o array (setado acima) p/ o ConfirmUserTask iterar com seguranca

    ' Los demás campos
    m.global.AddField("theme", "assocarray", true)
    m.global.setField("theme", theme())
    m.global.AddField("GetModel", "string", true)
    m.global.setField("getModel", GetModel())
    m.global.AddField("rokuUniqueID", "string", true)
    m.global.setField("rokuUniqueID", getDeviceESN())
    m.global.AddField("deviceMac", "string", true)
    m.global.setField("deviceMac", panelDeviceMac(getDeviceESN()))
    m.global.AddField("user", "string", true)
    m.global.AddField("pass", "string", true)
    m.global.AddField("expire", "string", true)
    m.global.AddField("email", "string", true)
    m.global.AddField("max_connections", "string", true)
    m.global.AddField("active_cons", "string", true)
    m.global.AddField("contentType", "string", true)
    m.global.AddField("action", "string", true)
    m.global.AddField("items", "string", true)
    ' Cache da lista CRUA de canais (get_live_streams) -> baixa 1x, reusa em todas as
    ' categorias e na contagem (elimina download duplo) e preload na inicializacao.
    m.global.AddField("liveStreamsRaw", "string", true)
    ' Capa da serie aberta agora -> "assistidos" salva a capa da SERIE (nao do episodio).
    m.global.AddField("currentSeriesPoster", "string", true)
    ' Id + titulo da serie aberta agora -> "assistidos" DEDUPLICA por serie (todos os
    ' episodios viram UMA entrada, com o nome da serie) em vez de 1 card por episodio.
    m.global.AddField("currentSeriesId", "string", true)
    m.global.AddField("currentSeriesTitle", "string", true)
    m.global.AddField("play", "string", true)
    m.global.AddField("isAdult", "bool", true)
    m.global.AddField("backdrop", "string", true)
    m.global.AddField("isExitApp", "bool", true)
    m.global.AddField("showMenu", "bool", true)
    m.global.AddField("contentTask", "node", true)
    m.global.AddField("titleSection", "string", true)
    m.global.AddField("channelCategory", "array", true)
    m.global.AddField("live", "array", true)
    m.global.AddField("moviesCategory", "array", true)
    m.global.AddField("movie", "array", true)
    m.global.AddField("seriesCategory", "array", true)
    m.global.AddField("series", "array", true)
    m.global.AddField("sort", "string", true)
    m.global.AddField("streamFormat", "string", true)
    m.global.AddField("timeServer", "integer", true)
    m.global.AddField("cacheSearch", "array", true)
    m.global.AddField("searchPreset", "string", true)
    m.global.searchPreset = ""
    m.global.AddField("menuNavMode", "string", true)
    m.global.menuNavMode = ""
    m.global.AddField("tileLive", "string", true)
    m.global.AddField("tileMovies", "string", true)
    m.global.AddField("tileSeries", "string", true)
    m.global.tileLive = ""
    m.global.tileMovies = ""
    m.global.tileSeries = ""

    ' Cargar preferencias y datos usando config activa
    m.global.channelCategory = LoadArraySection("channelCategory", configActiva.appName)
    m.global.moviesCategory = LoadArraySection("moviesCategory", configActiva.appName)
    m.global.seriesCategory = LoadArraySection("seriesCategory", configActiva.appName)
    m.global.live = LoadArrayMyList("live", configActiva.appName)
    m.global.movie = LoadArrayMyList("movie", ReadManifest().title)
    m.global.series = LoadArrayMyList("series", ReadManifest().title)
    
    ' MODIFICADO: Establecer ordenamiento por defecto como "más recientes"
    sortValue = regread("sort", configActiva.appName)
    if sortValue = "" or sortValue = invalid
        m.global.sort = "id"  ' Por defecto: más recientes
        regWrite("sort", "id", configActiva.appName)  ' Guardar la preferencia
    else
        m.global.sort = sortValue
    end if
    
    m.global.streamFormat = regread("streamFormat", configActiva.appName)

    ensureGlobalAssetFields()
    applyGlobalAssetDefaults()

end function