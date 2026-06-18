' Copyright (c) 2020 Roku, Inc. All rights reserved.

sub init()
    mBind([ "itemPoster", "background", "title", "description", "duration", "frame" ])
    m.title.font = createFont(getTheme().regularFont,getTheme().episodeTitleFontSize)
    m.description.font = createFont(getTheme().regularFont,getTheme().normalFontSize)
    m.duration.font = createFont(getTheme().regularFont,getTheme().normalFontSize)
    m.description.lineSpacing = getTheme().textLineSpacing
end sub

sub itemContentChanged() ' invoked when episode data is retrieved
    itemContent = m.top.itemContent ' episode metadata
    if itemContent <> invalid
        ' populate components with metadata
        m.poster.uri = itemContent.hdPosterUrl
        m.title.text = itemContent.title
        divider = " | "
        episode = "E" + itemContent.episodePosition
        time = GetTime(itemContent.length)
        date = itemContent.releaseDate
        season = itemContent.titleSeason
        m.info.text = episode + divider + date + divider + time + divider + season
        m.description.text = itemContent.description
    end if
end sub

sub showcontent()
    if m.top.width > 0 and m.top.height > 0 and m.top.itemContent <> invalid
        itemcontent = m.top.itemContent
        m.frame.height = m.top.height
        m.frame.width = m.top.width
        m.background.height = m.top.height - getTheme().frameThickness * 2
        m.background.width = m.top.width - getTheme().frameThickness * 2
        m.background.translation = [getTheme().frameThickness, getTheme().frameThickness]
        m.itemposter.loadWidth = m.background.width / 2
        m.itemposter.loadHeight = m.background.height
        m.itemposter.height = m.background.height
        m.itemposter.width = m.background.height 
        m.itemposter.uri = itemcontent.HDPOSTERURL
        m.top.findNode("detailGroup").translation = [m.itemposter.width + getTheme().episodeTextLeftRightPadding, getTheme().episodeTextTopBottomPadding]
        m.title.maxWidth = m.background.width - m.itemposter.width - getTheme().episodeTextLeftRightPadding * 2
        m.description.width = m.background.width - m.itemposter.width - getTheme().episodeTextLeftRightPadding * 2
        m.title.text = itemcontent.title
        m.description.text = itemcontent.DESCRIPTION
        m.duration.text = secondsToDuration(itemcontent.LENGTH, true)
        m.duration.translation = [0, m.background.height - m.duration.boundingRect().height - getTheme().episodeTextTopBottomPadding * 2]
        m.description.translation = [0, m.title.boundingRect().height + getTheme().episodeTextTopBottomPadding * 2]
        m.description.height = m.duration.translation[1] - m.description.translation[1] - getTheme().episodeTextTopBottomPadding
    end if
end sub

sub showfocus()
    if m.top.listHasFocus
        m.frame.opacity = m.top.focusPercent
    else
        m.frame.opacity = 0.1 * m.top.focusPercent
    end if
end sub
