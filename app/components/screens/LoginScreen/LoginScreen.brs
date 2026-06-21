sub init()
    ' Binding de elementos: codigo do revendedor + usuario + senha + display de MAC
    mBind(["LoginBox", "grp", "label", "codeTextEditBox", "userTextEditBox", "passTextEditBox", "loginButton", "loginBtnLabel",
           "keyBox", "codeKeyboard", "userKeyboard", "passKeyboard", "showAnimation", "hideAnimation", "showKey",
           "hideKey", "codeEditBox", "userEditBox", "passEditBox", "logoImage", "welcomeText", "footerText",
           "codeBox", "activationCodeLabel", "codeStatusLabel", "codeInstructionLabel", "bgLogin", "taglineText",
           "reloadButton", "reloadBtnLabel"])

    m.fullWidth = getScreenSize().width
    m.fullHeight = getScreenSize().height

    m.rectWidth = m.fullWidth * 0.5 * 0.75
    m.rectHeight = m.fullHeight * 0.5 * 0.75

    ' Grupo dos campos sobe (era 100 -> transbordava pra baixo do card) e o card ganha mais
    ' altura de folga, pra usuario/senha/ENTRAR ficarem DENTRO da caixa de vidro.
    m.grp.translation = [0, 48]

    m.rightMargin = 200
    m.LoginBox.translation = [m.fullWidth - m.rectWidth - m.rightMargin, m.fullHeight/2 - m.rectHeight/2]
    m.LoginBox.width = m.rectWidth
    m.LoginBox.height = m.rectHeight + 130

    m.baseFontSize = (m.rectHeight / 8) * 0.75 * 1.75
    ' Frase no TOPO centralizado (pedido do Thiago). Wordmark "Speed PlayerTech" removido:
    ' a logo transparente ja tem o nome escrito.
    m.welcomeText.text = "Sua diversão começa aqui"
    m.welcomeText.fontSize = 42
    m.welcomeText.horizOrigin = "center"
    m.welcomeText.translation = [m.fullWidth / 2, 70]
    m.welcomeY = 70
    m.welcomeOriginalX = m.fullWidth / 2
    m.welcomeMovedX = m.fullWidth / 2

    ' "Seu cinema, ao vivo, na sua TV." removida (pedido do Thiago)
    m.taglineText.text = ""

    m.footerText.text = loginTitulo() + "   •   build " + ReadManifest().build_version
    m.footerText.fontSize = m.baseFontSize * 0.5
    m.footerText.color = "#FFFFFF"
    m.footerText.width = m.fullWidth
    m.footerText.height = 10
    m.footerText.translation = [1000, m.fullHeight - 80]
    m.footerText.visible = true

    ' Logo Speed PlayerTech TRANSPARENTE (wide 1024x354) — sem escrita ao lado.
    ' Centralizada na metade esquerda (onde fica o card de login na direita).
    m.logoWidth = 700
    m.logoHeight = 242
    m.logoImage.width = m.logoWidth
    m.logoImage.height = m.logoHeight
    m.logoImage.translation = [140, m.fullHeight/2 - 250]

    m.label.fontSize = m.baseFontSize
    m.label.translation = [m.rectWidth / 2 - m.label.boundingRect().width / 2, 0]

    m.label.text = "Acesse sua conta"
    m.codeTextEditBox.hintText = " Código do revendedor"
    m.userTextEditBox.hintText = " Usuário"
    m.passTextEditBox.hintText = " Senha"
    ' texto do botao agora e o Label loginBtnLabel (centralizado), setado junto com o botao abaixo

    fieldW = (m.fullWidth / 2.5) * 0.75
    ' Altura do campo ATRELADA ao card (deterministica), nao ao boundingRect da fonte do
    ' sistema (que na TV vinha mais alto e inchava os campos -> transbordavam pra fora do card).
    btnH = m.rectHeight * 0.155

    m.codeTextEditBox.width = fieldW
    m.codeTextEditBox.height = btnH
    ' Texto encostado a ESQUERDA (recuo fixo) dentro da caixa, nao centralizado.
    m.codeTextEditBox.translation = [24, btnH * 0.18]
    m.codeTextEditBox.maxTextLength = 20
    m.codeEditBox.width = fieldW
    m.codeEditBox.height = btnH
    ' Centraliza a CAIXA pela largura REAL (fieldW), nao pelo boundingRect do texto (que e menor
    ' -> empurrava a caixa pra direita e o texto parecia centralizado). Texto fica com recuo 24.
    m.codeEditBox.translation = [(m.rectWidth - fieldW) / 2, 0]

    m.userTextEditBox.width  = fieldW
    m.userTextEditBox.height  = btnH
    m.userTextEditBox.translation = [24, btnH * 0.18]
    m.userTextEditBox.maxTextLength  = 20

    m.userEditBox.width  = fieldW
    m.userEditBox.height  = btnH
    m.userEditBox.translation = [(m.rectWidth - fieldW) / 2, 0]

    m.passTextEditBox.width  = fieldW
    m.passTextEditBox.height  = btnH
    m.passTextEditBox.translation = [24, btnH * 0.18]
    m.passTextEditBox.maxTextLength  = 20

    m.passEditBox.width  = fieldW
    m.passEditBox.height  = btnH
    m.passEditBox.translation = [(m.rectWidth - fieldW) / 2, 0]

    btnW = (m.fullWidth / 2.5) * 0.6
    m.loginButton.minWidth  = btnW
    m.loginButton.height = m.loginButton.boundingRect().height * 0.8
    ' Centraliza o BOTAO pela largura REAL (minWidth), nao pelo boundingRect do texto -> antes a
    ' caixa do botao saia pra direita e o "ENTRAR" parecia desalinhado a direita.
    m.loginButton.translation = [(m.rectWidth - btnW) / 2, 0]
    ' Label "ENTRAR" cobrindo o botao inteiro, centralizado (Label TEM horizAlign; o button nao).
    m.loginBtnLabel.width = btnW
    m.loginBtnLabel.height = m.loginButton.height
    m.loginBtnLabel.translation = [0, 0]
    m.loginBtnLabel.text = tr("ENTRAR")

    m.keyBox.width = getScreenSize().width
    m.keyBox.height = m.userKeyboard.boundingRect().height + 50
    m.keyBox.translation = [0, m.fullHeight]

    m.codeKeyboard.textEditBox.voiceEnabled = true
    m.codeKeyboard.translation = [ (m.keyBox.width - m.codeKeyboard.boundingRect().width) / 2, (m.keyBox.height - m.codeKeyboard.boundingRect().height) - 50 / 2 ]

    m.userKeyboard.textEditBox.voiceEnabled = true
    m.userKeyboard.translation = [ (m.keyBox.width - m.userKeyboard.boundingRect().width) / 2, (m.keyBox.height - m.userKeyboard.boundingRect().height) - 50 / 2 ]

    m.passKeyboard.textEditBox.voiceEnabled = true
    m.passKeyboard.translation = [ (m.keyBox.width - m.passKeyboard.boundingRect().width) / 2, (m.keyBox.height - m.passKeyboard.boundingRect().height) - 50 / 2 ]

    m.codeTextEditBox.observeField("focusedChild", "onFocusChain")
    m.userTextEditBox.observeField("focusedChild", "onFocusChain")
    m.passTextEditBox.observeField("focusedChild", "onFocusChain")

    m.codeKeyboard.observeFieldScoped("continue", "doNext")
    m.codeKeyboard.observeFieldScoped("left", "doLeft")
    m.codeKeyboard.observeFieldScoped("right", "doRight")
    m.codeKeyboard.observeField("focusedChild", "onFocusChain")

    m.userKeyboard.observeFieldScoped("continue", "doNext")
    m.userKeyboard.observeFieldScoped("left", "doLeft")
    m.userKeyboard.observeFieldScoped("right", "doRight")
    m.userKeyboard.observeField("focusedChild", "onFocusChain")

    m.passKeyboard.observeFieldScoped("continue", "doNext")
    m.passKeyboard.observeFieldScoped("left", "doLeft")
    m.passKeyboard.observeFieldScoped("right", "doRight")
    m.passKeyboard.observeField("focusedChild", "onFocusChain")

    m.loginButton.observeField("buttonSelected", "onValidateLogin")
    m.codeKeyboard.ObserveField("text", "OnKeyboardTextChanged")
    m.userKeyboard.ObserveField("text", "OnKeyboardTextChanged")
    m.passKeyboard.ObserveField("text", "OnKeyboardTextChanged")

    m.validateLogin = createObject("roSGNode", "LoginTask")
    m.validateLogin.observeField("state", "validateLoginDone")

    m.currAddressPart = 0
    m.codeTextEditBox.setFocus(true)

    ' ========== DISPLAY DO MAC (cadastro pelo revendedor) ==========
    m.codeBox.visible = true
    mac = m.global.deviceMac
    if mac = invalid or mac = "" then
        mac = panelDeviceMac(getStableDeviceId())
    end if
    m.activationCodeLabel.text = mac
    m.codeStatusLabel.text = ""

    ' Botao "Recarregar" (re-poll do painel por MAC sem fechar o app)
    rbW = 460
    m.reloadButton.minWidth = rbW
    m.reloadButton.height = m.reloadButton.boundingRect().height * 0.8
    m.reloadBtnLabel.width = rbW
    m.reloadBtnLabel.height = m.reloadButton.height
    m.reloadButton.observeField("buttonSelected", "onReload")

    setupLoginAssets()
