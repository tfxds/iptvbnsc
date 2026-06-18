sub Init()
    mBind(["title", "icon", "iconbox", "itemRing", "itemFill"])
    m.itemContentValues = m.top.itemContent
end sub

sub showcontent()
    m.itemContentValues = m.top.itemContent
    m.title.text = m.itemContentValues.title
    m.icon.uri = m.itemContentValues.icon
    showfocus()
end sub

' Foco: borda azul clara + fundo azul. Sem foco: borda discreta + fundo escuro.
sub applyFocus(focused as boolean)
    if focused then
        m.itemRing.color = "0x4F9CFFFF"
        m.itemFill.color = "0x2563EBFF"
        m.title.color = "0xFFFFFFFF"
    else
        m.itemRing.color = "0x2A3B5CFF"
        m.itemFill.color = "0x131D31FF"
        m.title.color = "0xC8DCE8FF"
    end if
end sub

sub showfocus()
    applyFocus(m.top.focusPercent > 0.3)
end sub

sub itemHasFocus()
    if m.top.itemContent <> invalid
        applyFocus(m.top.itemHasFocus)
    end if
end sub
