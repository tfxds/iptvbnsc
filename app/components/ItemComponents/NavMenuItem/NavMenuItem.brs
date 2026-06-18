sub Init()
    mBind(["cardBg", "icon", "caption"])
end sub

sub onItemContentChange()
    if m.top.itemContent = invalid then return
    content = m.top.itemContent
    if content.shortdescriptionline1 <> invalid
        m.caption.text = content.shortdescriptionline1
    end if
    if content.HDLISTITEMICONURL <> invalid
        m.icon.uri = content.HDLISTITEMICONURL
    end if
    m.cardBg.uri = "pkg:/images/menu/navcard.png"
end sub

sub onFocusChange()
    ' O foco e o SELETOR UNICO do MenuScreen; o card fica sempre no estado normal.
    m.cardBg.uri = "pkg:/images/menu/navcard.png"
end sub
