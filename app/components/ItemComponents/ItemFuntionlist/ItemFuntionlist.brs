' Copyright (c) 2019 Roku, Inc. All rights reserved.

sub Init()
    m.title = m.top.findNode("title")
    m.poster = m.top.findNode("poster")
	
end sub

sub OnContentSet( event as Object )
    content = event.GetData()
    if content <> invalid
        m.title.text = content.title
        m.poster.uri = content.icon
    end if
end sub



