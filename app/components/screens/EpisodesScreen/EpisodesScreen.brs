'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
function Init()
    mBind([ "seasons", "episodes", "backdrop"])

    m.top.ObserveField("visible", "onVisibleChange")
    m.seasons.ObserveField("itemFocused", "OnCategoryItemFocused")
    m.episodes.ObserveField("itemFocused", "OnListItemFocused")
    m.episodes.ObserveField("itemSelected", "OnListItemSelected")
    m.top.ObserveField("content", "OnContentChange")
end function

sub OnListItemFocused(event as Object) ' invoked when episode is focused
    focusedItem = event.GetData() ' index of episode
    ' index of season which contains focused episode
    categoryIndex = m.itemToSection[focusedItem]
	if categoryIndex <> invalid
        ' change focused item in seasons list
        if (categoryIndex - 1) = m.seasons.jumpToItem
            m.seasons.animateToItem = categoryIndex
        else if not m.seasons.IsInFocusChain()
            m.seasons.jumpToItem = categoryIndex
        end if
	end if
end sub

sub InitSections(content as Object)
    if isnonemptystr(content.FHDPOSTERURL)
      m.backdrop.uri = content.FHDPOSTERURL
    end if
    ' save the position of the first episode for each season
    m.firstItemInSection = [0]
    ' save the season index to which the episode belongs
    m.itemToSection = []
    ' save the title of each season
    sections = []
    sectionCount = 0
    ' goes through seasons and populate "firstItemInSection" and "itemToSection" arrays
    for each section in content.GetChildren(- 1, 0)
        itemsPerSection = section.GetChildCount()
        for each child in section.GetChildren(- 1, 0)
		    if child <> invalid
               m.itemToSection.Push(sectionCount)
			end if
        end for
        sections.push({title : section.title}) ' save title of each season
        m.firstItemInSection.Push(m.firstItemInSection.Peek() + itemsPerSection)
        sectionCount++
    end for
    m.firstItemInSection.Pop() ' remove last item
    m.seasons.content = ContentListToSimpleNode(sections) ' populate categortList with list of seasons
end sub

sub OnCategoryItemFocused(event as Object) ' invoked when season is focused
    ' we shouldn't change the focus in the episodes list as soon as we have switched to the list of seasons
    if m.seasonsGainFocus = true
        m.seasonsGainFocus = false
    else
        focusedItem = event.getData() ' index of season
        ' navigate to the first episode of season
        m.episodes.jumpToItem = m.firstItemInSection[focusedItem]
    end if
end sub

sub OnJumpToItem(event as Object) ' invoked when "jumpToItem field is changed
    itemIndex = event.GetData()
    m.episodes.jumpToItem = itemIndex ' navigate to the specified item
end sub

sub OnContentChange() ' invoked when EpisodesScreen content is changed
    content = m.top.content
    InitSections(content) ' populate seasons list
    m.episodes.content = content ' populate episodes list
end sub

sub onVisibleChange() ' invoked when Episodes screen becomes visible
    if m.top.visible = true
        m.episodes.setFocus(true) ' set focus to the episodes list
    end if
end sub

sub OnListItemSelected(event as Object) ' invoked when episode is selected
    itemSelected = event.GetData() ' index of selected item
    sectionIndex = m.itemToSection[itemSelected] ' season which contains selected episode
	m.top.jumpToEpisode = itemSelected
    ' OnEpisodesScreenItemSelected method in EpisodesScreenLogic.brs is invoked when selectedItem array is populated
    m.top.selectedItem = [sectionIndex, itemSelected - m.firstItemInSection[sectionIndex]]
end sub

' The OnKeyEvent() function receives remote control key events
function OnKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press
        ' handle "left" key press
        if key = "left" and m.episodes.HasFocus() ' episodes list should be focused
            m.seasonsGainFocus = true
            ' navigate to seasons list
            m.seasons.SetFocus(true)
            result = true
        ' handle "right" key press
        else if key = "right" and m.seasons.HasFocus() ' seasons list should be focused
            ' navigate to episodes list
            m.episodes.SetFocus(true)
            result = true
        end if
    end if
    return result
end function
