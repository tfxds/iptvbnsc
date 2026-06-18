sub Init()
    m.top.functionName = "runReload"
end sub

sub runReload()
    ' Mesma logica de config do boot (initGlobals): re-consulta o painel por MAC, atualiza
    ' branding, grava userTV/passTV no registro e remonta config_activa. Depois disso o
    ' ConfirmUserTask (rodado pela tela de login) valida e abre o menu se o MAC ja estiver
    ' cadastrado.
    configData = cargarConfigRemota()
    if configData = invalid then configData = []
    m.global.setField("config_activa", configData)

    configActiva = invalid
    if type(configData) = "roArray" and configData.Count() > 0 then configActiva = configData[0]
    if configActiva = invalid or type(configActiva) <> "roAssociativeArray"
        configActiva = { serverURL: "", appName: "S.A Player", version: "4.5", api_key: "46270abd00c39663cde5d450ff83cbb8" }
    end if
    m.global.config = configActiva

    m.top.done = true
end sub
