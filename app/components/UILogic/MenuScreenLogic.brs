'*************************************************************
'** Menu — dashboard completo
'*************************************************************

sub ShowMenuScreen()
    m.MenuScreen = CreateObject("roSGNode", "MenuScreen")
    m.MenuScreen.observeField("actionId", "OnMenuAction")
    m.MenuScreen.observeField("rowItemSelected", "OnHomeCardSelected")

    overhang = getScene().FindNode("overhang")
    if overhang <> invalid then overhang.visible = false

    ShowScreen(m.MenuScreen)
    stampMenuAccess()
    ' Pre-carrega Filmes e Series (Todos) em background pro cache -> 1a entrada instantanea.
    preloadListings()
    ' Monta as linhas da home com o que ja tiver (Continuar Assistindo entra na hora;
    ' Filmes/Series entram quando o preload terminar -> onPreload*Done re-monta).
    m.MenuScreen.homeRows = buildHomeRows()
end sub

' Dispara em paralelo os loaders de Filmes e Series (Todos), isolados via campos
' action/ctype (nao mexem nos globals). Ao terminar, populam o cache de sessao.
sub preloadListings()
    if m.global = invalid or m.global.config = invalid then return
    if m.cacheGrid_movie = invalid
        m.preloadMovie = CreateObject("roSGNode", "MainLoaderTask")
        m.preloadMovie.action = "get_vod_streams"
        m.preloadMovie.ctype = "movie"
        m.preloadMovie.category_id = ""
        m.preloadMovie.cacheKey = "saplayer_movie"
        m.preloadMovie.ObserveField("content", "onPreloadMovieDone")
        m.preloadMovie.control = "run"
    end if
    if m.cacheGrid_series = invalid
        m.preloadSeries = CreateObject("roSGNode", "MainLoaderTask")
        m.preloadSeries.action = "get_series"
        m.preloadSeries.ctype = "series"
        m.preloadSeries.category_id = ""
        m.preloadSeries.cacheKey = "saplayer_series"
        m.preloadSeries.ObserveField("content", "onPreloadSeriesDone")
        m.preloadSeries.control = "run"
    end if
    ' Preload da lista CRUA de canais -> popula m.global.liveStreamsRaw em background.
    ' Ao abrir Canais, categorias+lista usam o cache (abre rapido, sem download na hora).
    if m.global.liveStreamsRaw = invalid or m.global.liveStreamsRaw = ""
        m.preloadLive = CreateObject("roSGNode", "TimeGridLoaderTask")
        m.preloadLive.id = ""
        m.preloadLive.rawOnly = true
        m.preloadLive.control = "run"
    end if
end sub

sub onPreloadMovieDone()
    if m.preloadMovie <> invalid and m.preloadMovie.content <> invalid
        m.cacheGrid_movie = m.preloadMovie.content
        if m.MenuScreen <> invalid then m.MenuScreen.homeRows = buildHomeRows()
    end if
end sub

sub onPreloadSeriesDone()
    if m.preloadSeries <> invalid and m.preloadSeries.content <> invalid
        m.cacheGrid_series = m.preloadSeries.content
        if m.MenuScreen <> invalid then m.MenuScreen.homeRows = buildHomeRows()
    end if
end sub

' Monta a arvore de linhas da home: Continuar (filmes/series) + Recentes (filmes/series).
function buildHomeRows() as Object
    root = CreateObject("roSGNode", "ContentNode")

    cw = loadContinueWatchingList()
    appendContinueRow(root, cw, tr("Continuar filmes assistidos"), "movie")
    appendContinueRow(root, cw, tr("Continuar séries"), "series")

    appendCatalogRow(root, m.cacheGrid_movie, tr("Filmes adicionados recentemente"), "movie", 20)
    appendCatalogRow(root, m.cacheGrid_series, tr("Séries adicionadas recentemente"), "series", 20)

    return root
end function

' Linha "Continuar assistindo" filtrada por tipo (movie vs series/episode).
sub appendContinueRow(root as Object, cw as Object, title as String, kind as String)
    if cw = invalid or cw.Count() = 0 then return
    matched = []
    for each e in cw
        if e <> invalid and e.id <> invalid
            ct = ""
            if e.contentType <> invalid then ct = lcase("" + e.contentType)
            if ct = "" and e.mediaType <> invalid then ct = lcase("" + e.mediaType)
            isMovie = (ct = "movie")
            if (kind = "movie" and isMovie) or (kind = "series" and not isMovie)
                matched.Push(e)
            end if
        end if
    end for
    if matched.Count() = 0 then return
    row = root.CreateChild("ContentNode")
    row.title = title
    row.addField("rowType", "string", false)
    row.rowType = "continue"
    for each e in matched
        card = row.CreateChild("ContentNode")
        if e.hdPosterURL <> invalid then card.HDPOSTERURL = e.hdPosterURL
        if e.title <> invalid then card.title = e.title
    end for
