'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
sub RunCategoryTask()
    m.contentTask = CreateObject("roSGNode", "CategoryLoaderTask") ' create task for feed retrieving
    ' observe content so we can know when feed content will be parsed
    m.contentTask.ObserveField("content", "OnMainCategoryLoaded")
    m.contentTask.control = "run" ' GetContent(see CategoryLoaderTask.brs) method is executed
    m.loadingIndicator.visible = true ' show loading indicator while content is loading
end sub

sub OnMainCategoryLoaded() ' invoked when content is ready to be used
    m.GridScreen.SetFocus(true) ' set focus to GridScreen
    m.loadingIndicator.visible = false ' hide loading indicator because content was retrieved
    m.GridScreen.category = m.contentTask.content ' populate GridScreen with content

    if m.global.contentType = "live" and m.global.menuNavMode <> invalid and m.global.menuNavMode <> ""
        handleLiveMenuNavMode(m.contentTask.content)
        return
    end if

    ' Ja carrega a 1a categoria (sem PIN) ao ENTRAR, pra mostrar conteudo na hora
    ' (Filmes/Series e tambem os canais da TV) — antes ficava vazio ate escolher pasta.
    autoLoadFirstCategory(m.contentTask.content)
end sub

sub autoLoadFirstCategory(cats as Object)
    if m.global.contentType = "live"
        ' TV: carrega os canais da 1a categoria SEM PIN. Mantem o loading na tela
        ' (carregar todos os canais demora) pra nao parecer travado.
        if cats = invalid or cats.GetChildCount() = 0 then return
        for i = 0 to cats.GetChildCount() - 1
            c = cats.GetChild(i)
            if c.look = 0
                m.loadingIndicator.visible = true
                loadLiveCategoryById(c.id)
                return
            end if
        end for
    else
        ' CACHE de sessao: se ja carregamos o "Todos" deste tipo, mostra INSTANTANEO.
        ckey = "cacheGrid_" + m.global.contentType
        if m[ckey] <> invalid and m.GridScreen <> invalid and m.GridScreen.subtype() = "GridScreen"
            fl = getScene().FindNode("filteredList")
            if fl <> invalid then fl.visible = false
            mg = getScene().FindNode("markupGrid")
            if mg <> invalid then mg.visible = true
            m.GridScreen.content = invalid
            m.GridScreen.searchContent = invalid
            m.GridScreen.SetFocus(true)
            m.GridScreen.content = m[ckey]
            m.loadingIndicator.visible = false
            return
        end if
        ' Filmes/Series: carrega TODOS de uma vez (category_id vazio = tudo, sem pasta
        ' padrao), na ORDEM DO SERVIDOR. O usuario filtra por categoria depois se quiser.
        m.movieTask = CreateObject("roSGNode", "MainLoaderTask")
        m.movieTask.ObserveField("content", "OnMovieContentLoaded")
        m.movieTask.category_id = ""
        m.movieTask.category_title = m.global.titleSection
        m.movieTask.control = "run"
        m.loadingIndicator.visible = true
    end if
end sub

sub handleLiveMenuNavMode(categories as Object)
    mode = m.global.menuNavMode
    m.global.menuNavMode = ""

    if categories = invalid or categories.GetChildCount() = 0 then return

    catId = categories.GetChild(0).id
    if mode = "catchup" and categories.GetChildCount() > 1
        catId = categories.GetChild(1).id
    end if

    m.liveNavMode = mode
    loadLiveCategoryById(catId)
end sub