end sub

' ========== RECARREGAR (auto-login pos-cadastro do MAC, sem fechar o app) ==========
sub onReload()
    m.codeStatusLabel.color = "0xCCCCCC"
    m.codeStatusLabel.text = tr("Recarregando...")
    m.busyDialog = createObject("roSGNode", "ProgressDialog")
    getScene().dialog = m.busyDialog
    m.reloadTask = createObject("roSGNode", "ReloadConfigTask")
    m.reloadTask.observeField("done", "onReloadDone")
    m.reloadTask.control = "run"
end sub

sub onReloadDone()
    ' re-poll terminou -> valida as credenciais (igual ao boot)
    m.reloadConfirm = createObject("roSGNode", "ConfirmUserTask")
    m.reloadConfirm.observeField("state", "onReloadConfirm")
    m.reloadConfirm.control = "RUN"
end sub

sub onReloadConfirm()
    if m.reloadConfirm.state = "stop"
        if m.busyDialog <> invalid then m.busyDialog.close = true
        if m.reloadConfirm.auth = "1"
            ' MAC cadastrado -> navega pro menu pela MESMA maquina do login normal
            ' (MainScene observa "status" -> LoginDone -> success -> ShowLoginMenuScreen)
            m.top.status = m.reloadConfirm.status
        else
            m.codeStatusLabel.color = "0xFF5555"
            m.codeStatusLabel.text = tr("MAC ainda nao cadastrado. Peca ao revendedor e toque em Recarregar de novo.")
        end if
    end if
