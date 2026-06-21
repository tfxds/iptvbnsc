' Boot: faz poll por MAC no painel S.A Player.
'  - branding (logo/fundo/nome/tema) SEMPRE vem do painel
'  - auto-login SO quando ha portal real (urls != vazio)
'  - a lista de DNS do login vem do fluxo A (codigo), nunca da lista global do poll
function cargarConfigRemota() as Object
    ensureGlobalAssetFields()
    ' titulo/bienvenida nao entram no ensureGlobalAssetFields da source; garantir aqui
    if not m.global.hasField("titulo") then m.global.addField("titulo", "string", true)
    if not m.global.hasField("bienvenida") then m.global.addField("bienvenida", "string", true)
    ' Nome de exibicao padrao da marca (revendedor sobrescreve via app_name no applyPanelBranding)
    if m.global.titulo = invalid or m.global.titulo = "" then m.global.titulo = "Speed PlayerTech"

    deviceId = getStableDeviceId()
    poll = panelPoll(deviceId)
    configArray = []

    if poll <> invalid
        applyPanelBranding(poll)

        ' poll.urls = array de objetos {url, dns_id, username, password, type} p/ MAC cadastrado.
        ' Shape confirmado ao vivo 2026-06-08. Vazio => sem auto-login => tela de login.
        portal = poll.urls
        ' appName = namespace FIXO do registro (PIN/credenciais/preferencias).
        ' Tem que casar com o LoginTask ("S.A Player") senao auto-login/PIN quebram.
        ' O nome de exibicao (branding) fica em m.global.titulo, nao aqui.
        appName = "S.A Player"
        if portal <> invalid and GetInterface(portal, "ifArray") <> invalid and portal.Count() > 0
            for each u in portal
                serverBase = ""
                if Type(u) = "roAssociativeArray"
                    if u.dns_id <> invalid and Instr(1, u.dns_id, "://") > 0
                        serverBase = panelBaseFromUrl(u.dns_id)
                    else if u.url <> invalid and u.url <> ""
                        serverBase = panelBaseFromUrl(u.url)
                    end if
                    if serverBase <> ""
                        configArray.push({ serverURL: serverBase, appName: appName, version: "4.5", api_key: "46270abd00c39663cde5d450ff83cbb8" })
                        ' MAC cadastrado no painel (com user/pass) -> escreve as credenciais e o
                        ' app auto-loga (abre direto, sem pedir codigo/usuario/senha). O logout
                        ' agora LIMPA o painel (panelLogout), entao o poll volta vazio e nao re-loga
                        ' -> nao precisa mais da flag forceLogin (painel = fonte da verdade).
                        if u.username <> invalid and u.username <> "" and u.password <> invalid and u.password <> ""
                            regWrite("userTV", u.username, appName)
                            regWrite("passTV", u.password, appName)
                        end if
                    end if
                else if Type(u) = "roString" and u <> ""
                    configArray.push({ serverURL: panelBaseFromUrl(u), appName: appName, version: "4.5", api_key: "46270abd00c39663cde5d450ff83cbb8" })
                end if
            end for
        end if
    end if

    ' Fallback offline (poll falhou): assets S.A Player embutidos, sem auto-login.
    if poll = invalid
        applyGlobalAssetDefaults()
    end if

    return configArray
end function

function pollAppName(poll as Object) as String
    if poll.app_name <> invalid and poll.app_name <> "" then return poll.app_name
    return "S.A Player"
end function

' Mapeia os campos de branding do painel pros globais ja usados pelo app.
sub applyPanelBranding(poll as Object)
    version = mid(str(int(rnd(0) * 10000)), 2)

    if poll.img_logo <> invalid and poll.img_logo <> ""
        logoUrl = addCacheBuster(poll.img_logo, version)
        m.global.logo = logoUrl
        ' logologin NAO entra de proposito: a tela de login fica TRAVADA na marca Speed
        ' PlayerTech (so a home/menu usa a logo do revendedor). Decisao do Thiago 2026-06-17.
        m.global.logomenu = logoUrl
    end if

    if poll.img_bg <> invalid and poll.img_bg <> ""
        m.global.fondo = addCacheBuster(poll.img_bg, version)
    end if

    if poll.app_name <> invalid and poll.app_name <> ""
        m.global.titulo = poll.app_name
    end if
end sub

function invalidOrDefault(value) as String
    if value = invalid or value = "" then
        return ""
    else
        return value
    end if
end function

function pickTileUrl(json as Object, key as String, fallback as String) as String
    if json <> invalid and json[key] <> invalid and json[key] <> ""
        return json[key]
    end if
    return fallback
end function

function addCacheBuster(url as String, version as String) as String
    if url = invalid or url = "" then return ""
    if left(url, 6) = "pkg:/" then return url
    if instr(url, "?") > 0 then
        return url + "&v=" + version
    else
        return url + "?v=" + version
    end if
end function
