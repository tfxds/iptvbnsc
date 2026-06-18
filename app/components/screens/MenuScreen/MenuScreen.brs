'*************************************************************
'** MenuScreen — Home (sidebar vertical + linhas de conteudo)
'** Layout novo (Speed PlayerTech). Reaproveita as acoes do MenuScreenLogic
'** (actionId -> OnMenuAction) e os dados das linhas (homeRows, alimentado de fora).
'*************************************************************

sub Init()
    mBind([
        "bgMenu", "sidebarBg", "headerLogo", "menuList",
        "macLabel", "expLabel", "welcomeLabel", "clockLabel", "clockTimer",
        "contentRows"
    ])

    ' Fundo: bg.png da marca por padrao (revendedor pode sobrescrever via fondo).
    m.bgMenu.uri = getGlobalFondo()
    ' Logo do revendedor no topo da sidebar (default = marca).
    m.headerLogo.uri = getGlobalLogoMenu()

    setupMenu()
    setupFooter()
    setupWelcome()

    m.menuList.observeField("itemSelected", "onMenuItemSelected")
    m.contentRows.observeField("rowItemSelected", "onRowItemSelected")
    m.clockTimer.observeField("fire", "updateClock")
    ' Ao VOLTAR pra home (CloseScreen devolve o foco ao componente), o foco fica preso no
    ' m.top e a tela trava -> redireciona pro menu lateral.
    m.top.observeField("focusedChild", "onMenuFocusChanged")

    updateClock()
    m.clockTimer.control = "start"
end sub


' Itens do menu lateral. 'act' = acao roteada pelo MenuScreenLogic.OnMenuAction
' ('home' e tratado aqui: so move o foco pras linhas).
sub setupMenu()
    items = []
    items.Push({ title: tr("Pesquisar"),      act: "search",   HDLISTITEMICONURL: "pkg:/images/menu/search.png" })
    items.Push({ title: tr("Início"),         act: "home",     HDLISTITEMICONURL: "" })
    items.Push({ title: tr("TV ao vivo"),     act: "live",     HDLISTITEMICONURL: "pkg:/images/menu/tv.png" })
    items.Push({ title: tr("Filmes"),         act: "movies",   HDLISTITEMICONURL: "pkg:/images/menu/movie.png" })
    items.Push({ title: tr("Séries"),         act: "series",   HDLISTITEMICONURL: "pkg:/images/menu/series.png" })
    items.Push({ title: tr("Histórico"),      act: "favorites", HDLISTITEMICONURL: "pkg:/images/menu/plus.png" })
    items.Push({ title: tr("Meus dados"),     act: "account",  HDLISTITEMICONURL: "pkg:/images/menu/account.png" })
    items.Push({ title: tr("Configurações"),  act: "settings", HDLISTITEMICONURL: "pkg:/images/menu/settings.png" })
    items.Push({ title: tr("Atualizar lista"),act: "reload",   HDLISTITEMICONURL: "pkg:/images/menu/reload.png" })
    m.menuList.content = List2ContentNode(items)
    m.menuList.jumpToItem = 0
end sub


sub setupFooter()
    userName = ""
    if m.global <> invalid and m.global.user <> invalid then userName = m.global.user
    m.macLabel.text = "● Conectado: " + userName

    expText = "Validade : --"
    if m.global <> invalid and m.global.expire <> invalid
        if m.global.expire = "Never"
            expText = "Validade : " + tr("Never")
        else
            dt = CreateObject("roDateTime")
            dt.fromSeconds(m.global.expire.toInt())
            expText = "Validade : " + dt.AsDateString("short-month-no-weekday")
        end if
    end if
    m.expLabel.text = expText + "   ·   build " + ReadManifest().build_version
end sub


sub setupWelcome()
    nome = "Speed PlayerTech"
    if m.global <> invalid and m.global.titulo <> invalid and m.global.titulo <> "" then nome = m.global.titulo
    m.welcomeLabel.text = tr("Bem-vindo ao ") + nome
end sub


sub onHomeRowsSet()
    if m.contentRows = invalid then return
    if m.top.homeRows <> invalid then m.contentRows.content = m.top.homeRows
end sub


' Selecao no menu lateral: 'home' foca as linhas; o resto dispara a acao no Logic.
' Acoes na MESMA ordem dos itens de setupMenu (mapeadas por indice -> robusto,
' nao depende de campo custom sobreviver no ContentNode).
sub onMenuItemSelected()
    acts = ["search", "home", "live", "movies", "series", "favorites", "account", "settings", "reload"]
    idx = m.menuList.itemSelected
    if idx < 0 or idx >= acts.Count() then return
    act = acts[idx]
    if act = "home"
        if m.contentRows.content <> invalid and m.contentRows.content.getChildCount() > 0
            m.contentRows.setFocus(true)
        end if
    else
        m.top.actionId = act
    end if
end sub


' Card selecionado numa linha -> espelha [linha,coluna] pro Logic abrir o item.
sub onRowItemSelected()
    m.top.rowItemSelected = m.contentRows.rowItemSelected
end sub

' Devolve o foco a um filho navegavel quando o componente recebe foco (ao voltar de outra tela).
sub onMenuFocusChanged()
    if m.top.hasFocus() then m.menuList.setFocus(true)
end sub


sub updateClock()
    dt = CreateObject("roDateTime")
    dt.Mark()
    hours = dt.GetHours()
    mins = dt.GetMinutes()
    minStr = mins.ToStr()
    if mins < 10 then minStr = "0" + minStr
    hourStr = stri(hours).Trim()
    if hours < 10 then hourStr = "0" + hourStr
    m.clockLabel.text = hourStr + ":" + minStr
end sub


' Navegacao de foco entre o menu (esquerda) e as linhas (direita).
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "right"
        if m.menuList.hasFocus()
            if m.contentRows.content <> invalid and m.contentRows.content.getChildCount() > 0
                m.contentRows.setFocus(true)
                return true
            end if
        end if
    else if key = "left"
        if m.contentRows.hasFocus()
            col = 0
            sel = m.contentRows.rowItemFocused
            if sel <> invalid and sel.Count() >= 2 then col = sel[1]
            if col <= 0
                m.menuList.setFocus(true)
                return true
            end if
        end if
    else if key = "back"
        if m.contentRows.hasFocus()
            m.menuList.setFocus(true)
            return true
        end if
    end if

    return false
end function
