# Layout de disco do rodolucasbit, igual ao que o rodo-install criou (cópia do
# hosts/base/disko.nix). Os mounts usam partlabel (disk-main-ESP/root), então
# o nome do device só importa pra quem rodar o `disko` à mão. O disko NÃO
# reparticiona em `nixos-rebuild`.
#
# GPT: ESP 1G (vfat, /boot) + root ext4 no resto. Swap fica por zram (default.nix).
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
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