end sub

' Copia ate maxN itens do cache numa linha, ORDENADOS por id desc (mais recentes primeiro).
sub appendCatalogRow(root as Object, cache as Object, title as String, rowType as String, maxN as Integer)
    if cache = invalid then return
    n = cache.getChildCount()
    if n <= 0 then return

    order = []
    for i = 0 to n - 1
        it = cache.getChild(i)
        if it <> invalid
            idv = 0
            if it.id <> invalid and it.id <> "" then idv = ("" + it.id).ToInt()
            order.Push({ idx: i, idv: idv })
        end if
    end for
    order.SortBy("idv")   ' ascendente -> percorro do fim pro inicio (desc = mais novos)

    row = root.CreateChild("ContentNode")
    row.title = title
    row.addField("rowType", "string", false)
    row.rowType = rowType
    count = 0
    j = order.Count() - 1
    while j >= 0 and count < maxN
        it = cache.getChild(order[j].idx)
        if it <> invalid
            row.appendChild(it.clone(true))
            count = count + 1
        end if
        j = j - 1
    end while
end sub

' Card de uma linha selecionado: Continuar -> historico; Filme/Serie -> detalhes do item.
sub OnHomeCardSelected()
    sel = m.MenuScreen.rowItemSelected
    if sel = invalid or sel.Count() < 2 then return
    rows = m.MenuScreen.homeRows
    if rows = invalid then return
    rowNode = rows.getChild(sel[0])
    if rowNode = invalid then return

    rtype = rowNode.rowType
    if rtype = "continue"
        m.global.menuNavMode = "recordings"
        m.global.titleSection = tr("Continuar Assistindo")
        ShowMyListScreen()
        RunMyListTask()
    else if rtype = "movie"
        openHomeItem(rowNode, sel[1], m.cacheGrid_movie, "movie")
    else if rtype = "series"
        openHomeItem(rowNode, sel[1], m.cacheGrid_series, "series")
    end if
end sub

' Abre os DETALHES do item direto da home, replicando o fluxo da grade:
' ShowDetailsScreen(<conteudo completo clonado>, <indice do item>). Acha o item no cache
' pelo id do card (a linha e um subconjunto ordenado do cache).
sub openHomeItem(rowNode as Object, col as Integer, cache as Object, kind as String)
    if rowNode = invalid or cache = invalid then return
    card = rowNode.getChild(col)
    if card = invalid or card.id = invalid then return
    targetId = "" + card.id

    idx = -1
    n = cache.getChildCount()
    for i = 0 to n - 1
        it = cache.getChild(i)
        if it <> invalid and ("" + it.id) = targetId
            idx = i
            exit for
        end if
    end for
    if idx < 0 then return

    if kind = "movie"
        m.global.contentType = "movie"
        m.global.titleSection = tr("movies")
        m.global.action = "get_vod_categories"
        m.global.items = "get_vod_streams"
        m.global.play = "/movie/" + m.global.user + "/" + m.global.pass + "/"
        ' Filme: abre os Detalhes (sinopse + favoritar + play), IGUAL a grade. Nao da pra
        ' "tocar direto": o player do filme precisa do container_extension que vem do
        ' get_vod_info (so obtido nos Detalhes). O loop ao tocar e do PORTAL (a aba de
        ' Filmes original tambem trava), nao da home.
        ShowDetailsScreen(cache.clone(true), idx)
    else
        m.global.contentType = "series"
        m.global.titleSection = tr("series")
        m.global.action = "get_series_categories"
        m.global.items = "get_series"
        m.global.play = "/series/" + m.global.user + "/" + m.global.pass + "/"
        ' Serie: abre os Detalhes (temporadas/episodios) — esse fluxo funciona.
        ShowDetailsScreen(cache.clone(true), idx)
    end if
end sub

sub stampMenuAccess()
    appName = m.global.config.appName
    nowText = CreateObject("roDateTime")
    nowText.Mark()
    regWrite("menuUpdated_live", nowText.AsDateString("short-date"), appName)
end sub

