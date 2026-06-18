function getDefaultAssets() as Object
    return {
        logo: "pkg:/images/speedtech_logo.png",
        fondo: "pkg:/images/speedtech_bg.png",
        logomenu: "pkg:/images/speedtech_logo.png",
        logologin: "pkg:/images/speedtech_login.png",
        tileLive: "pkg:/images/bg_dark.png",
        tileMovies: "pkg:/images/background.jpg",
        tileSeries: "pkg:/images/bg_dark.png",
        menuTile: "pkg:/images/bg_dark.png",
        channel: "pkg:/images/channel.png",
        loader: "pkg:/images/loader.png",
        splash: "pkg:/images/splash-screen_fhd.jpg"
    }
end function

function isValidRemoteAssetUrl(url as String) as Boolean
    if url = invalid or url = "" then return false
    lower = lcase(url)
    if left(lower, 4) <> "http" then return false
    if right(lower, 8) = "/images/" then return false
    if instr(lower, "/images/?") > 0 then return false
    if instr(lower, "/images/&") > 0 then return false
    return true
end function

function resolveAssetUrl(remoteUrl as String, localFallback as String) as String
    if isValidRemoteAssetUrl(remoteUrl) then return remoteUrl
    if localFallback <> invalid and localFallback <> "" then return localFallback
    return getDefaultAssets().fondo
end function

function getGlobalLogo() as String
    return resolveAssetUrl(m.global.logo, getDefaultAssets().logo)
end function

function getGlobalFondo() as String
    return resolveAssetUrl(m.global.fondo, getDefaultAssets().fondo)
end function

function getGlobalLogoMenu() as String
    return resolveAssetUrl(m.global.logomenu, getDefaultAssets().logomenu)
end function

function getGlobalLogoLogin() as String
    return resolveAssetUrl(m.global.logologin, getDefaultAssets().logologin)
end function

function getGlobalTileLive() as String
    defs = getDefaultAssets()
    url = m.global.tileLive
    remote = resolveAssetUrl(url, defs.tileLive)
    if remote = defs.tileLive and isValidRemoteAssetUrl(m.global.fondo) then return m.global.fondo
    return remote
end function

function getGlobalTileMovies() as String
    defs = getDefaultAssets()
    url = m.global.tileMovies
    remote = resolveAssetUrl(url, defs.tileMovies)
    if remote = defs.tileMovies and isValidRemoteAssetUrl(m.global.logologin) then return m.global.logologin
    return remote
end function

function getGlobalTileSeries() as String
    defs = getDefaultAssets()
    url = m.global.tileSeries
    remote = resolveAssetUrl(url, defs.tileSeries)
    if remote = defs.tileSeries and isValidRemoteAssetUrl(m.global.logomenu) then return m.global.logomenu
    return remote
end function

sub ensureGlobalAssetFields()
    if m.global = invalid then return
    fieldList = ["logo", "fondo", "logomenu", "logologin", "tileLive", "tileMovies", "tileSeries"]
    for each fieldName in fieldList
        if not m.global.hasField(fieldName)
            m.global.addField(fieldName, "string", true)
            m.global[fieldName] = ""
        end if
    end for
end sub

sub applyGlobalAssetDefaults()
    if m.global = invalid then return
    ensureGlobalAssetFields()
    defs = getDefaultAssets()

    m.global.logo = resolveAssetUrl(m.global.logo, defs.logo)
    m.global.fondo = resolveAssetUrl(m.global.fondo, defs.fondo)
    m.global.logomenu = resolveAssetUrl(m.global.logomenu, defs.logomenu)
    m.global.logologin = resolveAssetUrl(m.global.logologin, defs.logologin)

    rawLive = m.global.tileLive
    m.global.tileLive = resolveAssetUrl(rawLive, defs.tileLive)
    if m.global.tileLive = defs.tileLive and isValidRemoteAssetUrl(m.global.fondo)
        m.global.tileLive = m.global.fondo
    end if

    rawMovies = m.global.tileMovies
    m.global.tileMovies = resolveAssetUrl(rawMovies, defs.tileMovies)
    if m.global.tileMovies = defs.tileMovies and isValidRemoteAssetUrl(m.global.logologin)
        m.global.tileMovies = m.global.logologin
    else if m.global.tileMovies = defs.tileMovies and isValidRemoteAssetUrl(m.global.fondo)
        m.global.tileMovies = m.global.fondo
    end if

    rawSeries = m.global.tileSeries
    m.global.tileSeries = resolveAssetUrl(rawSeries, defs.tileSeries)
    if m.global.tileSeries = defs.tileSeries and isValidRemoteAssetUrl(m.global.logomenu)
        m.global.tileSeries = m.global.logomenu
    else if m.global.tileSeries = defs.tileSeries and isValidRemoteAssetUrl(m.global.fondo)
        m.global.tileSeries = m.global.fondo
    end if
end sub

sub applySceneBackground(scene as Object)
    if scene = invalid then return
    scene.backgroundColor = getTheme().backgroundColor
    scene.backgroundUri = getGlobalFondo()
end sub
