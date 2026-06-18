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
    ' action/contentType vem dos CAMPOS do task se setados (preload isolado, sem mexer
    ' nos globals compartilhados); senao cai pro global (fluxo normal).
    act = m.global.items
    if m.top.action <> invalid and m.top.action <> "" then act = m.top.action
    m.ctype = m.global.contentType
    if m.top.ctype <> invalid and m.top.ctype <> "" then m.ctype = m.top.ctype

    ' request the content feed from the API
    ' "Todos" (category_id vazio): OMITE o parametro (=> painel retorna TODOS). Mandar
    ' "&category_id=" vazio fazia o painel retornar 0 titulos.
    baseUrl = m.global.config.serverURL + "/player_api.php?username=" + m.global.user + "&password=" + m.global.pass + "&action=" + act
    if m.top.category_id <> invalid and m.top.category_id <> "" then baseUrl = baseUrl + "&category_id=" + m.top.category_id

    ' COLD-START: se houver cacheKey (preload do "Todos"), tenta o DISCO primeiro (sem
    ' rede). So baixa se nao tem cache fresco. Apos baixar, grava no disco p/ proxima vez.
    rsp = ""
    fromDisk = false
    if m.top.cacheKey <> invalid and m.top.cacheKey <> ""
        rsp = readDiskCache(m.top.cacheKey, 24)
        if rsp <> "" then fromDisk = true
    end if
    if not fromDisk
        http = NewHttp( baseUrl )
        rsp = http.GetToStringWithRetry()
    end if
	rootChildren = []

    json = ParseJson(rsp)
    ' Cache de disco corrompido/vazio -> cai pra rede (nao mostra lista vazia).
    if fromDisk and (json = invalid or json.Count() = 0)
        http = NewHttp( baseUrl )
        rsp = http.GetToStringWithRetry()
        fromDisk = false
        json = ParseJson(rsp)
    end if
    if not fromDisk and m.top.cacheKey <> invalid and m.top.cacheKey <> "" and json <> invalid and json.Count() > 0
        writeDiskCache(m.top.cacheKey, rsp)
    end if
	if json <> invalid and json.Count() > 0 then
        ' Ordenacao: "auto" = mantem a ORDEM DO SERVIDOR (nao reordena, pedido do cliente).
        ' So reordena se o usuario escolher nome/id nas Configuracoes.
        if m.global.sort <> invalid and m.global.sort <> "auto" then
            if json[0].stream_id <> invalid then
                ' FILME: stream_id ja vem como numero -> SortBy direto funciona. NAO mexer
                ' (aplicar o loop _sortid aqui quebrava o carregamento dos filmes / pre-load).
                if m.global.sort = "id" then
                    json.SortBy("stream_id", "r")
                else
                    json.SortBy("name")
                end if
            else
                ' SERIE: series_id as vezes vem como STRING -> SortBy lexical poe "99" antes de
                ' "100" (perdia "recentes primeiro"). Chave numerica propria resolve.
                if m.global.sort = "id" then
                    for each it in json
                        if type(it) = "roAssociativeArray" then it._sortid = Int(Val(AnyToString(it.series_id)))
                    end for
                    json.SortBy("_sortid", "r")
                else
                    json.SortBy("name")
                end if
            end if
        end if

        row = {}
        row.title = m.top.category_title
        row.children = []
        for each item in json ' parse items and push them to row
            itemData = GetItemData(item)
            rootChildren.Push(itemData)
        end for
	end if  
    ' set up a root ContentNode to represent rowList on the GridScreen
    contentNode = CreateObject("roSGNode", "ContentNode")
    contentNode.Update({children: rootChildren}, true)
	m.top.content = contentNode
end sub

function GetItemData(video as Object) as Object
    item = {}
	item.title = video.name
	item.contentType = m.ctype
	item.mediaType = m.ctype
	' Guarda a categoria do item pra permitir FILTRO no app (troca de pasta instantanea
	' a partir do cache "Todos", sem nova chamada de rede).
	item.categoryId = AnyToString(video.category_id)
    item.rating = AnyToString(video.rating)
    item.description = ""
	item.categories = ""
	item.actors = ""
	item.cast = ""
    item.releasedate = ""
	item.directors = ""
    item.length = ""
    item.duration = ""
	
	if m.ctype = "movie" then
		item.id = video.stream_id
		item.hdPosterURL = video.stream_icon
        ' Verificar si container_extension existe antes de usarlo
        if video.container_extension <> invalid then
            item.url = m.global.config.serverURL + m.global.play + tostr(video.stream_id) + "." + video.container_extension
        else
            ' Usar formato por defecto basado en streamFormat
            extension = ".m3u8"
            if m.global.streamFormat <> invalid and m.global.streamFormat <> "hls" then extension = ".ts"
            item.url = m.global.config.serverURL + m.global.play + tostr(video.stream_id) + extension
        end if
        'item.streamFormat = video.container_extension
		item.fhdposterurl = ""
	else
		item.id = video.series_id
		item.hdPosterURL = video.cover
		item.fhdposterurl = backdrop_path(video.backdrop_path)
		item.children = []
	end if
	
    return item
end function