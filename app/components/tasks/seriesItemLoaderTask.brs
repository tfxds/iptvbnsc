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
    http = NewHttp( m.global.config.serverURL + "/player_api.php?username=" + m.global.user +"&password=" + m.global.pass + "&action=get_series_info&series_id=" + m.top.id )
    rsp = http.GetToStringWithRetry()
    json = ParseJson(rsp)
	content = m.top.content
	if json <> invalid and json.Count() > 0
        itemData = GetInfoSerie(json)
		seasons = GetSeasonData(json, itemData.hdPosterURL)
        if seasons <> invalid and seasons.Count() > 0
		    if content.GetChildCount() = 0
				itemData.children = seasons
			end if
        end if
		m.top.content.update(itemData,false)
	end if 
	m.top.contentView = content
end sub

function GetInfoSerie(series as Object) as Object
    item = {}
    item.mediaType = "series"
    item.contentType = "series"
    ' Guarda anti-crash: serie vinda de Favoritos/Continuar (ou resposta sem "info")
    ' nao tem series.info -> acessar series.info.X crasha (trava no carregamento).
    info = series.info
    if type(info) <> "roAssociativeArray" then info = {}
    item.description = info.plot
    item.hdPosterURL = info.cover
    item.fhdposterurl = backdrop_path(info.backdrop_path)
	item.categories = info.genre
    item.actors = ""
	item.cast = info.cast
    item.releasedate = info.releasedate
	item.directors = info.director
    item.length = 0
    return item
end function

function GetSeasonData(json as Object, seriesPoster = "" as Object) as Object
    seasonsArray = []
    if json <> invalid
	    episodeCounter = 0
		for i = 0 to json.episodes.Count() - 1
            num = AnyToString(i+1)
			episodes = []
            if json.episodes.DoesExist(num)
                for each episode in json.episodes[num]
                    episodeData = GetInfoEpisode(episode)
                    ' save season title for element to represent it on the episodes screen
                    episodeData.titleSeason = tr("Season") + " " + num
					episodeData.season = num
					episodeData.season_number = num
					episodeData.season_num  = num
					episodeData.episodePosition = num
					episodeData.numEpisodes = episodeCounter
                    episodeData.mediaType = "episode"
					episodeData.contentType = "episode"
					' Capa da SERIE (nao do episodio) -> "assistidos" mostra a serie certa.
					episodeData.seriesPoster = seriesPoster
                    episodes.Push(episodeData)
					episodeCounter ++
                end for
            end if
			seasonData = {}
			seasonData.id = evalInteger(num)
			seasonData.title = tr("Season") + " " + num
			if type(json.info) = "roAssociativeArray" then seasonData.releasedate = json.info.releasedate
			seasonData.episodePosition = num
			seasonData.episode_count = json.episodes[num].Count()
			seasonData.season_number = num
            seasonData.children = episodes
			seasonData.mediaType = "section"
            seasonData.contentType = "section"
            seasonsArray.Push(seasonData)
        end for
    end if
    return seasonsArray
end function

function GetInfoSeason(season as Object) as Object
	item = {}
    item.id = evalInteger(season.id)
    item.title = season.name
	item.releasedate = season.air_date
	item.episodePosition = season.season_number
	item.episode_count = season.episode_count
	item.season_number = season.season_number
    return item
end function

function GetInfoEpisode(episode as Object) as Object
	item = {}
    item.id = evalInteger(episode.id)
    item.title = episode.title
    item.url = m.global.config.serverURL + m.global.play + episode.id.ToStr() + "." + episode.container_extension
    'item.streamFormat = episode.container_extension
    einfo = episode.info
    if type(einfo) <> "roAssociativeArray" then einfo = {}
	if einfo.description <> invalid
        item.description = einfo.description
    else
        item.description = einfo.plot
    end if
    item.releaseDate = einfo.releasedate
    item.length = einfo.duration_secs
    item.rating = AnyToString(einfo.rating)
    item.hdPosterURL = einfo.movie_image
    return item
end function
