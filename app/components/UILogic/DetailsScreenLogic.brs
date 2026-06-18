'**************MAXIPTV.MX
sub ShowDetailsScreen(content as Object, selectedItem as Integer)
    ' create new instance of details screen
    detailsScreen = CreateObject("roSGNode", "DetailsScreen")
    detailsScreen.content = content
    detailsScreen.jumpToItem = selectedItem ' set index of item which should be focused
    detailsScreen.ObserveField("visible", "OnDetailsScreenVisibilityChanged")
    detailsScreen.ObserveField("buttonSelected", "OnButtonSelected")
    ShowScreen(detailsScreen)
end sub

sub OnDetailsScreenVisibilityChanged(event as Object) ' invoked when DetailsScreen "visible" field is changed
    visible = event.GetData()
    detailsScreen = event.GetRoSGNode()
    currentScreen = GetCurrentScreen()
    screenType = currentScreen.SubType()
    if visible = false
        if screenType = "GridScreen"
            ' update GridScreen's focus when navigate back from DetailsScreen
            currentScreen.jumpToRowItem = detailsScreen.itemFocused
			currentScreen.jumpToRowItemFilter = detailsScreen.itemFocused
        else if screenType = "MyListScreen"
            currentScreen.jumpToRowItem = detailsScreen.itemFocused
        else if screenType = "EpisodesScreen"
            ' update EpisodesScreen's focus when navigate back from DetailsScreen
            content = detailsScreen.content.GetChild(detailsScreen.itemFocused)
            currentScreen.jumpToItem = content.numEpisodes
        end if
    end if
end sub

sub OnButtonSelected(event) ' invoked when button in DetailsScreen is pressed
    details = event.GetRoSGNode()
    content = details.content
    buttonIndex = getScene().FindNode("buttons").content.GetChild(event.getData())
    selectedItem = details.itemFocused
    if buttonIndex.id = "play" or buttonIndex.id = "playepisode" ' check if "Play" and "Play Episode"button is pressed
        ' create Video node and start playback
        HandlePlayButton(content, selectedItem)
    else if buttonIndex.id = "episodes" ' check if "See all episodes" button is pressed
        ' create EpisodesScreen instance and show it
        ShowEpisodesScreen(content, selectedItem)
    else if buttonIndex.id = "add" ' add my list
        ' add item
		MarkItemList(content.GetChild(selectedItem))
		buttonIndex.id = "del"
		buttonIndex.title = tr("Remove from to my favorites") 
		buttonIndex.HDLISTITEMICONURL = "pkg:/images/icons/icon-remove-w.png"
		buttonIndex.HDLISTITEMICONSELECTEDURL = "pkg:/images/icons/icon-remove-b.png"
    else if buttonIndex.id = "del" ' del my list
        ' delete item
		UnMarkItemList(content.GetChild(selectedItem))
		buttonIndex.id = "add"
		buttonIndex.title = tr("Add to my favorites") 
		buttonIndex.HDLISTITEMICONURL = "pkg:/images/icons/icon-plus-w.png"
		buttonIndex.HDLISTITEMICONSELECTEDURL = "pkg:/images/icons/icon-plus-b.png"
    end if
end sub

sub MarkItemList(item as Object)
    if not IsMyListItem(item.mediatype, item.id)
		itemList = []
		if item.mediatype = "movie"
			if m.global.movie <> invalid
				itemList = m.global.movie
			end if	
			itemList.Push(ContentNodeToJson(item))
	    	m.global.movie = itemList
        	regWrite("movie", FormatJSON(itemList), ReadManifest().title)
        	'print "Add to List: "; itemList
		elseif item.mediatype = "series"
			if m.global.series <> invalid
				itemList = m.global.series
			end if	
			itemList.Push(ContentNodeToJson(item))
	    	m.global.series = itemList
        	regWrite("series", FormatJSON(itemList), ReadManifest().title)
        	'print "Add to List: "; itemList
		endif
	end if
end sub

sub  UnMarkItemList(content as Object)
	if content.mediatype = "movie"
        updatedItemList = []
        for each item in m.global.movie
            if item.id <> content.id
                updatedItemList.Push(item)
            end if
        end for
	    m.global.movie = updatedItemList
	    regWrite("movie", FormatJSON(updatedItemList), ReadManifest().title)
	    'print "Del to List: "; updatedItemList
	elseif content.mediatype = "series"
        updatedItemList = []
        for each item in m.global.series
            if item.id <> content.id
                updatedItemList.Push(item)
            end if
        end for
	    m.global.series = updatedItemList
	    regWrite("series", FormatJSON(updatedItemList), ReadManifest().title)
	    'print "Del to List: "; updatedItemList
	endif
end sub

sub HandlePlayButton(content as Object, selectedItem as Integer)
    itemContent = content.GetChild(selectedItem)
    ' if content child is serial with seasons
    ' we will set all episodes of serial to playlist
    if itemContent.mediaType = "series"
        ' Guarda capa/id/titulo da SERIE -> "assistidos" salva a capa certa e DEDUPLICA
        ' por serie (1 entrada por serie, nao 1 por episodio).
        if itemContent.hdPosterURL <> invalid then m.global.currentSeriesPoster = itemContent.hdPosterURL
        if itemContent.id <> invalid then m.global.currentSeriesId = AnyToString(itemContent.id)
        if itemContent.title <> invalid then m.global.currentSeriesTitle = itemContent.title
        children = []
        ' clone all episodes of easch season
        for each season in itemContent.getChildren(-1, 0)
            children.Append(CloneChildren(season))
        end for
        ' create new node and set all episodes of serial
        node = CreateObject("roSGNode", "ContentNode")
        node.Update({ children: children }, true)
        ' create a Video node and start playback
		if itemContent.GetChildCount() <> 0
            ShowVideoScreen(node, 0, true)
		end if
    else
        ShowVideoScreen(content, selectedItem)
    end if
    m.selectedIndex = selectedItem ' store index of selected item
end sub