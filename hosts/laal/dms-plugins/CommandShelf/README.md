# Meus Comandos · CommandShelf

Widget de desktop para DankMaterialShell **1.4.6+**, criado por **Matheuscara**.
Uma referência interativa dos comandos locais: categorias, busca sem diferença de
maiúsculas/acentos, detalhes e cópia. Não executa os comandos da lista.

## Uso

- Filtre por **Shell, Scripts, NixOS, SSH ou Atalhos**, ou use **Todos**.
- Combine a categoria com a busca; por exemplo, `funcao` encontra funções.
- Clique numa linha para ver comando, descrição e origem. Use o ícone de copiar
  para copiar o comando; SSH copia `ssh <alias>` e atalhos copiam a combinação.
- A confirmação só aparece depois que a cópia termina com sucesso.
- Atualize pelo botão de recarregar após mudar seus aliases ou scripts.
- Clique na busca e use **Esc** para limpar os filtros; **↓** vai para a lista,
  **↑/↓** navegam, **Enter** copia e **Espaço** expande o item selecionado.
- Use os controles nativos do DMS para mover com o botão direito e redimensionar.

## Fontes e privacidade

O `commands.py` usa somente a biblioteca padrão do Python e lê:

| Categoria | Origem |
|---|---|
| Shell / NixOS | Aliases, abbrs e funções do fish em `~/.config/fish/conf.d/*.fish`, `config.fish` e `functions/*.fish`; os que chamam `nix`, `nixos-rebuild`, `nix-shell`, `home-manager` etc. (ou têm nome `nix*`) ficam em NixOS |
| Scripts | Arquivos regulares, sem symlinks, com shebang em `~/.local/bin` |
| SSH | Hosts concretos em `~/.ssh/config`, com seus destinos e túneis |
| Atalhos | Os atalhos do niri declarados em `DESKTOP_SHORTCUTS` no helper |

A descrição de um comando vem de `function nome --description '...'` ou de
comentários `#: Descrição` logo acima do alias/abbr/função (em scripts, de uma
linha `#: ` ou do primeiro comentário depois do shebang). O parser não
carrega arquivos com `source`, não executa funções, não expande comandos de shell,
não segue `Include` do SSH e não expande curingas de hosts. Não há telemetria,
rede, serviço adicional, cache de inventário ou polling. Hosts, endereços e nomes
de scripts são lidos na máquina do usuário, não distribuídos neste plugin.

A leitura acontece ao carregar o widget e ao pedir atualização. Comandos criados
dinamicamente durante a inicialização do shell não são descobertos. A lista de
atalhos é explícita: adapte-a ao seu compositor se instalar em outro desktop.

## Instalação

Dependências: **DMS 1.4.6+, Python 3 e o comando `dms` no PATH**.
A cópia usa `dms cl copy` por argumentos, sem shell.

### Neste repositório (RodoNixos)

A pasta fica em `hosts/laal/dms-plugins/CommandShelf` e o Nix a instala como
plugin do DMS, publicando o mesmo helper como `nix-command-catalog`. As funções
fish `ajuda` e `comandos` (`users/config/fish/`) usam sua saída TSV. Não crie
uma segunda cópia do plugin no diretório do usuário.

### DMS sem NixOS

Copie **esta pasta completa** para
`~/.config/DankMaterialShell/plugins/CommandShelf`, reinicie o DMS, habilite
**Meus Comandos** e adicione-o em **Configurações → Widgets do desktop**.
O widget invoca diretamente o `commands.py` ao lado do QML: não depende do shell
personalizado do autor nem de uma lista de comandos pré-gerada.

Para reutilizar o catálogo num `help` próprio, sua interface é:

```bash
python3 commands.py --json
python3 commands.py --tsv
```

JSON inclui `version`, `categories`, `commands` e `warnings`; cada comando traz
`id`, `category`, `name`, `command`, `detail`, `description`, `kind` e `source`.
TSV tem cinco campos: categoria numérica, ícone, nome, detalhe e descrição.

## Verificação

Exercitado no DMS 1.4.6: busca combinada com categorias, acentos, atualização
repetida, nenhum resultado e cópia real de comandos NixOS, SSH e atalhos sem
newline extra.

## Licença

[MIT](LICENSE), copyright 2026 Matheuscara.
