'*************************************************************
'** TimeGridChannelItem — linha de canal (card fixo 600x68)
'*************************************************************
sub Init()
    mBind(["title", "poster", "rowBg", "rowBgFocus", "numero"])
    m.top.ObserveField("content", "OnContentSet")
end sub

sub OnContentSet()
    content = m.top.itemContent
    if content = invalid then content = m.top.content
    if content <> invalid
        m.title.text = content.title
        m.poster.uri = content.HDPOSTERURL
    end if

    ' Numero do canal = posicao na lista (index do MarkupList comeca em 0).
    idx = m.top.index
    if idx = invalid or idx < 0 then idx = 0
    m.numero.text = (idx + 1).ToStr()

    OnFocusPercentChanged()
end sub

' Foco: troca a OPACIDADE do card azul (NAO a uri) — trocar uri recarregava a imagem
' e piscava preto ao rolar a lista. Opacidade nao recarrega = sem pisca.
sub OnFocusPercentChanged()
    if m.rowBgFocus = invalid then return
    if m.top.focusPercent > 0.3
        m.rowBgFocus.opacity = 1
        m.title.color = "0xFFFFFFFF"
    else
        m.rowBgFocus.opacity = 0
        m.title.color = "0xE8EDF7FF"
    end if
end sub
