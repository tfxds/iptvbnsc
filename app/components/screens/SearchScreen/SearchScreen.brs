sub init()
    mBind(["bgPoster", "lupa", "Box", "search_bar", "editBox", "searchKeyboard", "keyBox", "searchList", "noResultsLabel", "ListFilters", "spinner", "presentListAnimation", "presentKeyboardAnimation", "labelText"])
    applySceneBackground(getScene())

    m.fullWidth = getScreenSize().width
    m.fullHeight = getScreenSize().height

    m.bgPoster.width = m.fullWidth
    m.bgPoster.height = m.fullHeight

    m.Box.translation = [ (m.fullWidth - m.Box.boundingRect().width) / 2 , 50]
    m.editBox.translation = [ 120 , (m.search_bar.boundingRect().height - m.editBox.boundingRect().height) / 2]
    m.editBox.hintText = tr("Pesquisar...")
    m.noResultsLabel.translation = [ (m.Box.boundingRect().width - m.noResultsLabel.boundingRect().width) / 2 , 0]

    m.searchKeyboard.domain = "email"
    m.searchKeyboard.mode = "ABC123Lower"
    m.searchKeyboard.textEditBox.hintText = tr(" Search...")
    m.searchKeyboard.textEditBox.voiceEnabled = true
    m.searchKeyboard.textEditBox.active = true
    m.searchKeyboard.textEditBox.active = true

    m.spinner.poster.uri="pkg:/images/loader.png"
    m.spinner.poster.width="128"
    m.spinner.poster.height="128"
    m.spinner.translation = [ (m.fullWidth-128) / 2 , (m.fullHeight-128) / 2]

    m.currentFilter = 0 '0=LIVE,1=MOVIES,2=SERIES
    m.currentSelected = 0

    m.top.ObserveField("visible", "onVisibleChange")
    ' Ao VOLTAR do video/detalhe, o CloseScreen da foco a RAIZ do componente (m.top) e o
    ' foco fica preso (nenhum filho navegavel) -> a seta nao mexe o seletor (antes so destravava
    ' com OK+Voltar). Redireciona o foco pra lista (se houver resultados) ou pro campo de busca.
    m.top.observeField("focusedChild", "onRootFocusChanged")
    m.top.observeField("content", "onListContentChange")
    m.top.observeField("filterSelected", "onFilterSelected")
    m.top.observeField("filterItemFocused", "onFilterItemFocused")
    m.top.observeField("searching", "onStartSearch")
    m.top.observeField("showSpinner","OnShowSpinnerChange")

    m.searchKeyboard.ObserveField("text", "onSearchQuery")
    m.searchKeyboard.observeFieldScoped("keyClose", "KeybordHide")

    ' BUSCA UNIFICADA: nao usa mais os botoes canal/filme/serie. Esconde a barra de
    ' filtros; o resultado vem MISTURADO numa fileira so (SearchTask roda os 3 tipos).
    createFilters()
    m.ListFilters.visible = false
    m.filters = ["get_live_streams","get_vod_streams", "get_series"]
    m.top.currentFilter = "all"

    m.searchList.translation = [ 120 , 420 ]

    m.keyBox.width = m.searchKeyboard.boundingRect().width + 50
    m.keyBox.height = m.searchKeyboard.boundingRect().height + 50
    m.keyBox.translation = [(m.fullWidth-m.searchKeyboard.boundingRect().width) / 2, m.fullHeight - m.searchKeyboard.boundingRect().height * 1.3]

    m.searchKeyboard.translation = [25,25]
    m.global.cachesearch = invalid

end sub

' Foco preso na raiz (volta do video) -> manda pra lista de resultados (se houver) ou pro
' campo de busca. So age quando e a PROPRIA raiz que esta com foco (nao um filho).
sub onRootFocusChanged()
    if not m.top.hasFocus() then return
    if m.searchList <> invalid and m.searchList.content <> invalid and m.searchList.content.getChildCount() > 0
        m.searchList.setFocus(true)
    else
        m.editBox.setFocus(true)
        focusEditBox()
    end if
end sub

sub OnVisibleChange() ' invoked when searchList change visibility
    if m.top.visible = true
        applySearchPreset()
        ' Sem barra de filtros: ja abre com o teclado pra digitar na hora.
        if m.editBox.text = invalid or m.editBox.text = "" then KeybordShow()
    end if
end sub

sub applySearchPreset()
    if m.global = invalid or m.global.searchPreset = invalid then return
    preset = m.global.searchPreset
    if preset = "" then return

    m.searchKeyboard.text = preset
    m.editBox.text = preset
    m.global.searchPreset = ""

    if preset.len() > 2
        runUnifiedSearch(preset)
    end if