Sub OnMenuFocused(event as Object)
    grid = event.GetRoSGNode()
    if grid.content = invalid then return
    focusedItem = grid.content.getChild(event.GetData())
    if focusedItem = invalid then return

    getScene().FindNode("itemLabelMain1").text = focusedItem.shortdescriptionline1
    desc2 = ""
    if focusedItem.shortdescriptionline2 <> invalid then desc2 = focusedItem.shortdescriptionline2
    getScene().FindNode("itemLabelMain2").text = desc2
End Sub

sub OnMenuAction()
    actionId = m.MenuScreen.actionId
    if actionId = invalid or actionId = "" then return

    if actionId = "live" or actionId = "epg"
        markSectionUpdated("live")
        m.global.menuNavMode = ""
        openLiveSection()
    else if actionId = "movies"
        markSectionUpdated("movies")
        m.global.menuNavMode = ""
        openMoviesSection()
    else if actionId = "series"
        markSectionUpdated("series")
        m.global.menuNavMode = ""
        openSeriesSection()
    else if actionId = "catchup"
        markSectionUpdated("live")
        openCatchupSection()
    else if actionId = "search"
        m.global.menuNavMode = ""
        openSearchSection()
    else if actionId = "favorites"
        m.global.menuNavMode = ""
        openFavoritesSection()
    else if actionId = "multi"
        openMultiSection()
    else if actionId = "recordings"
        openRecordingsSection()
    else if actionId = "account"
        m.global.menuNavMode = ""
        openAccountSection()
    else if actionId = "settings"
        m.global.menuNavMode = ""
        openSettingsSection()
    else if actionId = "radio"
        m.global.menuNavMode = ""
        openRadioSearch()
    else if actionId = "reload"
        reloadLists()
    end if
end sub

' Recarregar: re-marca as secoes como atualizadas agora e limpa cache de busca.
' O conteudo (canais/filmes/series) ja e buscado fresco do servidor ao abrir cada
' secao, entao isso garante listas atualizadas + da o feedback pro usuario.
sub reloadLists()
    appName = m.global.config.appName
    dt = CreateObject("roDateTime")
    dt.Mark()
    nowStr = dt.AsDateString("short-date")
    regWrite("menuUpdated_live", nowStr, appName)
    regWrite("menuUpdated_movies", nowStr, appName)
    regWrite("menuUpdated_series", nowStr, appName)
    if m.global.hasField("cacheSearch") then m.global.cacheSearch = []
    ' Limpa o cache de sessao e re-aquece em background (pre-carrega de novo).
    m.cacheGrid_movie = invalid
    m.cacheGrid_series = invalid
    m.global.liveStreamsRaw = ""
    m.cacheLiveChannels = invalid
    ' Recarregar = baixar fresco: limpa tambem o cache de DISCO.
    clearDiskCache("saplayer_movie")
    clearDiskCache("saplayer_series")
    clearDiskCache("saplayer_live")
    preloadListings()

    m.reloadDlg = createObject("roSGNode", "Dialog")
    m.reloadDlg.title = tr("Listas atualizadas")
    m.reloadDlg.optionsDialog = true
    m.reloadDlg.message = tr("O conteudo sera recarregado do servidor ao abrir cada secao.")
    m.reloadDlg.buttons = [tr("OK")]
    m.reloadDlg.observeField("buttonSelected", "onReloadDlgClose")
    getScene().dialog = m.reloadDlg
end sub

sub onReloadDlgClose()
    if m.reloadDlg <> invalid then m.reloadDlg.close = true
end sub

sub OnMenuSelection(event)
    dispatchHeroAction(event.getData())
end sub

sub OnNavMenuSelection(event)
    dispatchNavAction(event.getData())
end sub

sub OnHeaderMenuSelection(event)
    dispatchHeaderAction(event.getData())
end sub

' heroGrid/navGrid/headerGrid sao NOS-FILHOS do MenuScreen (id=), nao campos de
' interface -> acessar via .heroGrid de fora da invalid. Usar findNode pega o no real.
sub dispatchHeroAction(index as Integer)
    if m.MenuScreen = invalid then return
    grid = m.MenuScreen.findNode("heroGrid")
    if grid = invalid or grid.content = invalid then return
    item = grid.content.getChild(index)
    if item <> invalid and item.actionId <> invalid
        m.MenuScreen.actionId = item.actionId
    end if
end sub

sub dispatchNavAction(index as Integer)
    if m.MenuScreen = invalid then return
    grid = m.MenuScreen.findNode("navGrid")
    if grid = invalid or grid.content = invalid then return
    item = grid.content.getChild(index)
    if item <> invalid and item.actionId <> invalid
        m.MenuScreen.actionId = item.actionId
    end if
end sub

