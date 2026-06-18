sub init()
    mBind(["itemLabel", "group", "pillNormal", "pillSelected"])
    m.top.id = "markuplistitem"
	m.parent = m.top.getParent()
	m.parent.observeField("itemSelected", "onItemSelectedChanged")
	m.itemLabel.font = createFont(getTheme().boldFont, 26)
end sub

sub showcontent()
    itemcontent = m.top.itemContent
    m.itemlabel.text = itemcontent.title
	showfocus()
end sub

' Foco: realca a pilula azul e clareia o texto.
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