end sub

' Dispara a busca unificada (os 3 tipos numa fileira so). Centraliza a logica usada
' tanto ao digitar quanto no preset/searching.
sub runUnifiedSearch(term as String)
    if m.global.contentTask <> invalid
        m.global.contentTask.control = "stop"
    end if
    m.spinner.visible = true
    m.spinner.control = "start"
    m.global.contentTask = CreateObject("roSGNode", "SearchTask")
    m.global.contentTask.ObserveField("content", "onSearchRetrieved")
    m.global.contentTask.action = "all"
    m.global.contentTask.searchTerm = term
    m.global.contentTask.control = "run"
end sub

sub onSearchQuery(event as Object)
    m.editBox.text = event.GetData()
    cursorPosition = m.editBox.cursorPosition
    m.editBox.cursorPosition = cursorPosition + 1

    ' Para a busca anterior antes de comecar outra (digitacao rapida).
    if m.global.contentTask <> invalid
        m.global.contentTask.control = "stop"
    end if

    q = event.GetData()
    if q.len() > 2
        runUnifiedSearch(q)
    else
        m.spinner.visible = false
        m.spinner.control = "stop"
        m.top.content = invalid
        m.noResultsLabel.visible = false
    end if
end sub


sub onStartSearch(event)
    if event.getData()
        runUnifiedSearch(m.editBox.text)
    end if
end sub

sub onSearchRetrieved(event)
    m.top.content = invalid
    content = event.getData()

    if content.getChild(0) <> invalid
        if content.getChild(0).GetChildCount() > 0
            m.noResultsLabel.visible = false
            m.top.content = content
        else
            m.top.showSpinner = false
            m.noResultsLabel.text = tr("No search results were found.")
            m.noResultsLabel.visible = true
        end if
    else
        m.top.showSpinner = false
        m.noResultsLabel.text = tr("No search results were found.")
        m.noResultsLabel.visible = true
    end if
end sub


sub onListContentChange()
    m.spinner.visible = false
    m.spinner.control = "stop"
    m.searchList.visible = true
end sub

sub createFilters()
    data = CreateObject("roSGNode", "ContentNode")
    items = [
        { title: "canais", selected: true },
        { title: "filmes", selected: false },
        { title: "séries", selected: false }
    ]
    row = data.CreateChild("ContentNode")
    for each currentItem in items
        item = row.CreateChild("SearchFilterNode")
        item.labeltext = tr(currentItem.title)
        item.isselected = currentItem.selected
    end for
    m.ListFilters.content = data
end sub

sub onFilterSelected(event)
    ' Sem uso na busca unificada (barra de filtros escondida). Mantido por seguranca.
end sub

sub onFilterItemFocused(event)
    ' Sem uso na busca unificada (barra de filtros escondida). Mantido por seguranca.
end sub

sub search()
    m.searchKeyboard.text = m.editBox.text
    m.top.searching = true
end sub

sub focusEditBox()
    animate = m.editBox.isInFocusChain()
    m.editBox.active = "false"
    if not animate
        m.search_bar.uri = "pkg:/images/search/searchbar.png"
        return
    end if
    m.search_bar.uri = "pkg:/images/search/searchbar_focus.png"
    m.editBox.active = "true"
end sub

function KeybordShow()
    m.editBox.setFocus(false)
    m.keyBox.visible = "true"
    m.searchKeyboard.setFocus(true)
end function

function KeybordHide()
    m.keyBox.visible = "false"
    m.searchKeyboard.setFocus(false)
    m.editBox.setFocus(true)
    focusEditBox()
end function

sub OnShowSpinnerChange(event)
  if event.getData()
    m.spinner.visible = true
    m.spinner.control = "start"
  else
    m.spinner.visible = false
    m.spinner.control = "stop"
  end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    if press and m.top.isInFocusChain()
        ' Navegacao SEM a barra de filtros: editBox <-> searchList direto.
        if key = "up"
            if m.searchList.isInFocusChain()
                m.searchList.setFocus(false)
                m.editBox.setFocus(true)
                focusEditBox()
            end if
            handled = true
        else if key = "down"
            if m.editBox.isInFocusChain()
                m.editBox.setFocus(false)
                m.searchList.setFocus(true)
            end if
            handled = true
        else if key = "OK" then
            ' Abre o teclado a partir do editBox ou da lista.
            KeybordShow()
            handled = true
        else if key = "back"
            if m.searchKeyboard.isInFocusChain()
                KeybordHide()
                handled = true
            end if
        end if
    end if
    return handled
end function
