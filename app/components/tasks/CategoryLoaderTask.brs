'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub Init()
    m.top.functionName = "GetContent"
    if m.global.contentType = "live"
        m.category = m.global.channelCategory
    else if m.global.contentType = "movie"
        m.category = m.global.moviesCategory
    else if m.global.contentType = "series"
        m.category =  m.global.seriesCategory
    end if
end sub

sub GetContent()
    content = createObject("roSGNode", "ContentNode")
    ' request the content feed from the API
    http = NewHttp( m.global.config.serverURL + "/player_api.php?username=" + m.global.user +"&password=" + m.global.pass + "&action=" + m.global.action)
    rsp = http.GetToStringWithRetry()
    json = ParseJson(rsp)

    ' --- LIVE: contagem por categoria ---------------------------------------
    ' A API get_live_categories NAO traz contagem. Fazemos UMA chamada extra a
    ' get_live_streams (sem category_id = todos os canais) e contamos quantos
    ' por category_id. Tambem montamos o total para a categoria "Tudo".
    countsByCat = {}
    totalChannels = 0
    if m.global.contentType = "live"
        ' Reusa o cache CRU (mesma lista que a aba de canais usa) -> evita baixar
        ' get_live_streams 2x ao abrir Canais. Se ainda nao tem cache, baixa e guarda.
        rspStreams = ""
        if m.global.liveStreamsRaw <> invalid and m.global.liveStreamsRaw <> ""
            rspStreams = m.global.liveStreamsRaw
        else
            streamsUrl = m.global.config.serverURL + "/player_api.php?username=" + m.global.user + "&password=" + m.global.pass + "&action=get_live_streams"
            httpStreams = NewHttp(streamsUrl)
            rspStreams = httpStreams.GetToStringWithRetry()
            m.global.liveStreamsRaw = rspStreams
        end if
        streamsJson = ParseJson(rspStreams)
        if streamsJson <> invalid and type(streamsJson) = "roArray"
            for each ch in streamsJson
                if ch <> invalid and ch.category_id <> invalid
                    cid = ch.category_id.ToStr()
                    if countsByCat[cid] = invalid
                        countsByCat[cid] = 1
                    else
                        countsByCat[cid] = countsByCat[cid] + 1
                    end if
                    totalChannels = totalChannels + 1
                end if
            end for
        end if
    end if

	if json <> invalid and json.Count() > 0
	    result = []
		if m.global.contentType = "live"
		    ' "Tudo" (id vazio) no topo com a contagem TOTAL, depois "Favoritos" (id 0).
		    result = [{"category_id": "", "category_name": tr("Tudo")}, {"category_id": "0","category_name": "My Favorites","parent_id": 0}]
		else
		    ' Filmes/Series: pasta "Todos" (id vazio = todos) no topo, igual aos Canais.
		    result = [{"category_id": "", "category_name": tr("Todos")}]
		end if
		result.Append(json)
        for i = 0 to result.count()-1
		    look_enabled = false
			if m.category <> invalid
                for each look in m.category
                    if look = "all"
					    look_enabled = true
                    else if result[i].category_id = look
                        look_enabled = true
                    end if
                end for
			end if
			' AUTO: categoria adulta pelo NOME (ADULTOS/+18/XXX/PORNO...) sempre pede PIN,
			' mesmo sem o usuario ter marcado manualmente. Corrige adulto abrindo sem PIN.
			if checkIsAdults(result[i].category_name) then look_enabled = true
		    itemcontent = content.createChild("ContentNode")
		    itemcontent.id = result[i].category_id
		    itemcontent.hdgridposterurl = "pkg:/images/icons/movie.png"

		    baseTitle = clean(tr(result[i].category_name))

		    if m.global.contentType = "live"
		        ' Determina a contagem que aparece a direita do nome.
		        catId = result[i].category_id.ToStr()
		        countVal = 0
		        if catId = ""
		            countVal = totalChannels
		        else if catId = "0"
		            ' Favoritos: usa a lista global de favoritos (live), ou 0.
		            if m.global.live <> invalid and type(m.global.live) = "roArray"
		                countVal = m.global.live.Count()
		            end if
		        else
		            if countsByCat[catId] <> invalid then countVal = countsByCat[catId]
		        end if
		        ' Nome e contador SEPARADOS (contador num label proprio a direita -> nao
		        ' some quando o nome eh longo, como acontecia com o texto padronizado).
		        nm = baseTitle
		        if Len(nm) > 22 then nm = Left(nm, 21) + "."
		        itemcontent.title = nm
		        itemcontent.addFields({ catcount: countVal.ToStr() })
		    else
		        itemcontent.title = baseTitle
		    end if

		    itemcontent.addField("duration", "float", false)
		    itemcontent.setField("duration", "0.0"+ stri(i+1))
		    itemcontent.addFields({look: look_enabled})
        end for
	end if
    m.top.content = content
end sub

' Formata o titulo da categoria como `nome` + espacos + `contagem`, aproximando
' o alinhamento a direita dentro da largura da LabelList (texto, fonte proporcional).
function formatCatTitle(name as String, count as Integer) as String
    countStr = count.ToStr()
    ' Largura util ~ 26 caracteres na coluna de categorias. Trunca nome longo.
    maxName = 18
    nm = name
    if Len(nm) > maxName then nm = Left(nm, maxName - 1) + "."
    targetLen = 26
    pad = targetLen - Len(nm) - Len(countStr)
    if pad < 2 then pad = 2
    spaces = ""
    for i = 1 to pad
        spaces = spaces + " "
    end for
    return nm + spaces + countStr
end function