end sub

sub setupLoginAssets()
    applySceneBackground(getScene())
    ' Fundo proprio do login: usa o fundo do revendedor se houver, senao o padrao S.A Player.
    if m.bgLogin <> invalid
        m.bgLogin.width = getScreenSize().width
        m.bgLogin.height = getScreenSize().height
        ' Fundo do login = padrao da marca (bg.png), MAS segue o revendedor quando ele cadastra
        ' um BG no painel (igual a logo). getGlobalFondo = m.global.fondo (revendedor) ou default.
        m.bgLogin.uri = getGlobalFondo()
    end if
    ' Logo Speed PlayerTech TRANSPARENTE (wide), nao a do painel (login = marca fixa)
    m.logoImage.uri = "pkg:/images/speedtech_logo.png"
end sub

' Nome do app: FIXO "Speed PlayerTech" (decisao do Thiago — nao usar o nome do painel).
function loginTitulo() as String
    return "Speed PlayerTech"
end function

' ========== NAVEGACAO (codigo -> usuario -> senha -> login) ==========

sub doLeft()
    if m.codeKeyboard.isInFocusChain() then
        m.codeTextEditBox.cursorPosition = m.codeTextEditBox.cursorPosition - 1
    elseif m.userKeyboard.isInFocusChain() then
        m.userTextEditBox.cursorPosition = m.userTextEditBox.cursorPosition - 1
    elseif m.passKeyboard.isInFocusChain()
        m.passTextEditBox.cursorPosition = m.passTextEditBox.cursorPosition - 1
    end if
end sub

