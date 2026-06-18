'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
sub Init()
    ' set the name of the function in the Task node component to be executed when the state field changes to RUN
    ' in our case this method executed after the following cmd: m.contentTask.control = "run"(see Init method in MainScene)
    m.top.functionName = "GetContent"
end sub
 








 sub GetContent()
    date = CreateObject("roDatetime")

    ' LIMITE CRITICO: este task faz 1 requisicao HTTP POR CANAL. Em "Tudo" (1175 canais)
    ' isso eram 1175 requisicoes que saturavam a conexao por minutos -> o filme/stream
    ' nao conseguia bufferizar (ficava "so carregando"). Limita aos primeiros N (visiveis).
    maxEpg = 40
    epgCount = 0
    for each content in m.top.content.GetChildren(-1, 0)
        if epgCount >= maxEpg then exit for
        epgCount = epgCount + 1
        ' Crear solicitud HTTP

               http = NewHttp( m.global.config.serverURL + "/player_api.php")
        http.contentHeader = "application/x-www-form-urlencoded"
        http.AddParam("username", m.global.user.Escape())
        http.AddParam("password", m.global.pass.Escape())
        http.AddParam("action", "get_short_epg".Escape())
        http.AddParam("limit", "7".Escape())
        http.AddParam("stream_id", content.id.Escape())

        ' Enviar solicitud
        request = http.Request()

        ' Parsear JSON
        json = ParseJson(request)

        ' Validar que json es un objeto con epg_listings
        if Type(json) = "roAssociativeArray" and json.epg_listings <> invalid and json.epg_listings.Count() > 0
            for each channel in json.epg_listings
                program = content.createChild("ContentNode")

                ' Decodificar campos base64
                title = decodeBase64(channel.title)
                description = decodeBase64(channel.description)

                ' Calcular duración del programa
                startTime = evalInteger(channel.start_timestamp)
                endTime = evalInteger(channel.stop_timestamp)
                duration = Int(endTime - startTime)

                ' Asignar campos al nodo
                program.title = title
                program.description = description
                ' playStart/playStop/playDuration via addFields: o campo padrao 'playStart' do
                ' ContentNode e FLOAT -> timestamp de 10 digitos (ex 1781226000) perdia precisao
                ' em float32 e o currentProgramOf errava o programa "no ar" (mostrava sem dados).
                program.addFields({ "playStart": startTime, "playStop": endTime, "playDuration": duration })
            end for
        else
            ' (sem debug para publicação)
        end if
    end for
end sub
