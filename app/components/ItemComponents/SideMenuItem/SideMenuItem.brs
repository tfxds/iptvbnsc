sub init()
    m.hl = m.top.findNode("hl")
    m.icon = m.top.findNode("icon")
    m.caption = m.top.findNode("caption")
end sub

sub onContentSet()
    c = m.top.itemContent
    if c = invalid then return
    m.caption.text = c.title
    if c.HDLISTITEMICONURL <> invalid and c.HDLISTITEMICONURL <> ""
        m.icon.uri = c.HDLISTITEMICONURL
        m.icon.visible = true
    else
        m.icon.visible = false
    end if
end sub

' Realce: a pilula aparece (opacidade) e o texto fica branco quando focado.
sub onFocusChange()
    p = m.top.focusPercent
    m.hl.opacity = p
    if p > 0.5
        m.caption.color = "0xffffffff"
    else
        m.caption.color = "0xbcd0e8ff"
    end if
end sub
