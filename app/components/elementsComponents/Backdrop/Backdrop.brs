'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
sub init()
    mBind(["poster", "maskBackground"])

    m.poster.loadWidth = getScreenSize().width
    m.poster.loadHeight = getScreenSize().height
    m.poster.width = getScreenSize().width
    m.poster.height = getScreenSize().height
    m.maskBackground.width = getScreenSize().width
    m.maskBackground.height = getScreenSize().height
end sub

sub onColorChanged(event)
    m.maskBackground.color = event.getData()
end sub
