sub Init()
    m.top.functionName = "GetContent"
end sub

' Live = MPEG-TS continuo (.ts). O painel serve .m3u8 como MEDIA playlist (sem
' BANDWIDTH) -> Roku da "-5 no valid bitrates". O .ts e o que os apps que funcionam
' (Vizzion/Magic/Assist/Playsim/Blessed) usam: Roku auto-detecta o TS e toca.
function getStreamExtension() as String
    return ".ts"
end function

' Sem streamFormat -> Roku auto-detecta o container do .ts. Forcar "hls" quebrava.
function getLiveStreamFormat() as String
    return ""
end function

sub GetContent()
    if m.top.id <> "0"
    	' CACHE CRU: baixa get_live_streams (TODOS) UMA vez e guarda em m.global.liveStreamsRaw.
    	' Categorias especificas FILTRAM esse cache no app (instantaneo, sem nova chamada).
    	rsp = ""
    	if m.global.liveStreamsRaw <> invalid and m.global.liveStreamsRaw <> ""
    	    rsp = m.global.liveStreamsRaw
    	else
    	    ' COLD-START: disco primeiro (sem rede); so baixa se nao tem cache fresco.
    	    rsp = readDiskCache("saplayer_live", 24)
    	    if rsp <> ""
    	        m.global.liveStreamsRaw = rsp
    	    else
    	        baseUrl = m.global.config.serverURL + "/player_api.php?username=" + m.global.user +"&password=" + m.global.pass + "&action=get_live_streams"
    	        http = NewHttp( baseUrl )
    	        rsp = http.GetToStringWithRetry()
    	        m.global.liveStreamsRaw = rsp
    	        ' persiste no disco p/ a proxima abertura do app nao baixar de novo.
    	        if rsp <> invalid and rsp <> "" then writeDiskCache("saplayer_live", rsp)
    	    end if
    	end if
    	' Preload leve: ja cacheou o cru -> NAO constroi os 1175 nos (economiza memoria/CPU,
    	' evita competir com o stream do filme). A lista real e montada ao abrir Canais.
    	if m.top.rawOnly = true
    	    m.top.content = createObject("RoSGNode","ContentNode")
    	    return
    	end if
    	json = ParseJson(rsp)
    	' Filtra pela categoria pedida (id <> "" = categoria especifica; "" = Tudo).
    	if m.top.id <> "" and json <> invalid and type(json) = "roArray"
    	    filtered = CreateObject("roArray", 0, true)
    	    for each ch in json
    	        if ch <> invalid and ch.category_id <> invalid and ch.category_id.ToStr() = m.top.id then filtered.Push(ch)
    	    end for
    	    json = filtered
    	end if
		m.content = createObject("RoSGNode","ContentNode")
		if json <> invalid and json.Count() > 0 then
			' Canais: ORDEM DO SERVIDOR/LISTA (o provedor curou a ordem dos canais -> pedido
			' do Andrade). NAO reordena por id/nome por padrao, que embaralhava a grade.
			' So aplica A-Z se o usuario escolher EXPLICITAMENTE "nome" nas Configuracoes.
			if m.global.sort = "name" then json.SortBy("name")
        	for each channel in json
				m.channel = m.content.createChild("ContentNode")
				m.channel.id = channel.stream_id
        		m.channel.title = channel.name.ToStr()
				if isnonemptystr(channel.stream_icon) and channel.stream_icon <> invalid  then
        		   m.channel.hdposterurl = channel.stream_icon
				else 
        		   m.channel.hdposterurl = "pkg:/images/channel.png"
        		end if		
				
				' Usar función auxiliar para determinar la extensión
				streamExtension = getStreamExtension()
				
        		m.channel.url = m.global.config.serverURL + m.global.play + tostr(channel.stream_id) + streamExtension
        		m.channel.live = true
        		m.channel.streamFormat = getLiveStreamFormat()
        		if m.printedLiveUrl <> true then m.printedLiveUrl = true : ? "[SAPLAYER LIVE] url="; m.channel.url; " fmt="; m.channel.streamFormat
        		'm.channel.streamFormat = "hls"
				m.channel.addFields({"nowTime": getCurrentTime()})
				'if channel.program <> invalid
        		'    for each program in channel.program 
				'        addProgram(program)
        		'    end for
				'end if
       	 	end for
    	end if
		m.top.content = m.content
	else
    	json = m.global.live
		m.content = createObject("RoSGNode","ContentNode")
		if json <> invalid and json.Count() > 0 then
			if m.global.sort <> "auto"
        		if m.global.sort = "id"
            		json.SortBy("id", "r")
        		else
					json.SortBy("title")
				end if
        	end if
        	for each channel in json
				m.channel = m.content.createChild("ContentNode")
				m.channel.id = channel.id
        		m.channel.title = channel.title.ToStr()
				if isnonemptystr(channel.hdposterurl) and channel.hdposterurl <> invalid  then
        		   m.channel.hdposterurl = channel.hdposterurl
				else 
        		   m.channel.hdposterurl = "pkg:/images/channel.png"
        		end if		
				
				' Usar función auxiliar para determinar la extensión
				streamExtension = getStreamExtension()
				
        		m.channel.url = m.global.config.serverURL + m.global.play + tostr(channel.id) + streamExtension
        		m.channel.live = true
        		m.channel.streamFormat = getLiveStreamFormat()
				m.channel.addFields({"nowTime": getCurrentTime()})
       	 	end for
        else		
			m.channel = m.content.createChild("ContentNode")
			m.channel.id = "0"
        	m.channel.title = tr("Empty")
            m.channel.hdposterurl = "pkg:/images/channel.png"
			
			' Usar función auxiliar para determinar la extensión
			streamExtension = getStreamExtension()
			
        	m.channel.url = m.global.config.serverURL + m.global.play + tostr("0") + streamExtension
        	m.channel.live = true
			m.channel.addFields({"nowTime": getCurrentTime()})
    	end if
		m.top.content = m.content
	end if
end sub

sub addProgram(program as Object) as Object
     item = m.channel.createChild("ContentNode")
     item.title = program.program_title
     item.playDuration = program.duration
     item.playStart = program.start_timestamp
	 item.description = program.description
end sub