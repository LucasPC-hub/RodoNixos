{ pkgs, inputs, self, ... }:

# Comando `rodo-install` embutido na ISO. Fluxo:
#   1. escolhe disco alvo + confirma (APAGA TUDO)
#   2. pergunta hostname + username
#   3. gera hosts/<host> a partir do base (hostname, device do disko, user)
#      e cria users/<user>.nix; registra o host no flake.nix (âncora)
#   4. disko particiona/formata/monta em /mnt
#   5. nixos-generate-config --no-filesystems  -> hardware.nix real
#   6. nixos-install --flake .#<host>  +  senha do usuário
#
# O repo inteiro vem embutido na ISO (${self}), então o install é offline no
# que diz respeito ao SOURCE; o nixos-install ainda baixa pacotes do cache
# (precisa de rede na máquina alvo).

let
  system = pkgs.stdenv.hostPlatform.system;
  disko = inputs.disko.packages.${system}.default;

  rodo-install = pkgs.writeShellApplication {
    name = "rodo-install";
    runtimeInputs = [
      pkgs.util-linux      # lsblk
      pkgs.gitMinimal
      disko
      pkgs.nixos-install-tools  # nixos-install, nixos-generate-config, nixos-enter
      pkgs.coreutils
      pkgs.gnused
    ];
    text = ''
      set -euo pipefail

      SRC="${self}"   # source do RodoNixos embutido na ISO (read-only)

      if [ "$(id -u)" -ne 0 ]; then
        echo "rode com sudo: sudo rodo-install"; exit 1
      fi

      echo "======================================"
      echo "     RodoNixos — instalador"
      echo "======================================"
      echo
      echo "Discos disponíveis:"
      lsblk -dpno NAME,SIZE,MODEL | grep -vE '/dev/(loop|sr|zram)' || true
      echo
      read -rp "Disco ALVO (ex: /dev/nvme0n1): " DISK
      [ -b "$DISK" ] || { echo "não é um dispositivo de bloco: $DISK"; exit 1; }
      echo
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "  ISSO VAI APAGAR TODO O CONTEÚDO DE: $DISK"
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      read -rp "digite exatamente 'sim' para continuar: " CONFIRM
      [ "$CONFIRM" = "sim" ] || { echo "abortado."; exit 1; }

      read -rp "hostname da máquina (ex: rodo-joao): " HOST
      [ -n "$HOST" ] || { echo "hostname vazio"; exit 1; }
      read -rp "username (ex: joao): " USERNAME
      [ -n "$USERNAME" ] || { echo "username vazio"; exit 1; }

      WORK="$(mktemp -d)"
      cp -rT "$SRC" "$WORK"
      chmod -R u+w "$WORK"
      cd "$WORK"

      echo ">> gerando host '$HOST' a partir do base..."
      cp -rT hosts/base "hosts/$HOST"
      sed -i "s|networking.hostName = \"rodo-base\";|networking.hostName = \"$HOST\";|" "hosts/$HOST/default.nix"
      sed -i "s|users.users.rodouser|users.users.$USERNAME|" "hosts/$HOST/default.nix"
      sed -i "s|/dev/disk/by-id/RODO-DISKO-DEVICE|$DISK|" "hosts/$HOST/disko.nix"

      cp users/rodouser.nix "users/$USERNAME.nix"
      sed -i "s|rodouser|$USERNAME|g" "users/$USERNAME.nix"

      # registra no flake.nix (âncora determinística)
      sed -i "/# >>> RODO-INSTALL-HOSTS/a\\      $HOST = mkHost { hostPath = ./hosts/$HOST; users = { $USERNAME = ./users/$USERNAME.nix; }; };" flake.nix

      # NB: $WORK é um diretório simples (o ${self} da ISO não tem .git). Flake
      # em path sem git => o nix já enxerga TODOS os arquivos, sem precisar de
      # `git add`. Por isso não há nenhum comando git aqui.

      echo ">> particionando + formatando $DISK (disko)..."
      disko --mode disko --flake ".#$HOST"

      echo ">> detectando hardware da máquina..."
      nixos-generate-config --no-filesystems --root /mnt --dir /tmp/hwgen
      cp /tmp/hwgen/hardware-configuration.nix "hosts/$HOST/hardware.nix"

      echo ">> copiando config para /mnt/etc/nixos..."
      mkdir -p /mnt/etc/nixos
      cp -rT "$WORK" /mnt/etc/nixos

      echo ">> instalando (.#$HOST)... isso baixa pacotes do cache, pode demorar."
      nixos-install --flake "/mnt/etc/nixos#$HOST" --no-channel-copy

      echo ">> defina a senha do usuário '$USERNAME':"
      nixos-enter --root /mnt -c "passwd $USERNAME"

      echo
      echo "======================================"
      echo "  Instalado! Rode:  reboot"
      echo "  Depois, rebuild com:"
      echo "    sudo nixos-rebuild switch --flake /etc/nixos#$HOST"
      echo "======================================"
    '';
  };
in
{
  environment.systemPackages = [ rodo-install ];
}
