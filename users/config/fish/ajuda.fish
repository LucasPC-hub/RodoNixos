# ajuda: meus comandos e atalhos, por categoria (fish, scripts, NixOS, SSH, desktop).
#
#   ajuda            mostra tudo
#   ajuda nix        só as linhas (ou categorias) que contêm "nix"
#
# Os dados vêm do nix-command-catalog (o commands.py do widget CommandShelf, que
# só lê arquivos): aliases, abbrs e funções do fish, ~/.local/bin, ~/.ssh/config
# e os atalhos do niri. Para descrever um comando, use `function x --description '...'`
# ou uma linha "#: descrição" logo acima do alias/abbr/função.
function ajuda --description 'Lista meus comandos e atalhos por categoria (ajuda <termo> filtra)'
    if not type -q nix-command-catalog
        echo 'ajuda: nix-command-catalog não está no PATH' >&2
        return 127
    end
    set -l cols $COLUMNS
    test -n "$cols"; or set cols (tput cols 2>/dev/null); or set cols 120

    nix-command-catalog --tsv | awk -F'\t' -v cols=$cols -v q=(string lower -- "$argv") '
    BEGIN {
        # Truecolor (RGB direto): fica igual em qualquer terminal/tema.
        BD = "\033[38;2;59;130;246m"                        # moldura: azul
        B  = "\033[1m"; R = "\033[0m"; D = "\033[2m"
        C  = "\033[1;38;2;125;211;252m"                     # nome do comando: azul claro
        IC["󰊕"] = "\033[1;38;2;74;222;128m"                 # função: verde
        IC[""] = "\033[38;2;229;231;235m"                   # github: branco
        IC[""] = "\033[38;2;192;132;252m"                   # tailscale: roxo
        IC[""] = "\033[38;2;251;191;36m"                    # LAN: âmbar
        IC[""] = "\033[38;2;34;211;238m"                    # túnel: ciano
        IC[""] = "\033[38;2;148;163;184m"                   # genérico: cinza-azulado
        title[1] = "Fish  ~/.config/fish"; title[2] = "~/.local/bin"
        title[3] = "NixOS";                title[4] = "SSH  ~/.ssh/config"
        title[5] = "Atalhos do desktop (Super)"
    }
    function rep(c, n,  s) { s = ""; while (n-- > 0) s = s c; return s }
    function cut(str, w)   { return length(str) > w ? substr(str, 1, w - 1) "…" : str }
    {
        s = $1
        if (q != "" && !index(tolower($0), q) && !index(tolower(title[s]), q)) next
        k = ++n[s]; total++
        icon[s,k] = ($2 != "" ? $2 : " "); name[s,k] = $3; det[s,k] = $4; desc[s,k] = $5
        if (length($3) > wn[s]) wn[s] = length($3)
        if (length($4) > wd[s]) wd[s] = length($4)
        if (length($5) > we[s]) we[s] = length($5)
    }
    END {
        if (!total) { print "Nada encontrado para \"" q "\"." > "/dev/stderr"; exit 1 }
        max = cols - 2                                  # largura total (com moldura) que cabe
        for (s = 1; s <= 5; s++) {
            if (!n[s]) continue
            fixed = 11 + wn[s] + wd[s]                  # tudo da linha exceto a descrição
            if (fixed + we[s] > max) {                  # não cabe: encolhe descrição, depois detalhe
                we[s] = max - fixed
                if (we[s] < 16) {
                    wd[s] += we[s] - 16; if (wd[s] < 8) wd[s] = 8
                    fixed = 11 + wn[s] + wd[s]
                    we[s] = max - fixed; if (we[s] < 1) we[s] = 1
                }
            }
            w = wn[s] + wd[s] + we[s]                   # soma das 3 colunas de conteúdo
            printf "\n%s╭─ %s%s%s %s%s╮%s\n", BD, B, title[s], R, BD, rep("─", 6 + w - length(title[s])), R
            for (k = 1; k <= n[s]; k++) {
                ic = icon[s,k]; ick = (ic in IC ? IC[ic] : R)
                printf "%s│%s %s%s%s  %s%-*s%s  %s%-*s%s  %-*s %s│%s\n", BD, R, ick, ic, R, C, wn[s], name[s,k], R, D, wd[s], cut(det[s,k], wd[s]), R, we[s], cut(desc[s,k], we[s]), BD, R
            }
            printf "%s╰%s╯%s\n", BD, rep("─", 9 + w), R
        }
    }'
end
