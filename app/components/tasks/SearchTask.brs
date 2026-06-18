'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub Init()
    m.top.functionName = "GetContent"
end sub

sub GetContent()
    contentNode = CreateObject("roSGNode", "ContentNode")
    rootChildren = []

    query = m.top.searchTerm
    if query = invalid then query = ""

    ' BUSCA UNIFICADA: roda os 3 tipos (1=canal, 2=filme, 3=serie) e junta TUDO numa
    ' fileira so (pedido Andrade: sem escolher canal/filme/serie, busca tudo de uma vez).
    ' Cada item carrega o SEU proprio tipo (mediaType/url) -> o playback ja despacha certo
    ' por item (live toca direto; filme/serie vao pro Details). Por isso NAO usamos mais
    ' m.global.contentType aqui (que era unico) -> o tipo vem do request de cada tipoid.
    kinds = [{ tipoid: "1", kind: "live" }, { tipoid: "2", kind: "movie" }, { tipoid: "3", kind: "series" }]
    row = { title: tr("Resultados"), children: [] }

    for each k in kinds
        url = "https://roku.zedplayer.pp.ua/buscador.php?username=" + m.global.user + "&password=" + m.global.pass + "&search=" + query + "&tipoid=" + k.tipoid + "&baseurl=" + m.global.config.serverURL
        http = NewHttp(url)
        rsp = http.GetToStringWithRetry()
        parsed = ParseJson(rsp)
        if parsed <> invalid and type(parsed) = "roArray" and parsed.Count() > 0
            for each item in parsed
                itemData = GetItemData(item, k.kind)
                if itemData <> invalid and LCase(itemData.title).Instr(LCase(query)) > -1
                    row.children.Push(itemData)
                end if
            end for
        end if
    end for

    if row.children.Count() > 0 then rootChildren.Push(row)

    contentNode.Update({children: rootChildren}, true)
    m.top.content = contentNode
end sub


' kind = "live" | "movie" | "series" -> define id/capa/url do item. Cada tipo monta a
' propria URL (/live//movie//series/) pra tocar certo na fileira misturada.
function GetItemData(video as Object, kind as String) as Object
    item = {}
    item.title = video.name
    item.contentType = kind
    item.mediaType = kind
    item.rating = AnyToString(video.rating)
    item.description = ""
    item.categories = ""
    item.actors = ""
    item.cast = ""
    item.releasedate = ""
    item.directors = ""
    item.length = ""
    item.duration = ""

    if kind = "live"
        item.id = video.stream_id
        item.hdPosterURL = video.stream_icon
        m3u8 = ".m3u8"
        if m.global.streamFormat <> "hls" then m3u8 = ".ts"
        item.url = m.global.config.serverURL + "/live/" + m.global.user + "/" + m.global.pass + "/" + tostr(video.stream_id) + m3u8
        item.live = true
        item.fhdposterurl = ""
    else if kind = "movie"
        item.id = video.stream_id
        item.hdPosterURL = video.stream_icon
        ext = ""
        if video.container_extension <> invalid and video.container_extension <> ""
            ext = "." + video.container_extension
        end if
        item.url = m.global.config.serverURL + "/movie/" + m.global.user + "/" + m.global.pass + "/" + tostr(video.stream_id) + ext
        item.fhdposterurl = ""
    else if kind = "series"
        item.id = video.series_id
        item.hdPosterURL = video.cover
        item.fhdposterurl = backdrop_path(video.backdrop_path)
        item.children = []
    end if

    return item
end function