sub doRight()
    if m.codeKeyboard.isInFocusChain() then
        m.codeTextEditBox.cursorPosition = m.codeTextEditBox.cursorPosition + 1
    elseif m.userKeyboard.isInFocusChain() then
        m.userTextEditBox.cursorPosition = m.userTextEditBox.cursorPosition + 1
    elseif m.passKeyboard.isInFocusChain()
        m.passTextEditBox.cursorPosition = m.passTextEditBox.cursorPosition + 1
    end if
end sub

sub doNext()
    m.currAddressPart = m.currAddressPart + 1
    updateAddressPart()
end sub

sub doPrev()
    m.currAddressPart = m.currAddressPart - 1
    updateAddressPart()
end sub

sub hideAllInputKeyboards()
    m.codeTextEditBox.active = "false"
    m.codeTextEditBox.setFocus(false)
    m.codeKeyboard.setFocus(false)
    m.codeKeyboard.visible = "false"
    m.userTextEditBox.active = "false"
    m.userTextEditBox.setFocus(false)
    m.userKeyboard.setFocus(false)
    m.userKeyboard.visible = "false"
    m.passTextEditBox.active = "false"
    m.passTextEditBox.setFocus(false)
    m.passKeyboard.setFocus(false)
    m.passKeyboard.visible = "false"
end sub

sub updateAddressPart()
    if m.currAddressPart = 0
        hideAllInputKeyboards()
        m.codeTextEditBox.active = "true"
        m.codeTextEditBox.setFocus(true)
        m.codeKeyboard.setFocus(true)
        m.codeKeyboard.visible = "true"
        m.keyboard = m.codeKeyboard
        m.keyboard.mode = "NameLower"
        m.stringToUpdate = m.codeTextEditBox
        m.keyboard.domain = "alphanumeric"
    else if m.currAddressPart = 1
        hideAllInputKeyboards()
        m.userTextEditBox.active = "true"
        m.userTextEditBox.setFocus(true)
        m.userKeyboard.setFocus(true)
        m.userKeyboard.visible = "true"
        m.keyboard = m.userKeyboard
        m.keyboard.mode = "NameLower"
        m.stringToUpdate = m.userTextEditBox
        m.keyboard.domain = "alphanumeric"
    else if m.currAddressPart = 2
        hideAllInputKeyboards()
        m.passTextEditBox.active = "true"
        m.passTextEditBox.setFocus(true)
        m.passKeyboard.setFocus(true)
        m.passKeyboard.visible = "true"
        m.keyboard = m.passKeyboard
        m.keyboard.mode = "FullLower"
        m.stringToUpdate = m.passTextEditBox
        m.keyboard.domain = "alphanumeric"
    else if m.currAddressPart >= 3
        hideAllInputKeyboards()
        KeybordHide()
        m.loginButton.setFocus(true)
        return
    end if

    m.keyboard.text = m.stringToUpdate.text
    m.keyboard.textEditBox.cursorPosition = m.keyboard.text.Len()
    m.keyboard.keyGrid.jumpToKey = [ 0, 0, 0 ]
end sub

sub OnKeyboardTextChanged(event as Object)
    if m.codeKeyboard.isInFocusChain() then
        m.codeTextEditBox.text = event.GetData()
        m.codeTextEditBox.cursorPosition = m.codeTextEditBox.cursorPosition + 1
    elseif m.userKeyboard.isInFocusChain() then
        m.userTextEditBox.text = event.GetData()
        m.userTextEditBox.cursorPosition = m.userTextEditBox.cursorPosition + 1
    elseif m.passKeyboard.isInFocusChain()
        m.passTextEditBox.text = event.GetData()
        m.passTextEditBox.cursorPosition = m.passTextEditBox.cursorPosition + 1
    end if
end sub

function KeybordShow()
    updateAddressPart()
    m.footerText.visible = false
    if m.codeBox <> invalid then m.codeBox.visible = false
    m.welcomeText.translation = [m.welcomeMovedX, m.welcomeY]
    m.LoginBox.translation = [m.fullWidth - m.rectWidth - m.rightMargin, m.keyBox.height / 8]
    m.hideKey.keyValue = [[0,m.fullHeight],[0,(m.fullHeight - m.keyBox.height)]]
    m.hideAnimation.control = "start"
end function

