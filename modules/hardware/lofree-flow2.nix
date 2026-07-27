{ ... }:

# Lofree Flow 2 (388d:0001) — libera acesso raw HID pra VIA (usevia.app).
# Sem isso o /dev/hidraw* nasce root:root 0600: o Chromium enumera o teclado
# no seletor WebHID mas nao consegue abrir -> NotAllowedError e a leitura da
# versao do protocolo volta lixo ("Received invalid protocol version").
#
# uaccess dá ACL pra sessao ativa (via systemd-logind); MODE/GROUP é fallback.
# A regra so reavalia no plug: desconecta e reconecta o cabo depois do rebuild.
{
  services.udev.extraRules = ''
    # Lofree Flow 2 - raw HID (VIA)
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="388d", ATTRS{idProduct}=="0001", MODE="0660", GROUP="users", TAG+="uaccess"
    # fallback USB (alguns firmwares expoem por usb_device)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="388d", ATTRS{idProduct}=="0001", MODE="0660", GROUP="users", TAG+="uaccess"
  '';
}
