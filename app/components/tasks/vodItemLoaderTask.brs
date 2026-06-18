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
    ' request the content feed from the API
    http = NewHttp( m.global.config.serverURL + "/player_api.php?username=" + m.global.user +"&password=" + m.global.pass + "&action=get_vod_info&vod_id="+ m.top.id )
    rsp = http.GetToStringWithRetry()
    json = ParseJson(rsp)
	if json <> invalid and json.Count() > 0
        itemData = GetInfoData(json)
		m.top.content.update(itemData,false)
	end if 
	m.top.contentView = m.top.content
end sub

function GetInfoData(video as Object) as Object
    item = {}
    ' Guarda anti-crash: itens vindos de Favoritos/Continuar Assistindo (ou resposta
    ' sem "info") nao tem video.info -> acessar video.info.X crasha ("trava carregando").
    info = video.info
    ' A API devolve info = [] (array VAZIO) quando nao ha dados -> .plot num array crasha.
    ' So aceita se for objeto (roAssociativeArray); senao usa {}.
    if type(info) <> "roAssociativeArray" then info = {}
	if video.description <> invalid
        item.description = info.description
    else
        item.description = info.plot
    end if
	item.categories = info.genre
	item.actors = info.actors
	item.cast = info.cast
    item.releasedate = info.releasedate
	item.directors = info.director
    item.length = info.duration_secs
    item.duration = info.duration
    item.fhdposterurl = backdrop_path(info.backdrop_path)
    return item
end function
