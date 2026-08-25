# Layout de disco declarativo (disko) — usado SÓ pelo host base.
#
# Nenhum host de produção (rodolucas/laal/rodojaisla) importa este arquivo,
# então ele não afeta as máquinas atuais. O disko também NÃO reparticiona em
# `nixos-rebuild`: a parte destrutiva (zerar/formatar) só roda quando o comando
# `disko` é chamado à mão — o que só acontece dentro do rodo-install, no disco
# que você escolheu e confirmou.
#
# GPT: ESP 1G (vfat, /boot) + root ext4 no resto. Swap fica por zram (default.nix).
{
  disko.devices.disk.main = {
    type = "disk";
    # O rodo-install troca este device pelo disco escolhido (sed nesta string):
    device = "/dev/disk/by-id/RODO-DISKO-DEVICE";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
