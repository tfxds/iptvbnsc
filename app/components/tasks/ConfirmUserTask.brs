sub init()
    m.top.functionName = "go"
end sub
sub go()
    good = check_user()
    if good <> invalid then
        m.top.auth = good.user_info.auth.ToStr()  ' Convertir auth a cadena para comparación
        if m.top.auth = "1" then
            ' Autenticación exitosa, continuar con el proceso
            m.top.message = good.user_info.message
            m.top.status = good.user_info.status
            m.global.max_connections = good.user_info.max_connections
            m.global.active_cons = good.user_info.active_cons
            m.global.user = good.user_info.username
            m.global.pass = good.user_info.password
            m.global.expire = "Never"
            if good.user_info.exp_date <> invalid then
                m.global.expire = good.user_info.exp_date.toInt()
            end if
            m.global.timeServer = good.server_info.timestamp_now
        else
            ' Si auth es "0", não autenticou
        end if
    else
        Dbg("❌ Eliminated account - no servidor válido")

        ' Validación para no explotar si no se encontró servidor
        appName = ""
        if m.global.config <> invalid and m.global.config.appName <> invalid
            appName = m.global.config.appName
        end if

        if appName <> ""
            regDelete("userTV", appName)
            regDelete("passTV", appName)
            regDelete("lock", appName)
            regDelete("channelCategory", appName)
            regDelete("moviesCategory", appName)
            regDelete("seriesCategory", appName)
            regDelete("live", appName)
            regDelete("movie", appName)
            regDelete("series", appName)
            regDelete("sort", appName)
            regDelete("streamFormat", appName)
        else
            Dbg("⚠️ No se pudo determinar appName para eliminar registros.")
        end if
    end if
end sub
function check_user() As Object
    ' Recorremos cada servidor del array

    ' Guarda: no boot config_activa pode ainda nao existir/estar vazio (MAC nao
    ' cadastrado ou corrida com initGlobals). Sem isso, "for each" em invalid trava o app.
    if m.global.config_activa = invalid or type(m.global.config_activa) <> "roArray" or m.global.config_activa.Count() = 0
        return invalid
    end if

    for each cfg in m.global.config_activa
        user = regread("userTV", cfg.appName)
        pass = regread("passTV", cfg.appName)

        if user <> invalid and pass <> invalid and user <> "" and pass <> "" then
            url = cfg.serverURL + "/player_api.php?username=" + user.Escape() + "&password=" + pass.Escape()
            http = NewHttp(url)
            response = http.GetToStringWithRetry()

            if len(response) > 0 and (Left(response, 1) = "{" or Left(response, 1) = "[")
                json = ParseJson(response)

                if json.user_info <> invalid then
                    if json.user_info.auth = 1

                        ' Guardar servidor válido
                        m.global.user = user
                        m.global.pass = pass
                        m.global.config = config(cfg)
                        return json
                    end if
                end if
            end if
        else
        end if
    end for
    return invalid
end function


function config(cfg)
  return {
        "serverURL": cfg.serverURL,
        "appName": cfg.appName,
        "api_key": "46270abd00c39663cde5d450ff83cbb8",
        "version": "4.5"
        }
end function