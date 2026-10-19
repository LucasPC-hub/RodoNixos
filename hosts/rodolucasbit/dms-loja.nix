{ lib, ... }:

# Plugins da loja do DMS iguais aos da laal. Na máquina dela eles foram
# instalados pela loja (~/.config/DankMaterialShell/plugins); aqui vêm do
# plugins.lock.json copiado de lá, no mesmo repo e commit de cada um, e vão
# pro sistema junto com os de hosts/laal/dms-extras.nix.
#
# Pra atualizar: copiar de novo o ~/.config/DankMaterialShell/plugins.lock.json
# da laal para users/config/dms-shell/ e rodar fkr.
let
  lock = (lib.importJSON ../../users/config/dms-shell/plugins.lock.json).plugins;

  fonte = p:
    let
      repo = builtins.fetchGit {
        url = p.repo;
        rev = p.commit;
        allRefs = true;
      };
    in
    if p ? path then "${repo}/${p.path}" else repo;
in
{
  programs.dms-shell.plugins = lib.mapAttrs (_: p: { src = fonte p; }) lock;
}
