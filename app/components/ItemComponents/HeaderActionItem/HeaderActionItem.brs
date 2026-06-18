sub Init()
    mBind(["pillBg", "icon", "caption"])
end sub

' Sem dependencia de width/height: a pilula ja tem tamanho fixo no XML e sempre aparece.
sub onItemContentChange()
    if m.top.itemContent = invalid then return
    content = m.top.itemContent
    if content.shortdescriptionline1 <> invalid
        m.caption.text = content.shortdescriptionline1
    end if
    if content.HDLISTITEMICONURL <> invalid
        m.icon.uri = content.HDLISTITEMICONURL
    end if
    m.pillBg.uri = "pkg:/images/menu/pill.png"
end sub

sub onFocusChange()
    ' O foco e o SELETOR UNICO do MenuScreen; a pilula fica sempre no estado normal.
    m.pillBg.uri = "pkg:/images/menu/pill.png"
    m.caption.color = "0xffffff"
end sub
