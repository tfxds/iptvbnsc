' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

sub Init()
    m.top.functionName = "GetContent"
end sub

sub GetContent()
    rootChildren = []

    if m.global.menuNavMode = "recordings"
        rootChildren = loadRecordingsChildren()
    else
        json = []
        json.Append(m.global.movie)
        json.Append(m.global.series)
        if json <> invalid and json.Count() > 0
            for each item in json
                itemData = GetItemData(item)
                rootChildren.Push(itemData)
            end for
        end if
    end if

    contentNode = CreateObject("roSGNode", "ContentNode")
    contentNode.Update({children: rootChildren}, true)
    m.top.content = contentNode
end sub

function loadRecordingsChildren() as Object
    children = []
    list = loadContinueWatchingList()
    if list = invalid or list.Count() = 0 then return children

    for each item in list
        if item = invalid then continue for
        posVal = 0
        if item.pos <> invalid then posVal = item.pos
        ' SERIE aparece na lista mesmo no comecinho do episodio (acabou de trocar de EP);
        ' FILME so entra com >= 60s assistidos (evita encher de coisa mal-comecada).
        isSeriesEntry = (item.seriesKey <> invalid and item.seriesKey <> "")
        if (not isSeriesEntry) and posVal < 60 then continue for

        entry = {}
        entry.id = item.id
        entry.title = item.title
        if entry.title = invalid or entry.title = "" then entry.title = "ID " + item.id
        entry.contentType = 1
        entry.hdPosterURL = item.hdPosterURL
        entry.fhdposterurl = item.hdPosterURL
        if item.url <> invalid and item.url <> "" then entry.url = item.url
        if item.length <> invalid then entry.length = item.length
        entry.resumePos = posVal
        ' SERIE (Continuar Assistindo): guarda o id da SERIE + id do episodio salvo, pra
        ' reconstruir o PLAYLIST completo no play -> botoes proximo/anterior + autoplay
        ' funcionam (antes tocava so o episodio solto pela url, sem navegacao). O FILME
        ' continua reproduzindo DIRETO pela url salva, com resume (mediaType=movie).
        if item.seriesKey <> invalid and item.seriesKey <> ""
            entry.mediaType = "series"
            entry.seriesId = AnyToString(item.seriesKey)
            entry.episodeId = AnyToString(item.id)
            if item.title <> invalid then entry.seriesTitle = item.title
        else
            entry.mediaType = "movie"
        end if
        children.Push(entry)
    end for

    return children
end function

function GetItemData(video as Object) as Object
    item = {}
    item.id = video.id
    item.title = video.title
    item.contentType = video.contentType
    item.mediaType = video.mediaType
    item.rating = video.rating
    item.hdPosterURL = video.hdPosterURL
    item.fhdposterurl = video.fhdposterurl

    ' Copia a url SEMPRE que existir (robusto): o contentType do favorito pode vir
    ' como "movie"/string e nao 1 (inteiro) -> sem url o player dava "erro de reproducao".
    if video.url <> invalid and video.url <> ""
        item.url = video.url
    else
        item.children = []
    end if

    return item
end function
