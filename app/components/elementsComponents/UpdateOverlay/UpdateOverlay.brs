sub init()
    m.barFill = m.top.findNode("barFill")
    m.pct = m.top.findNode("pct")
    render()
end sub

sub render()
    if m.barFill = invalid then return

    ' status de cada passo (carregam em sequencia: canais -> filmes -> series)
    applyStep("cardCanais", "iconCanais", "okCanais", "1º", statusOf(m.top.canaisDone, true))
    applyStep("cardFilmes", "iconFilmes", "okFilmes", "2º", statusOf(m.top.filmesDone, m.top.canaisDone))
    applyStep("cardSeries", "iconSeries", "okSeries", "3º", statusOf(m.top.seriesDone, m.top.filmesDone))

    done = 0
    if m.top.canaisDone then done = done + 1
    if m.top.filmesDone then done = done + 1
    if m.top.seriesDone then done = done + 1

    m.barFill.width = (done / 3.0) * 820.0
    if m.pct <> invalid then m.pct.text = Str(Int((done / 3.0) * 100)).Trim() + "%"
end sub

' Retorna "done" / "loading" / "pending"
function statusOf(isDone as Boolean, prevReady as Boolean) as String
    if isDone then return "done"
    if prevReady then return "loading"
    return "pending"
end function

sub applyStep(cardId as String, iconId as String, okId as String, order as String, status as String)
    card = m.top.findNode(cardId)
    icon = m.top.findNode(iconId)
    ok = m.top.findNode(okId)
    if card = invalid or icon = invalid or ok = invalid then return

    if status = "done"
        card.color = "0x16A34A22"
        icon.text = "✓"
        icon.color = "0x22C55EFF"
        ok.text = "carregado"
        ok.color = "0x22C55EFF"
    else if status = "loading"
        card.color = "0x0EA5E926"
        icon.text = "•"
        icon.color = "0x38BDF8FF"
        ok.text = "carregando…"
        ok.color = "0x38BDF8FF"
    else
        card.color = "0x0E1626CC"
        icon.text = order
        icon.color = "0x94A3B8FF"
        ok.text = ""
    end if
end sub
