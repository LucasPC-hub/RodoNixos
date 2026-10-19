{ lib, rustPlatform, fetchFromGitHub, symlinkJoin }:
let
  version = "1.11.6-dms.2";
  # coldi1337/dms-bitwarden-cli main @ 2026-10-14, the revision vendored in
  # dms/plugins/Bitwarden (MIT).
  src = fetchFromGitHub {
    owner = "coldi1337";
    repo = "dms-bitwarden-cli";
    rev = "9a74d8a0071d2d2ba8f56e3c9c4907cce27cb8d8";
    hash = "sha256-kWC5z7uraqqkG+4Du1rWXSBR+fq9OAnssR7hE7+Bhpg=";
  };
  # Each helper is its own crate with its own lockfile. The lockfiles are
  # byte-identical copies of the pinned ones, kept beside this file so
  # evaluation needs no import-from-derivation.
  lockFiles = {
    vault = ./vault.Cargo.lock;
    unlock-key = ./unlock-key.Cargo.lock;
    agent = ./agent.Cargo.lock;
  };
  helper = crate: pname: rustPlatform.buildRustPackage {
    inherit pname version src;
    sourceRoot = "${src.name}/${crate}";
    cargoLock.lockFile = lockFiles.${crate};
    # Integration tests drive keyrings/sockets; the plugin runs each
    # binary's own --self-test before it is used.
    doCheck = false;
    meta = {
      description = "Helper for the Bitwarden Dankbar DMS plugin (${crate})";
      homepage = "https://github.com/coldi1337/dms-bitwarden-cli";
      license = lib.licenses.mit;
      mainProgram = pname;
      platforms = [ "x86_64-linux" ];
    };
  };
in
symlinkJoin {
  name = "qs-bitwarden-helpers-${version}";
  paths = [
    (helper "vault" "qs-bitwarden-vault")
    (helper "unlock-key" "qs-bitwarden-unlock-key")
    (helper "agent" "qs-bitwarden-ssh-agent")
  ];
}