function KeybordHide()
    m.footerText.visible = true
    if m.codeBox <> invalid then m.codeBox.visible = true
    m.welcomeText.translation = [m.welcomeOriginalX, m.welcomeY]
    m.LoginBox.translation = [m.fullWidth - m.rectWidth - m.rightMargin, m.fullHeight/2 - m.rectHeight/2]
    m.showKey.keyValue = [[0,(m.fullHeight - m.keyBox.height)],[0,m.fullHeight]]
    m.showAnimation.control = "start"
end function

sub onFocusChain()
    if m.codeTextEditBox.isInFocusChain() then
        m.codeTextEditBox.active = "true"
        m.codeEditBox.uri = "pkg:/images/login/user-edit-focus.png"
        m.userEditBox.uri = "pkg:/images/login/user-edit.png"
        m.passEditBox.uri = "pkg:/images/login/pass-edit.png"
        m.codeTextEditBox.hintTextColor = "#FFFFFF"
        m.codeTextEditBox.textColor = "#FFFFFF"
    elseif m.userTextEditBox.isInFocusChain() then
        m.userTextEditBox.active = "true"
        m.userEditBox.uri = "pkg:/images/login/user-edit-focus.png"
        m.codeEditBox.uri = "pkg:/images/login/user-edit.png"
        m.passEditBox.uri = "pkg:/images/login/pass-edit.png"
        m.userTextEditBox.hintTextColor = "#FFFFFF"
        m.userTextEditBox.textColor = "#FFFFFF"
    elseif m.passTextEditBox.isInFocusChain()
        m.passTextEditBox.active = "true"
        m.passEditBox.uri = "pkg:/images/login/pass-edit-focus.png"
        m.codeEditBox.uri = "pkg:/images/login/user-edit.png"
        m.userEditBox.uri = "pkg:/images/login/user-edit.png"
        m.passTextEditBox.hintTextColor = "#FFFFFF"
        m.passTextEditBox.textColor = "#FFFFFF"
    elseif m.codeKeyboard.isInFocusChain()
        m.codeTextEditBox.text = m.codeKeyboard.text
    elseif m.userKeyboard.isInFocusChain()
        m.userTextEditBox.text = m.userKeyboard.text
    elseif m.passKeyboard.isInFocusChain()
        m.passTextEditBox.text = m.passKeyboard.text
    else
        m.codeTextEditBox.hintTextColor = "#9FB6C6"
        m.codeTextEditBox.textColor = "#E7EEF4"
        m.userTextEditBox.hintTextColor = "#9FB6C6"
        m.userTextEditBox.textColor = "#E7EEF4"
        m.passTextEditBox.hintTextColor = "#9FB6C6"
        m.passTextEditBox.textColor = "#E7EEF4"
        m.codeEditBox.uri = "pkg:/images/login/user-edit.png"
        m.passEditBox.uri = "pkg:/images/login/pass-edit.png"
        m.userEditBox.uri = "pkg:/images/login/user-edit.png"
    end if
end sub

sub validateLoginDone()
    if m.validateLogin.state = "stop" then
        if m.validateLogin.validated then
            m.busyDialog.close = true
            m.top.status = m.validateLogin.status
        else
            if m.busyDialog <> invalid then m.busyDialog.close = true
            msg = m.validateLogin.errorMsg
            if msg = invalid or msg = "" then msg = tr("Usuario, senha ou codigo invalidos")
            m.codeStatusLabel.text = msg
            ShowMessageDialog(tr("Falha no login"), msg)
        end if
    end if
end sub

sub onValidateLogin()
    code = m.codeTextEditBox.text
    user = m.userTextEditBox.text
    pass = m.passTextEditBox.text

    if isEmpty(code) or isEmpty(user) or isEmpty(pass) then
        if isEmpty(code) then
            ShowMessageDialog(tr("Campo obrigatorio"), tr("Informe o codigo do revendedor"))
        elseif isEmpty(user) then
            ShowMessageDialog(tr("Campo obrigatorio"), tr("Informe o usuario"))
        else
            ShowMessageDialog(tr("Campo obrigatorio"), tr("Informe a senha"))
        end if
        return
    end if

    if not m.top.validate then
        m.top.validate = false
        m.validateLogin.code = code
        m.validateLogin.user = user
        m.validateLogin.pass = pass
        m.busyDialog = createObject("roSGNode", "ProgressDialog")
        getScene().dialog = m.busyDialog
        m.validateLogin.control = "RUN"
    end if
