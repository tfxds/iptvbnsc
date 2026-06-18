# Como rodar o app no Roku (sideload)

Não precisa de conta de desenvolvedor paga nem publicar na loja pra testar. É só ligar o **Modo Desenvolvedor** no aparelho e subir o `.zip`.

## 1. Ligar o Modo Desenvolvedor no Roku
No controle do Roku, com a tela inicial aberta, aperte nesta sequência:

**Home 3× · Up 2× · Right · Left · Right · Left · Right**

Vai abrir a tela "Developer Settings".
- Marque **Enable installer and restart** (Habilitar instalador e reiniciar).
- Aceite o contrato (botão na tela).
- Anote a **senha** se ele pedir pra criar uma (você vai usar no passo 3). Se não pedir, a senha padrão costuma ser `rokudev`.
- O Roku reinicia.

## 2. Descobrir o IP do Roku
No Roku: **Settings → Network → About** → anota o "IP address" (ex.: `192.168.0.50`).

## 3. Abrir o instalador no navegador (do PC, na MESMA rede do Roku)
No navegador do computador, acesse: `http://<IP_DO_ROKU>` (ex.: `http://192.168.0.50`)
- Vai pedir usuário/senha:
  - usuário: **rokudev**
  - senha: a que você criou no passo 1 (ou `rokudev`)

## 4. Subir o app
Na página "Development Application Installer":
1. Clique em **Upload** / "Escolher arquivo" e selecione o **`saplayer-roku.zip`**.
2. Clique em **Install** (ou **Replace** se já tiver um instalado).
3. O app abre sozinho no Roku em alguns segundos.

## 5. Como pegar o `.zip` (ele está no servidor)
O pacote está em `/root/roku-app/out/saplayer-roku.zip`. Pra baixar pro seu PC:
```bash
scp root@<SERVIDOR>:/root/roku-app/out/saplayer-roku.zip .
```
(ou pega pelo FTP/painel que você já usa). Depois é só selecionar esse arquivo no passo 4.

## 6. Ver erros/logs enquanto testa (opcional, muito útil)
No PC, na mesma rede:
```bash
telnet <IP_DO_ROKU> 8085
```
Abre o "BrightScript debug console" — mostra prints e qualquer erro de execução em tempo real. Útil pra eu diagnosticar se algo travar.

## 7. O que testar (resumo)
- App abre com a marca S.A Player.
- Tela de login com **Código do revendedor + Usuário + Senha** e o **MAC** exibido embaixo.
- Logar com um **código ativo + usuário/senha** → entra na grade.
- Cadastrar o MAC no painel e reabrir → entra sozinho (auto-login).

Checklist completo em `HOMOLOGACAO.md`.

## Erros comuns
- **"Failed to install"**: o `manifest` precisa estar na RAIZ do zip (já está no nosso build).
- **Página `http://IP` não abre**: o Modo Desenvolvedor não foi habilitado, ou o PC não está na mesma rede do Roku.
- **Tela preta/reinicia**: abrir o `telnet ...:8085` e me mandar as linhas de erro.
