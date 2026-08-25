# Backup/restore do perfil inteiro do Zen Browser (histórico, cookies, logins,
# abas, extensões) cifrado com age, pra migrar de PC ou recuperar.
#
#   zen-backup           -> empacota ~/.zen (menos cache), cifra e envia pro remote
#   zen-restore [nome]   -> baixa (o último, ou o nome dado), decifra e restaura
#
# Feche o Zen antes (o perfil é sqlite; copiar aberto corrompe).
# Destino: $ZEN_BACKUP_REMOTE (default: bucket OCI). Chave age: $AGE_KEY.
{ pkgs, ... }:

let
  # Chave pública admin (age). Só ela + as chaves de host descriptografam.
  adminKey = "age1fhrctt9huhe2yr9m9qv77vjvlf6ucl0aafn2x766vg9p4sj7jfjsw5qanu";

  zen-backup = pkgs.writeShellApplication {
    name = "zen-backup";
    runtimeInputs = [ pkgs.rclone pkgs.age pkgs.gnutar pkgs.zstd ];
    text = ''
      admin="${adminKey}"
      remote="''${ZEN_BACKUP_REMOTE:-oci:zen-profile-backup}"
      prof="$HOME/.zen"
      [ -d "$prof" ] || { echo "sem perfil em $prof"; exit 1; }
      if pgrep -f '\.zen/|zen-bin|zen-beta' >/dev/null 2>&1; then
        echo "⚠️  Feche o Zen antes (evita corromper o perfil sqlite)."; exit 1
      fi
      name="zen-$(uname -n)-$(date +%Y%m%d-%H%M%S).tar.zst.age"
      echo "empacotando + cifrando $prof ..."
      tar --zstd -C "$HOME" \
        --exclude='.zen/*/cache2' --exclude='.zen/*/startupCache' \
        --exclude='.zen/*/shader-cache' --exclude='.zen/*/thumbnails' \
        -cf - .zen | age -r "$admin" | rclone rcat "$remote/$name" --progress
      echo "ok -> $remote/$name"
      # Retenção: mantém só os 7 backups mais recentes.
      old="$(rclone lsf "$remote" 2>/dev/null | grep '\.tar\.zst\.age$' | sort | head -n -7 || true)"
      for f in $old; do echo "expirando antigo: $f"; rclone deletefile "$remote/$f" || true; done
    '';
  };

  zen-restore = pkgs.writeShellApplication {
    name = "zen-restore";
    runtimeInputs = [ pkgs.rclone pkgs.age pkgs.gnutar pkgs.zstd ];
    text = ''
      key="''${AGE_KEY:-$HOME/.config/receita-de-bolo.md}"
      remote="''${ZEN_BACKUP_REMOTE:-oci:zen-profile-backup}"
      [ -f "$key" ] || { echo "sem chave age em: $key"; exit 1; }
      if pgrep -f '\.zen/|zen-bin|zen-beta' >/dev/null 2>&1; then
        echo "⚠️  Feche o Zen antes de restaurar."; exit 1
      fi
      latest="''${1:-$(rclone lsf "$remote" 2>/dev/null | sort | tail -1)}"
      [ -n "$latest" ] || { echo "nenhum backup em $remote"; exit 1; }
      echo "restaurando: $latest"
      if [ -d "$HOME/.zen" ]; then
        bak="$HOME/.zen.bak-$(date +%Y%m%d-%H%M%S)"; mv "$HOME/.zen" "$bak"
        echo "perfil antigo movido pra $bak"
      fi
      rclone cat "$remote/$latest" | age -d -i "$key" | tar --zstd -C "$HOME" -xf -
      echo "ok. Zen restaurado de $latest"
    '';
  };
in
{
  home.packages = [ zen-backup zen-restore ];
}
