{ pkgs, inputs, ... }:

let
  jetbrains = import ./programs/jetbrains.nix { inherit pkgs; };

  # Decifra o .env cifrado de um projeto (secrets/<proj>-env.age no RodoNixos)
  # pra ./.env na pasta atual. Funciona em qualquer worktree/máquina que tenha
  # a chave age pessoal. Uso: rodoenv vitrum  [destino]
  rodoenv = pkgs.writeShellApplication {
    name = "rodoenv";
    runtimeInputs = [ pkgs.age ];
    text = ''
      # rodoenv [--if-missing] <projeto> [destino]
      # --if-missing: não faz nada se o destino já existe (uso em shellHook/direnv).
      if_missing=0
      if [ "''${1:-}" = "--if-missing" ]; then if_missing=1; shift; fi
      proj="''${1:-}"
      dest="''${2:-.env}"
      repo="''${RODONIXOS:-$HOME/RodoNixos}"
      key="''${AGE_KEY:-$HOME/.config/sops/age/keys.txt}"
      agefile="$repo/secrets/$proj-env.age"

      if [ -z "$proj" ]; then
        echo "uso: rodoenv [--if-missing] <projeto> [destino]   (ex: rodoenv vitrum)"; exit 1
      fi
      if [ ! -f "$agefile" ]; then echo "não existe: $agefile"; exit 1; fi
      if [ ! -f "$key" ]; then echo "sem chave age em: $key"; exit 1; fi
      if [ "$if_missing" = "1" ] && [ -e "$dest" ]; then exit 0; fi
      if [ -e "$dest" ]; then cp -f "$dest" "$dest.bak"; echo "backup do antigo -> $dest.bak"; fi

      age -d -i "$key" -o "$dest" "$agefile"
      chmod 600 "$dest"
      echo "ok: $proj -> $dest"
    '';
  };

  # Gera URLs JDBC (com credencial) a partir do cofre secrets/databases.age.
  # A pessoa importa colando a URL no DataGrip ou DBeaver. Uso: db-export [saida]
  db-export = pkgs.writeShellApplication {
    name = "db-export";
    runtimeInputs = [ pkgs.age pkgs.jq ];
    text = ''
      repo="''${RODONIXOS:-$HOME/RodoNixos}"
      key="''${AGE_KEY:-$HOME/.config/sops/age/keys.txt}"
      agefile="$repo/secrets/databases.age"
      out="''${1:-conexoes-jdbc.txt}"

      [ -f "$agefile" ] || { echo "não existe: $agefile (rode setup-databases.sh)"; exit 1; }
      [ -f "$key" ] || { echo "sem chave age em: $key"; exit 1; }

      age -d -i "$key" "$agefile" | jq -r '
        .[]
        | .u = (.user|@uri) | .p = (.password|@uri)
        | "[\(.name)]  (\(.type) @ \(.host):\(.port)/\(.db))",
          ( if .type=="postgresql" then "jdbc:postgresql://\(.host):\(.port)/\(.db)?user=\(.u)&password=\(.p)"
            elif (.type=="mysql" or .type=="mariadb") then "jdbc:\(.type)://\(.host):\(.port)/\(.db)?user=\(.u)&password=\(.p)"
            elif .type=="sqlserver" then "jdbc:sqlserver://\(.host):\(.port);databaseName=\(.db);user=\(.u);password=\(.p)"
            elif .type=="oracle" then "jdbc:oracle:thin:\(.u)/\(.p)@\(.host):\(.port)/\(.db)"
            else "jdbc:\(.type)://\(.host):\(.port)/\(.db)?user=\(.u)&password=\(.p)" end ),
          ""
      ' > "$out"
      chmod 600 "$out"
      echo "ok -> $out (contém senhas; não commitar). Importe colando cada URL."
    '';
  };
in
{
  imports = [
    ./shared.nix
    inputs.dsearch.homeModules.default
    inputs.helium-browser.homeModules.default
  ];

  home.username = "lucasp";
  home.homeDirectory = "/home/lucasp";
  home.stateVersion = "25.05";

  # Pacotes só meus
  home.packages = with pkgs; [
    deezer-desktop
    deezer-enhanced
    rclone
    protonmail-desktop
    proton-pass
    proton-vpn
    tidal-hifi
    zed-editor
    ghostty
    dig
    qbittorrent
    goofcord
    inputs.t3code.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.cmux.packages.${pkgs.stdenv.hostPlatform.system}.default
    jamesdsp
    remmina
    freerdp
    awscli2
    oci-cli
    tmux
    rodoenv
    db-export
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.webstorm)
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.datagrip)
  ];

  programs.dsearch.enable = true;
  programs.helium.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    AWS_DEFAULT_REGION = "us-east-1";
    AWS_REGION = "us-east-1";
    # agenix expõe os arquivos via symlink (lrwxrwxrwx); o oci-cli reclama da
    # permissão do link. Os alvos reais são 600, então é seguro silenciar.
    OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING = "True";
    QT_QPA_PLATFORMTHEME = "gtk3";
    TERMINAL = "kitty";
    BROWSER = "zen-beta";
    FILES = "thunar";
    NIXOS_OZONE_WL = "1";
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.shared-mime-info}/share";
  };

  # Cedilha (ç/Ç) com dead_acute + c
  home.file.".XCompose".text = ''
    include "%L"
    <dead_acute> <c> : "ç" U00E7
    <dead_acute> <C> : "Ç" U00C7
  '';
}