sub dispatchHeaderAction(index as Integer)
    if m.MenuScreen = invalid then return
    grid = m.MenuScreen.findNode("headerGrid")
    if grid = invalid or grid.content = invalid then return
    item = grid.content.getChild(index)
    if item <> invalid and item.actionId <> invalid
        m.MenuScreen.actionId = item.actionId
    end if
end sub

sub markSectionUpdated(section as String)
    appName = m.global.config.appName
    dt = CreateObject("roDateTime")
    dt.Mark()
    regWrite("menuUpdated_" + section, dt.AsDateString("short-date"), appName)
end sub

sub openSearchSection()
    m.global.searchPreset = ""
    ShowSearchScreen()
end sub

sub openRadioSearch()
    m.global.searchPreset = "radio"
    ShowSearchScreen()
end sub

' Clicar em "Favoritos" no topo abre um submenu: Continuar Assistindo / Meus Favoritos.
sub openFavoritesSection()
    ' Overlay proprio (extends Group), nao Dialog nativo -> empilha no screen stack.
    m.favDlg = createObject("roSGNode", "FavoritesScreenDialog")
    m.favDlg.observeField("selected", "onFavMenuSelected")
    ShowScreen(m.favDlg)
    m.favDlg.setFocus(true)
end sub

sub onFavMenuSelected()
    idx = m.favDlg.selected
    ' Fecha o overlay (estava empilhado via ShowScreen).
    CloseScreen(m.favDlg)
    m.favDlg = invalid
    if idx = 0
        ' Continuar Assistindo (historico do que voce estava vendo)
        m.global.menuNavMode = "recordings"
        m.global.titleSection = tr("Continuar Assistindo")
        ShowMyListScreen()
        RunMyListTask()
    else if idx = 1
        ' Meus Favoritos (o que voce favoritou)
        m.global.menuNavMode = ""
        m.global.titleSection = tr("Meus Favoritos")
        ShowMyListScreen()
        RunMyListTask()
    else if idx = 2
        ' Limpar Recentes (apaga o historico de Continuar Assistindo)
        confirmClearRecents()
    end if
end sub

' Confirma e limpa TODO o historico de "Continuar Assistindo" (quando acumula muito).
sub confirmClearRecents()
    m.clearDlg = createObject("roSGNode", "Dialog")
    m.clearDlg.title = tr("Limpar Recentes")
    m.clearDlg.optionsDialog = true
    m.clearDlg.message = tr("Apagar todo o historico de Continuar Assistindo?")
    m.clearDlg.buttons = [tr("Sim, limpar"), tr("Cancelar")]
    m.clearDlg.observeField("buttonSelected", "onClearRecentsSelected")
    getScene().dialog = m.clearDlg
end sub

sub onClearRecentsSelected()
    idx = m.clearDlg.buttonSelected
    m.clearDlg.close = true
    if idx = 0
        regDelete("list", "ContinueWatching")
        m.clearDoneDlg = createObject("roSGNode", "Dialog")
        m.clearDoneDlg.title = tr("Pronto")
        m.clearDoneDlg.message = tr("Historico de recentes limpo.")
        m.clearDoneDlg.buttons = [tr("OK")]
        m.clearDoneDlg.observeField("buttonSelected", "onClearDoneClose")
        getScene().dialog = m.clearDoneDlg
    end if
end sub

sub onClearDoneClose()
    if m.clearDoneDlg <> invalid then m.clearDoneDlg.close = true
end sub

sub openRecordingsSection()
    m.global.menuNavMode = "recordings"
    m.global.titleSection = tr("Gravações")
    ShowMyListScreen()
    RunMyListTask()
end sub

sub openAccountSection()
    currDialog = createObject("roSGNode", "AccountScreenDialog")
    currDialog.id = "AccountScreen"
    currDialog.observeField("action", "onAccountAction")
    currDialog.observeField("closeMe", "onAccountClose")
    ' Overlay proprio (extends Group), nao Dialog -> empilha no screen stack.
    m.accountModal = currDialog
    ShowScreen(currDialog)
    ' Da foco ao overlay, senao os botoes (Sair da conta / Cancelar) nao respondem.
    currDialog.setFocus(true)
end sub

sub onAccountAction()
    if m.accountModal <> invalid and m.accountModal.action = "logout"
        ' Logout() ja limpa toda a screen stack (incluindo este overlay).
        Logout()
    end if
end sub

' Cancelar / BACK no overlay -> so fecha o modal e volta pro menu.
sub onAccountClose()
    if m.accountModal <> invalid
        CloseScreen(m.accountModal)
        m.accountModal = invalid
    end if
