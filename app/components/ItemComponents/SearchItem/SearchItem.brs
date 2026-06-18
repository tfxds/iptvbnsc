' Copyright (c) 2020 Roku, Inc. All rights reserved.

sub OnContentSet() ' invoked when item metadata retrieved
    content = m.top.itemContent
    ' set poster uri if content is valid
    if content <> invalid
        m.top.FindNode("poster").uri = content.hdPosterURL
		 m.top.FindNode("posterText").text = content.title
    end if
end sub

function onFocusChange(event as object) as void
    focused = event.getData()
    m.top.FindNode("focusRing").visible = focused
    if focused
        m.top.FindNode("posterText").repeatCount = -1
    else
        m.top.FindNode("posterText").repeatCount = 0
    end if
end function
