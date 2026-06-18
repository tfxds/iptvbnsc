sub Init()
    mBind(["bg", "focusRing", "icon", "title", "subtitle", "badge", "badgeRow", "badgeDot"])
end sub

sub onItemContentChange()
    if m.top.itemContent = invalid or m.top.width <= 0 or m.top.height <= 0 then return

    w = m.top.width
    h = m.top.height
    m.bg.width = w
    m.bg.height = h
    m.focusRing.width = w
    m.focusRing.height = h
    m.focusRing.uri = "pkg:/images/menu/hero_focus.png"

    m.icon.translation = [40, 40]
    m.badge.translation = [w - 178, 40]
    m.title.translation = [40, h - 118]
    m.title.width = w - 80
    m.subtitle.translation = [40, h - 62]
    m.subtitle.width = w - 80

    content = m.top.itemContent
    if content.shortdescriptionline1 <> invalid
        m.title.text = content.shortdescriptionline1
    end if
    if content.shortdescriptionline2 <> invalid
        m.subtitle.text = content.shortdescriptionline2
    end if
    if content.HDLISTITEMICONURL <> invalid
        m.icon.uri = content.HDLISTITEMICONURL
    end if
    ' Fundo do tile = gradiente proprio (nao a logo do painel)
    if content.tileBg <> invalid and content.tileBg <> ""
        m.bg.uri = content.tileBg
    else
        m.bg.uri = "pkg:/images/menu/tile_live.png"
    end if
    ' Selo "AO VIVO" so no tile de TV ao vivo
    m.badge.visible = (content.id = "live")

    onFocusChange()
end sub

sub onFocusChange()
    ' Foco agora e o SELETOR UNICO do MenuScreen; nao usar anel por item
    m.focusRing.visible = false
end sub
