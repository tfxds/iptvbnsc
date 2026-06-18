sub Init()
    mBind(["posterMask", "itemPoster", "posterText", "focusRing", "card"])
    m.posterFont = createFont(getTheme().regularFont, 22)
    m.posterText.font = m.posterFont
end sub

sub OnItemContentChange()
    itemContent = m.top.itemContent
    if itemContent = invalid then return
    m.itemPoster.uri = itemContent.HDPOSTERURL
    m.posterText.text = ellipsizeTitle(itemContent.title, 18)
end sub

' Trunca o titulo numa linha so, com reticencias se for muito longo para o card.
' (Heuristica por numero de caracteres; a Label com wrap=false ainda corta o resto.)
function ellipsizeTitle(title, maxChars as Integer) as String
    if title = invalid then return ""
    if type(title) <> "String" and type(title) <> "roString" then title = "" + title
    if title.len() <= maxChars then return title
    return left(title, maxChars - 1).trim() + "..."
end function

'
' Foco: o anel azul aparece (sem escalar o poster, pra nao desalinhar o anel).
sub focusChanging()
    ' intencionalmente vazio: o destaque de foco eh o anel (on_focus_change)
end sub

function on_focus_change(event as object) as void
    if event.getData()
        m.focusRing.visible = true
        m.posterText.color = "0xffffffff"
    else
        m.focusRing.visible = false
        m.posterText.color = "0xc8dce8ff"
    end if
end function
