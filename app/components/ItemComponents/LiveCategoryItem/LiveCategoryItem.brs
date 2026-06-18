sub init()
    mBind(["itemLabel", "group", "pillNormal", "pillSelected", "countLabel"])
    m.top.id = "livecategoryitem"
    m.parent = m.top.getParent()
    if m.parent <> invalid then m.parent.observeField("itemSelected", "onItemSelectedChanged")
end sub

sub showcontent()
    itemcontent = m.top.itemContent
    if itemcontent <> invalid
        m.itemlabel.text = itemcontent.title
        ' Contador no label proprio a direita (campo catcount).
        if m.countLabel <> invalid
            if itemcontent.catcount <> invalid then m.countLabel.text = itemcontent.catcount else m.countLabel.text = ""
        end if
    end if
    showfocus()
end sub

' Foco: realca a pilula azul e clareia o texto (igual Filmes/Series).
sub showfocus()
    if m.top.focusPercent > 0.3 then
        m.pillSelected.opacity = m.top.focusPercent
        m.itemlabel.color = "0xFFFFFFFF"
    else
        m.pillSelected.opacity = 0
        m.itemlabel.color = "0xc8dce8ff"
    end if
end sub

' Categoria ativa (selecionada): mantem destaque azul mesmo sem foco.
sub onItemSelectedChanged()
    if m.parent = invalid then return
    itemSelected = m.parent.itemSelected
    if m.top.index = itemSelected then
        if m.top.focusPercent <= 0.3 then m.pillSelected.opacity = 0.85
        m.itemlabel.color = "0xFFFFFFFF"
    else
        if m.top.focusPercent <= 0.3 then
            m.pillSelected.opacity = 0
            m.itemlabel.color = "0xc8dce8ff"
        end if
    end if
end sub
