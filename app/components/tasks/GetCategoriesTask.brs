'*************************************************************
'** Roku Xtream-ALL for XoceUnder                            *
'** Copyright (c)2024 XoceUnder.  All rights reserved.       *
'*************************************************************
sub Init()
    ' set the name of the function in the Task node component to be executed when the state field changes to RUN
    ' in our case this method executed after the following cmd: m.contentTask.control = "run"(see Init method in MainScene)
    m.top.functionName = "GetCategories"
end sub

sub GetCategories()
    ' request the content feed from the API
    http = NewHttp( m.global.config.serverURL + "/player_api.php?username=" + m.global.user +"&password=" + m.global.pass + "&action=" + m.global.action)
    categoriesResponse = http.GetToStringWithRetry()
    m.top.categories = CategoriesFactory().BuildCategoriesObject(categoriesResponse)
end sub