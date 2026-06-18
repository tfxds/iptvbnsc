'*************************************************************
'** Roku Xtream-ALL for XoceUnder
'** Copyright (c)2024 XoceUnder.  All rights reserved.
Sub Init()
  baseGroupInit()
End Sub


Sub showBackNode()
  Dbg("showBackNode")
  if m.top.backNode <> invalid
    if m.top.backNode.hasField("show")
      m.top.backNode.show = true
    else
      m.top.backNode.setfocus(true)
    end if
  end if
end Sub
