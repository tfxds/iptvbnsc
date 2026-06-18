# Proxy de remux HEVC → fMP4 (canais 4K/FHD no Roku)

## Problema
O Roku **não decodifica HEVC/H.265 dentro de MPEG-TS** (só em fMP4/DASH). Painéis Xtream
servem os canais "4K/FHD" como **HEVC-em-TS**, então o player Roku dá `errCode -5`
("unsupported video format"). Comprovado por `ffprobe`: canais que falham = HEVC Main;
canais que tocam = H.264. Apps concorrentes (ex: Vizzion) resolvem com **remux no servidor**.

## Solução
`ffmpeg -c copy` (cópia de codec, **sem re-encode** → CPU baixíssima) remuxa o stream
**TS → fMP4** com tag `hvc1` (a que o Roku aceita) + `aac_adtstoasc` (corrige o AAC do TS).
O app reaponta os canais que dão `-5` para este proxy.

```
Roku → proxy (UK, remux fMP4/hvc1) → relay BR → painel Xtream
```

O **relay BR** é necessário porque o painel **bloqueia IPv6 e geo fora do Brasil** (401).
O proxy puxa o painel via `http_proxy` apontando para um relay num IP brasileiro autorizado.

## 1) Relay BR (IP autorizado pelo painel)
`tinyproxy` num servidor no Brasil:
```bash
apt-get install -y tinyproxy
echo "Allow <IP_DO_PROXY>" >> /etc/tinyproxy/tinyproxy.conf   # libera só o servidor de remux
# painel bloqueia IPv6 -> fixa o host do painel num IPv4:
echo "<IPv4_do_painel> <host_do_painel>" >> /etc/hosts
systemctl restart tinyproxy
# firewall: liberar a porta (8888) só pro IP do proxy de remux
```

## 2) Proxy de remux (`proxy.py`)
Servidor com `ffmpeg` + `python3`:
```bash
apt-get install -y ffmpeg
# variaveis de ambiente (NUNCA hardcode credenciais no git):
#   PANEL=http://<host_painel>/live/<user>/<pass>
#   BR_PROXY=http://<ip_relay_br>:8888
python3 proxy.py
```
Use o `hevcproxy.service` (systemd) com `Environment=` para PANEL/BR_PROXY.

Endpoints:
- `GET /r/<id>/index.m3u8` — sobe o ffmpeg do canal sob demanda e serve a playlist fMP4
- `GET /r/<id>/<arquivo>` — serve `init.mp4` / `index<N>.m4s`
- `GET /health`

ffmpeg ocioso (sem requests há `IDLE`=30s) é encerrado automaticamente.

## 3) App (Roku)
Em `TimeGridView.controlvideoplay`, no `errCode -5`, o canal é reapontado para
`http://<proxy>:8090/r/<id>/index.m3u8` (`streamFormat=hls`). Canais H.264 tocam direto
no `.ts` e nunca chegam no fallback.

## Pendências para produção
- Generalizar a conta do painel (passar `user/pass` por request em vez de fixo no `PANEL`).
- HTTPS + domínio no proxy.
- Medir custo de banda (cada espectador 4K ≈ 15–25 Mbps in+out; mesma emissão pode ser
  compartilhada por vários espectadores).
- Canais 4K que "só carregam" podem ser limite de **banda** (bitrate alto), não codec —
  remux não resolve; só transcode com downscale (pesado), não recomendado.
