' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainScene.xml using relative path.

sub RunMyListTask()
    m.contentTask = CreateObject("roSGNode", "MyListLoaderTask") ' create task for feed retrieving
    ' observe content so we can know when feed content will be parsed
    m.contentTask.ObserveField("content", "OnMainContentLoaded")
    m.contentTask.control = "run" ' GetContent(see MainLoaderTask.brs) method is executed
    m.loadingIndicator.visible = true ' show loading indicator while content is loading
end sub

sub OnMainContentLoaded() ' invoked when content is ready to be used
    m.MyListScreen.SetFocus(true) ' set focus to GridScreen
    m.loadingIndicator.visible = false ' hide loading indicator because content was retrieved
    m.MyListScreen.content = m.contentTask.content ' populate GridScreen with content
    m.global.menuNavMode = ""
end sub