function GetSupportedMediaTypes() as Object ' returns AA with supported media types
    return {
        "series": "series"
        "season": "episode"
        "episode": "episode"
        "movie": "movies"
        "shortFormVideo": "shortFormVideos"
    }
end function

' check if deep link arguments are valid
function ValidateDeepLink(args as Object) as Boolean
   mediaType = args.mediaType
   contentId = args.contentId
   types = GetSupportedMediaTypes()
   return mediaType <> invalid and contentId <> invalid and types[mediaType] <> invalid
end function

' Perform deep linking
sub DeepLink(content as Object, mediaType as String, contentId as String)
    playableItem = FindNodeById(content, contentId) ' find content for deep linking by contentId
    types = GetSupportedMediaTypes()
    ' check if chosen item has appropriate mediaType
    if playableItem <> invalid and playableItem.mediaType = types[mediaType]
        'ClearScreenStack() ' remove all screen from screen stack except GridScreen
        ' looking for appropriate handler for provided mediaType
        if mediaType = "episode" or mediaType = "shortFormVideo" or mediaType = "movie"
            HandlePlayableMediaTypes(playableItem)
        else if mediaType = "season"
            HandleSeasonMediaType(playableItem)
        else if mediaType = "series"
            HandleSeriesMediaType(playableItem)
        end if
    end if
end sub

' Handler for "season" type
' Launch an EpisodesScreen that displays episodes organized by season; highlight the episode mapped to the contentid
sub HandleSeasonMediaType(content as Object)
    itemIndex = content.numEpisodes ' number of chosen episode among all seasons
    series = content.getParent().getParent() ' series node of the episode mapped to the contentid
    episodes = ShowEpisodesScreen(series, itemIndex) ' launch an EpisodesScreen
    episodes.ObserveField("visible", "OnDeepLinkDetailsScreenVisibilityChanged")
end sub

' Handler for "episode", "shortFormVideo" and "movie" types
' Play the content identified by the contentId
sub HandlePlayableMediaTypes(content as Object)
    PrepareDetailsScreen(content) ' create detailsScreen and push it to the screen stack
    ShowDeepVideoScreen(content) ' Launch a Video
end sub

sub PrepareDetailsScreen(content as Object)
    ' create DetailsScreen to be shown when user navigate from Video player
    ' it will contain info about played content
    m.deepLinkDetailsScreen = CreateObject("roSGNode", "DetailsScreenDeep")
    m.deepLinkDetailsScreen.content = content
    m.deepLinkDetailsScreen.ObserveField("visible", "OnDeepLinkDetailsScreenVisibilityChanged")
    m.deepLinkDetailsScreen.ObserveField("buttonSelected", "OnDeepLinkDetailsScreenButtonSelected")
    ShowScreen(m.deepLinkDetailsScreen) ' adds DetailsScreen to screen stack but don't show it 
end sub

sub OnDeepLinkDetailsScreenVisibilityChanged(event as Object) ' invoked when DetailsScreen or EpisodesScreen "visible" field is changed
    visible = event.GetData()
    screen = event.GetRoSGNode()
    if visible = false and IsScreenInScreenStack(screen) = false
        content = screen.content
        if content <> invalid
            ' jump to appropriate tile on GridScreen
            m.GridScreen.jumpToRowItem = [content.homeRowIndex, content.homeItemIndex]
            ' Invalidate deepLinkDetailsScreen if user press "Back" button on DetailsScreen
            if m.deepLinkDetailsScreen <> invalid
                m.deepLinkDetailsScreen = invalid
            end if
        end if
    end if
end sub

sub OnDeepLinkDetailsScreenButtonSelected(event as Object) ' invoked when button is  pressed on DetailsScreen
    buttonIndex = event.getData() ' index of selected button
    details = event.GetRoSGNode()
    button = details.buttons.getChild(buttonIndex)
    content = m.deepLinkDetailsScreen.content.clone(true)
    if button.id = "play"
        content.bookmarkPosition = 0
        ShowDeepVideoScreen(content)
    end if
end sub