Sub init()
    mBind(["mainGroup", "poster", "icon"])
    m.top.id = "markupGridItem" 

End Sub

sub showcontent()
    if m.top.itemContent <> invalid and m.top.width > 0 and m.top.height > 0
        m.mainGroup.translation = [m.top.width / 2, m.top.height / 2 - 30]
        m.icon.width = 190  'm.top.width
        m.icon.height = m.icon.width
		m.icon.uri = m.top.itemContent.HDLISTITEMICONURL
        showfocus()
    end if
end sub

sub showfocus()
    if m.top.itemContent <> invalid
        tile = getDefaultAssets().menuTile
        if m.top.focusPercent > 0.3
            m.poster.uri = "pkg:/images/list_selection_focus.png"
        else
            m.poster.uri = tile
        end if
    end if
end sub

