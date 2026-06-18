sub init()
    m.itemPoster = m.top.findNode("itemPoster")
    m.itemText = m.top.findNode("itemText")
end sub

sub itemContentChanged()
    render()
end sub

sub showfocus()
    render()
end sub

sub itemHasFocus()
    render()
end sub

sub render()
    itemData = m.top.itemContent
    if itemData = invalid then return

    m.itemText.text = itemData.labelText

    active = false
    if itemData.isSelected = true then active = true
    if m.top.itemHasFocus = true then active = true
    if m.top.focusPercent > 0.3 then active = true

    if active then
        m.itemPoster.uri = "pkg:/images/search/pill_active.png"
        m.itemText.color = "0xFFFFFF"
    else
        m.itemPoster.uri = "pkg:/images/search/pill_normal.png"
        m.itemText.color = "0x9FB6C6"
    end if
end sub
