'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
sub Init()
    ' set the name of the function in the Task node component to be executed when the state field changes to RUN
    ' in our case this method executed after the following cmd: m.contentTask.control = "run"(see Init method in MainScene)
    m.top.functionName = "GetContent"
end sub

sub GetContent()
    ' request the content feed from the API
    http = NewHttp( ReadManifest().server_api + "/player_api.php?username=" + m.global.user +"&password=" + m.global.pass + "&action=" + m.global.action)
    rsp = http.GetToStringWithRetry()
    rootChildren = []
    json = ParseJson(rsp)
	if json <> invalid
        row = {}
        row.title = tr("New & Popular")
        row.children = json
        rootChildren.Push(row)
	end if  
    ' set up a root ContentNode to represent rowList on the GridScreen
    contentNode = CreateObject("roSGNode", "ContentNode")
    contentNode.Update({children: rootChildren}, true)
	m.top.content = contentNode
end sub

