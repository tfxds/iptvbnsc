sub init()
    m.top.functionName = "runLogout"
end sub

sub runLogout()
    devId = m.top.deviceId
    if devId <> invalid and devId <> "" then panelLogout(devId)
end sub
