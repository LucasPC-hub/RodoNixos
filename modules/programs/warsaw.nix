{ pkgs, lib, ... }:

let
  warsaw = pkgs.stdenv.mkDerivation {
    pname = "warsaw";
    version = "2.21.4-3";

    src = ../../assets/warsaw_setup_64.deb;

    nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook ];

    buildInputs = with pkgs; [
      dbus.lib
      stdenv.cc.cc.lib
      libx11
      libxi
      libxcursor
      libxext
      libxfixes
      libxft
      libxrender
      fontconfig
      zlib
      nss
      at-spi2-core
      glib
    ];

    dontStrip = true;

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      mkdir -p $out/bin $out/lib $out/etc $out/share/fonts

      cp usr/local/bin/warsaw/core       $out/bin/
      cp usr/local/bin/warsaw/wsupdsl    $out/bin/
      cp usr/local/bin/warsaw/wsatspi    $out/bin/ 2>/dev/null || true
      cp usr/local/bin/warsaw/sysdss     $out/bin/ 2>/dev/null || true
      cp usr/local/lib/warsaw/*.so       $out/lib/
      cp usr/local/etc/warsaw/*          $out/etc/
      cp -r usr/local/share/fonts/*      $out/share/fonts/ 2>/dev/null || true

      # wsbrmu.so tem PT_GNU_STACK com stack executável — kernel rejeita dlopen
      # Limpa o bit PF_X do PT_GNU_STACK (0x6474e551) via patch direto no ELF
      ${pkgs.python3}/bin/python3 - "$out/lib/wsbrmu.so" << 'PYEOF'
import struct, sys
with open(sys.argv[1], 'r+b') as f:
    d = bytearray(f.read())
if d[:4] != b'\x7fELF' or d[4] != 2: raise SystemExit("not ELF64")
e_phoff     = struct.unpack_from('<Q', d, 32)[0]
e_phentsize = struct.unpack_from('<H', d, 54)[0]
e_phnum     = struct.unpack_from('<H', d, 56)[0]
for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    if struct.unpack_from('<I', d, off)[0] == 0x6474e551:  # PT_GNU_STACK
        flags = struct.unpack_from('<I', d, off + 4)[0]
        struct.pack_into('<I', d, off + 4, flags & ~0x1)   # clear PF_X
        with open(sys.argv[1], 'r+b') as f: f.write(d)
        print(f"wsbrmu.so: exec-stack cleared ({flags:#x} -> {flags & ~0x1:#x})")
        break
PYEOF
    '';
  };
in
{
  # Diretório mutável para estado do warsaw (gas.dbd precisa de escrita)
  systemd.tmpfiles.rules = [
    "d /var/lib/warsaw 0755 root root -"
  ];

  # Copia configs padrão apenas se não existirem; cria symlinks FHS
  system.activationScripts.warsaw = {
    text = ''
      # Garante que o diretório existe (tmpfiles roda depois)
      mkdir -p /var/lib/warsaw

      # Copia arquivos de config padrão (somente na primeira vez)
      for f in ${warsaw}/etc/*; do
        fname="$(basename "$f")"
        if [ ! -f "/var/lib/warsaw/$fname" ]; then
          cp "$f" "/var/lib/warsaw/$fname"
        fi
      done

      # Symlinks FHS — o core usa dlopen com caminhos absolutos /usr/local/...
      mkdir -p /usr/local/bin /usr/local/etc /usr/local/lib

      # Remove diretórios reais caso existam (para poder criar symlinks)
      [ -d /usr/local/bin/warsaw ] && ! [ -L /usr/local/bin/warsaw ] && rm -rf /usr/local/bin/warsaw
      [ -d /usr/local/etc/warsaw ] && ! [ -L /usr/local/etc/warsaw ] && rm -rf /usr/local/etc/warsaw
      [ -d /usr/local/lib/warsaw ] && ! [ -L /usr/local/lib/warsaw ] && rm -rf /usr/local/lib/warsaw

      ln -sfn ${warsaw}/bin  /usr/local/bin/warsaw
      ln -sfn /var/lib/warsaw /usr/local/etc/warsaw
      ln -sfn ${warsaw}/lib  /usr/local/lib/warsaw
    '';
  };

  systemd.services.warsaw = {
    description = "Warsaw Security Module (Topaz OFD)";
    after = [ "multi-user.target" "dbus.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "forking";
      PIDFile = "/var/run/core.pid";
      Restart = "always";
      RestartSec = "5s";
      ExecStart = "${warsaw}/bin/core";
      # Adiciona o rootca.crt gerado ao NSS de todos os browsers do usuário
      ExecStartPost = pkgs.writeShellScript "warsaw-trust-cert" ''
        # Aguarda o daemon gerar rootca.crt (typ. <2s)
        for i in $(seq 1 10); do
          [ -f /var/lib/warsaw/rootca.crt ] && break
          sleep 1
        done
        [ -f /var/lib/warsaw/rootca.crt ] || exit 0

        CERT=/var/lib/warsaw/rootca.crt
        CERTUTIL=${pkgs.nss.tools}/bin/certutil

        add_cert() {
          local db="$1"
          [ -f "$db/cert9.db" ] || return
          "$CERTUTIL" -A -n "Warsaw Personal CA" -t "CT,," \
            -i "$CERT" -d "sql:$db" 2>/dev/null && \
            echo "warsaw: CA adicionada em $db" || true
        }

        # Zen Browser (~/.config/zen/)
        for dir in /home/jaisla/.config/zen/*/; do
          add_cert "$dir"
        done

        # Firefox (~/.config/mozilla/firefox/)
        for dir in /home/jaisla/.config/mozilla/firefox/*/; do
          add_cert "$dir"
        done

        # NSS compartilhados
        add_cert /home/jaisla/.pki/nssdb
        add_cert /home/jaisla/.local/share/pki/nssdb
      '';
    };

    environment = {
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      SSL_CERT_DIR  = "${pkgs.cacert}/etc/ssl/certs";
    };
  };
}