end sub

' Logout: LIMPA o registro no painel (libera a vaga), apaga credenciais locais, fecha TODAS
' as telas (pro Voltar nao revelar o menu) e mostra o login. Sem flag forceLogin -> o painel
' eh a fonte da verdade: se o MAC estiver cadastrado, o proximo boot auto-loga; se foi limpo
' (logout), o poll volta vazio e cai no login.
sub Logout()
    appName = m.global.config.appName
    ' Avisa o painel pra zerar o registro desse MAC, mas EM TASK (assincrono) -> o panelPost e
    ' sincrono (rede) e travava o app se chamado aqui na thread da cena.
    devId = m.global.rokuUniqueID
    if devId <> invalid and devId <> ""
        t = createObject("roSGNode", "PanelLogoutTask")
        t.deviceId = devId
        getScene().appendChild(t)   ' enraiza na cena pra nao ser coletado antes de terminar
        t.control = "run"
    end if
    regDelete("userTV", appName)
    regDelete("passTV", appName)
    regDelete("forceLogin", appName)   ' aposentado: painel manda agora
    if getScene().dialog <> invalid then getScene().dialog.close = true
    while m.screenStack.Count() > 0
        s = m.screenStack.Pop()
        if s <> invalid
            s.visible = false
            m.top.RemoveChild(s)
        end if
    end while
    ShowLoginScreen()
end sub

sub openLiveSection()
    m.global.contentType = "live"
    m.global.titleSection = tr("live")
    m.global.action = "get_live_categories"
    m.global.items = "get_live_streams"
    m.global.play = "/live/" + m.global.user + "/" + m.global.pass + "/"
    m.global.isAdult = false
    ShowTimeGridScreen()
    RunCategoryTask()
end sub

sub openCatchupSection()
    m.global.menuNavMode = "catchup"
    m.global.contentType = "live"
    m.global.titleSection = tr("Ver Anteriores")
    m.global.action = "get_live_categories"
    m.global.items = "get_live_streams"
    m.global.play = "/live/" + m.global.user + "/" + m.global.pass + "/"
    m.global.isAdult = false
    ShowTimeGridScreen()
    RunCategoryTask()
end sub

sub openMultiSection()
    m.global.menuNavMode = "multi"
    m.global.contentType = "live"
    m.global.titleSection = tr("Multi-Tela")
    m.global.action = "get_live_categories"
    m.global.items = "get_live_streams"
    m.global.play = "/live/" + m.global.user + "/" + m.global.pass + "/"
    m.global.isAdult = false
    ShowTimeGridScreen()
    RunCategoryTask()
end sub

sub openMoviesSection()
    m.global.contentType = "movie"
    m.global.titleSection = tr("movies")
    m.global.action = "get_vod_categories"
    m.global.items = "get_vod_streams"
    m.global.play = "/movie/" + m.global.user + "/" + m.global.pass + "/"
    ShowGridScreen()
    RunCategoryTask()
end sub

sub openSeriesSection()
    m.global.contentType = "series"
    m.global.titleSection = tr("series")
    m.global.action = "get_series_categories"
    m.global.items = "get_series"
    m.global.play = "/series/" + m.global.user + "/" + m.global.pass + "/"
    ShowGridScreen()
    RunCategoryTask()
end sub

sub openSettingsSection()
    lock = regread("lock", m.global.config.appName)
    ' Sem PIN definido (vazio) ou PIN padrao 0000 => abre direto, sem pedir nada.
    if lock = invalid or lock = "" or lock = "0000" then
        ShowSettingScreen()
    else
        m.look = createObject("roSGNode", "PinDialog")
        m.look.title = tr("Enter Pin")
        m.look.pinPad.secureMode = false
        m.look.pinPad.pinLength = "4"
        m.look.observeField("pin", "onVerifyAccess")
        m.look.setFocus(true)
        getScene().dialog = m.look
    end if
end sub

sub onVerifyAccess()
    if m.look.pin.len() = 4 then
        m.confirmPin = createObject("roSGNode", "PinTask")
        m.confirmPin.section = m.global.config.appName
        m.confirmPin.pin = m.look.pin
        m.confirmPin.observeField("state", "verifyAccess")
        m.confirmPin.control = "RUN"
    end if
end sub

sub verifyAccess()
    if m.confirmPin.state = "stop" then
        if m.confirmPin.result then
            getScene().dialog.close = true
            ShowSettingScreen()
        else
            m.look.title = tr("Incorrect Pin, try again")
            m.look.pin = ""
            m.look.setFocus(true)
        end if
    end if
end sub
