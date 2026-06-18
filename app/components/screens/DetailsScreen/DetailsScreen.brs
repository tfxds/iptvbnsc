'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
' entry point of detailsScreen
function Init()
    mBind([ "description", "backdrop", "buttons", "shiftUpGroup",
          "title", "year", "genres", "cast", "director"])
		    
    m.top.ObserveField("visible", "OnVisibleChange")
    m.top.ObserveField("itemFocused", "OnItemFocusedChanged")
    m.bookmark = 0
	
end function

sub onVisibleChange()' invoked when DetailsScreen visibility is changed
    ' set focus for buttons list when DetailsScreen becomes visible
    if m.top.visible = true
        m.buttons.SetFocus(true)
    end if
end sub


sub SetDetailsContent(content)
    if isnonemptystr(content.FHDPOSTERURL)
      m.backdrop.uri = content.FHDPOSTERURL
	  m.global.backdrop = content.FHDPOSTERURL
	else
      m.backdrop.uri = m.global.backdrop
    end if

    m.description.text = content.description
	
    buttons = []
    if content.mediaType = "series"
      buttons.Push({id: "playepisode", title: tr("Reproduzir Tudo"), HDLISTITEMICONURL: "pkg:/images/icons/icon-play-w.png", HDLISTITEMICONSELECTEDURL: "pkg:/images/icons/icon-play-b.png"})
      buttons.Push({id: "episodes", title: tr("Episódios"), HDLISTITEMICONURL: "pkg:/images/icons/icon-episodes-w.png", HDLISTITEMICONSELECTEDURL: "pkg:/images/icons/icon-episodes-b.png"})
	  if not IsMyListItem(content.mediaType,content.id)
	      buttons.Push({id: "add", title: tr("Adicionar ao Favoritos"), HDLISTITEMICONURL: "pkg:/images/icons/icon-plus-w.png", HDLISTITEMICONSELECTEDURL: "pkg:/images/icons/icon-plus-b.png"})
	  else
	      buttons.Push({id: "del", title: tr("Remover dos meus favoritos"), HDLISTITEMICONURL: "pkg:/images/icons/icon-remove-w.png", HDLISTITEMICONSELECTEDURL: "pkg:/images/icons/icon-remove-b.png"})
      end if
    else
      buttons.Push({id: "play", title: tr("Iniciar"), HDLISTITEMICONURL: "pkg:/images/icons/icon-play-w.png", HDLISTITEMICONSELECTEDURL: "pkg:/images/icons/icon-play-b.png"})
	  if not IsMyListItem(content.mediaType,content.id)
	      buttons.Push({id: "add", title: tr("Adicionar aos meus favoritos"), HDLISTITEMICONURL: "pkg:/images/icons/icon-plus-w.png", HDLISTITEMICONSELECTEDURL: "pkg:/images/icons/icon-plus-b.png"})
	  else
	      buttons.Push({id: "del", title: tr("Remover dos meus favoritos"), HDLISTITEMICONURL: "pkg:/images/icons/icon-remove-w.png", HDLISTITEMICONSELECTEDURL: "pkg:/images/icons/icon-remove-b.png"})
      end if	  
    end if
    m.buttons.content = List2ContentNode(buttons)

    text = []
	text.push(content.title)
	if content.contentType = 2
	  seasons = []
      for each season in content.getChildren(-1, 0)
	    seasons.push(season)
      end for
	  if seasons.count() <> 1
	    text.push(seasons.count().toStr() + " " + tr("Temporadas"))
	  else
        text.push(seasons.count().toStr() + " " + tr("Temporada"))	  
	  end if
	end if
	
	m.title.text = text.join(" | ")
	
    m.genres.text = content.categories.join(", ")
    m.cast.text = content.actors.join(", ")
    if isnonemptystr(m.cast.text) then m.cast.text += chr(10)
    if isnonemptystr(content.directors) then m.cast.text += "Direção: " + content.directors.join(", ")
    year = []
    if content.releaseDate <> invalid then year.push(content.releaseDate.split("-")[0])
    if isnonemptystr(content.rating) then year.push(content.rating)
    if isNumber(content.length) then year.push(secondsToDuration(content.length))
    m.year.text = year.join(" | ")
	
    m.detailsPoster = createObject("roSGNode", "Poster")
    m.detailsPoster.id = "detailsPoster"
    m.detailsPoster.loadDisplayMode = "limitSize"
    m.detailsPoster.loadWidth = 450
    m.detailsPoster.loadHeight = 675
    m.detailsPoster.width = 450
    m.detailsPoster.height = 675
    m.detailsPoster.translation = [243, 200]
    m.detailsPoster.failedBitmapUri = "pkg:/images/poster_failed.png"
    m.detailsPoster.uri = content.hdposterurl
    m.shiftUpGroup.translation = [0, 905]
    m.top.appendChild(m.detailsPoster)
end sub

sub onDetailsPosterTimerFire()
  if m.detailsPoster <> invalid and m.detailsPoster.loadStatus = "loading"
    m.top.removeChild(m.detailsPoster)
    m.detailsPoster = createObject("roSGNode", "Poster")
    m.detailsPoster.id = "detailsPoster"
    m.detailsPoster.loadWidth = 550
    m.detailsPoster.loadHeight = 309
    m.detailsPoster.width = 550
    m.detailsPoster.height = 309
    m.detailsPoster.translation = [143, 200]
    m.detailsPoster.uri = m.top.content.hdposterurl
    m.top.appendChild(m.detailsPoster)
  end if
end sub

sub OnJumpToItem() ' invoked when jumpToItem field is populated
    content = m.top.content
    ' check if jumpToItem field has valid value
    ' it should be set within interval from 0 to content.Getchildcount()
    if content <> invalid and m.top.jumpToItem >= 0 and content.GetChildCount() > m.top.jumpToItem
        m.top.itemFocused = m.top.jumpToItem
    end if
end sub

sub OnItemFocusedChanged(event as Object)' invoked when another item is focused
    m.screenType = event.GetRoSGNode()
    focusedItem = event.GetData() ' get position of focused item
    content = m.top.content.GetChild(focusedItem) ' get metadata of focused item
	if content.mediatype = "movie"
        m.movieTask = CreateObject("roSGNode", "vodItemLoaderTask")
	else
	    m.movieTask = CreateObject("roSGNode", "seriesItemLoaderTask")
	end if
    m.movieTask.ObserveField("contentView", "OnInfoContentLoaded")
	m.movieTask.content = content
    m.movieTask.id = content.id
    m.movieTask.control = "run"
	getScene().FindNode("loadingIndicator").visible = true
    'SetDetailsContent(content) ' populate DetailsScreen with item metadata
end sub

sub OnInfoContentLoaded()
    getScene().FindNode("loadingIndicator").visible = false
	if m.movieTask.contentView <> invalid
        SetDetailsContent(m.movieTask.contentView) ' populate DetailsScreen with item metadata	
	end if
end sub

' The OnKeyEvent() function receives remote control key events
function OnkeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press
        currentItem = m.top.itemFocused ' position of currently focused item
		'?"ScreenType " m.screenType.SubType()
        ' handle "left" button keypress
        if key = "left"
            ' navigate to the left item in case of "left" keypress
            m.top.jumpToItem = currentItem - 1
            result = true
        ' handle "right" button keypress
        else if key = "right"
            ' navigate to the right item in case of "right" keypress
            m.top.jumpToItem = currentItem + 1
            result = true
        end if
    end if
    return result
end function