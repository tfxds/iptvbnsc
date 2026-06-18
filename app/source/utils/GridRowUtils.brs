function GetinfoItemData(video as Object) as Object
    item = {}

	if video.info.description <> invalid
        item.description = video.info.description
    else
        item.description = video.info.plot
    end if
	
    if video.info.cover <> invalid
        item.hdPosterURL = video.info.cover
    else
        item.hdPosterURL = video.info.movie_image
    end if
	
    if video.info.backdrop_path <> invalid
        item.fhdposterurl = video.info.backdrop_path[0]
    else
        item.fhdposterurl = video.info.movie_image
    end if
	
	item.categories = video.info.genre.ToStr()
	
	if video.info.actors <> invalid
	    item.actors = video.info.actors.ToStr()
	end if
	
	item.cast = video.info.cast
    item.releasedate = video.info.releasedate
	
	item.directors = video.info.director.ToStr()

	if video.info.duration_secs <> invalid
        item.length = video.info.duration_secs
    end if
	
	if video.movie_data.container_extension <> invalid
        item.url = m.global.config.serverURL + m.global.play + video.movie_data.stream_id.ToStr() +"."+video.movie_data.container_extension
    end if
	
    return item
end function

function GetItemEpisode(video as Object) as Object
    item = {}
    item.id = video.stream_id
    item.title = video.title
    item.season = video.season
    item.episodePosition = video.episode_num.ToStr()
	
    if not isEmpty(video.info)
        ' populate length of content to be displayed on the GridScreen
        if invalid <> video.info.duration_secs then item.length = video.info.duration_secs.ToStr()
		if invalid <> video.info.releaseDate then item.releasedate = video.info.releaseDate.ToStr()
		if invalid <> video.info.rating then item.rating = video.info.rating.ToStr()
		if invalid <> video.info.movie_image then item.hdPosterURL = video.info.movie_image.ToStr()
        if invalid <> video.info.plot then item.description = video.info.plot.ToStr()
    end if
	
	if video.container_extension <> invalid
        item.url = m.global.config.serverURL + m.global.play + tostr(video.stream_id) +"."+video.container_extension
        item.streamFormat = video.container_extension
    end if
	
    return item
end function

function GetSeasonData(seasons as Object) as Object
    seasonsArray = []
    if seasons <> invalid
        episodeCounter = 0
        for each season in seasons 
            if season.episodes <> invalid
                episodes = []
                for each episode in season.episodes
                    episodeData = GetItemEpisode(episode)
                    ' save season title for element to represent it on the episodes screen
                    episodeData.titleSeason = season.name
                    episodeData.numEpisodes = episodeCounter
                    episodeData.mediaType = "episode"
                    episodes.Push(episodeData)
                    episodeCounter ++
                end for
                seasonData = {}
				seasonData.title = season.name
				seasonData.id = season.stream_id
                seasonData.children = episodes
                ' set content type for season object to represent it on the screen as section with episodes
                seasonData.contentType = "section"
                seasonsArray.Push(seasonData)
            end if
        end for
    end if
    return seasonsArray
end function