end sub

sub showExitButton()
    getScene().dialog.close = true
    if m.loginButton.isInFocusChain()
        if isEmpty(m.codeTextEditBox.text) then
            m.loginButton.setFocus(false)
            m.currAddressPart = 0
            m.codeTextEditBox.setFocus(true)
            m.codeKeyboard.setFocus(true)
            m.codeKeyboard.visible = "true"
            KeybordShow()
        elseif isEmpty(m.userTextEditBox.text) then
            m.loginButton.setFocus(false)
            m.currAddressPart = 1
            m.userTextEditBox.setFocus(true)
            m.userKeyboard.setFocus(true)
            m.userKeyboard.visible = "true"
            KeybordShow()
        elseif isEmpty(m.passTextEditBox.text) then
            m.loginButton.setFocus(false)
            m.currAddressPart = 2
            m.passTextEditBox.active = "true"
            m.passTextEditBox.setFocus(true)
            m.passKeyboard.setFocus(true)
            m.passKeyboard.visible = "true"
            KeybordShow()
        end if
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press then
        if key = "up" then
            if m.reloadButton.isInFocusChain() then
                m.reloadButton.setFocus(false)
                m.loginButton.setFocus(true)
                result = true
            elseif m.loginButton.isInFocusChain() then
                m.loginButton.setFocus(false)
                m.passTextEditBox.active = "true"
                m.passTextEditBox.setFocus(true)
                result = true
            elseif m.passTextEditBox.isInFocusChain() then
                m.passTextEditBox.setFocus(false)
                m.passTextEditBox.active = "false"
                m.userTextEditBox.setFocus(true)
                result = true
            elseif m.userTextEditBox.isInFocusChain() then
                m.userTextEditBox.setFocus(false)
                m.userTextEditBox.active = "false"
                m.codeTextEditBox.setFocus(true)
                result = true
            end if
        else if key = "down" then
            if m.codeTextEditBox.isInFocusChain() and not m.codeKeyboard.isInFocusChain() then
                m.codeTextEditBox.active = "false"
                m.codeTextEditBox.setFocus(false)
                m.userTextEditBox.active = "true"
                m.userTextEditBox.setFocus(true)
                result = true
            elseif m.userTextEditBox.isInFocusChain() and not m.userKeyboard.isInFocusChain() then
                m.userTextEditBox.active = "false"
                m.userTextEditBox.setFocus(false)
                m.passTextEditBox.active = "true"
                m.passTextEditBox.setFocus(true)
                result = true
            elseif m.passTextEditBox.isInFocusChain() and not m.passKeyboard.isInFocusChain()
                m.passTextEditBox.active = "false"
                m.passTextEditBox.setFocus(false)
                m.loginButton.setFocus(true)
                result = true
            elseif m.loginButton.isInFocusChain() then
                m.loginButton.setFocus(false)
                m.reloadButton.setFocus(true)
                result = true
            end if
        else if key = "back" then
            if m.codeKeyboard.isInFocusChain() and m.codeKeyboard.visible then
                m.codeTextEditBox.setFocus(true)
                KeybordHide()
                m.codeKeyboard.visible = "false"
                result = true
            elseif m.userKeyboard.isInFocusChain() and m.userKeyboard.visible then
                m.userTextEditBox.setFocus(true)
                KeybordHide()
                m.userKeyboard.visible = "false"
                result = true
            elseif m.passKeyboard.isInFocusChain() and m.passKeyboard.visible then
                m.passTextEditBox.setFocus(true)
                m.passKeyboard.visible = "false"
                KeybordHide()
                result = true
            end if
        else if key = "OK" then
            result = true
            if m.codeTextEditBox.isInFocusChain() then
                m.currAddressPart = 0
                m.codeKeyboard.setFocus(true)
                KeybordShow()
                m.codeKeyboard.visible = "true"
            elseif m.userTextEditBox.isInFocusChain() then
                m.currAddressPart = 1
                m.userKeyboard.setFocus(true)
                KeybordShow()
                m.userKeyboard.visible = "true"
            elseif m.passTextEditBox.isInFocusChain()
                m.currAddressPart = 2
                m.passKeyboard.setFocus(true)
                m.passKeyboard.visible = "true"
                KeybordShow()
            end if
        end if
    end if
    return result
end function
