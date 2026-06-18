'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub Init()
	mBind(["markupGrid", "groupSection", "contentLabel"])
	getScene().FindNode("overhang").visible = false
    applySceneBackground(getScene())

    m.top.ObserveField("visible", "onVisibleChange")
	m.groupSection.translation = [(getScreenSize().width - 240) - m.contentLabel.boundingRect().height , 980]
end sub

sub OnVisibleChange()
    if m.top.visible = true and m.top.content <> invalid
        m.markupGrid.SetFocus(true)
    end if
end sub
