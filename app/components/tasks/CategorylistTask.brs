'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub Init()
    m.top.functionName = "GetContent"
end sub

sub GetContent()
	categoryList = [ "get_live_categories", "get_vod_categories", "get_series_categories"]
	for each category in categoryList
        ' request the content feed from the API
        http = NewHttp( m.global.config.serverURL + "/player_api.php?username=" + m.global.user +"&password=" + m.global.pass + "&action=" + category)
		rsp = http.GetToStringWithRetry()
		json = ParseJson(rsp)
		if json <> invalid
	        result = [{"category_id": "all", "category_name": "Block All", "parent_id": 0}]
		    result.Append(json)
		    showList = []
			for i = 0 to result.count()-1
			    item = {}
			    item.code = result[i].category_id
			    item.name = tr(result[i].category_name)
			    showList.push(item)
			end for
			if category = "get_live_categories"
			    m.top.live = showList
			else if category = "get_vod_categories"
			    m.top.movies = showList
			else if category = "get_series_categories"
			    m.top.series = showList
			end if
		end if
    end for
    m.top.finish = true
end sub
