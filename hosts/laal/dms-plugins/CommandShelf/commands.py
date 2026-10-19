#!/usr/bin/env python3
"""Catálogo dos meus comandos (fonte única do `ajuda` e do widget CommandShelf).

Só LÊ arquivos e serializa metadados: nunca executa, faz `source` nem expande
nada dos arquivos lidos, e não acessa rede.

Fontes: aliases, abbrs e funções do fish (~/.config/fish/conf.d/*.fish,
config.fish e functions/*.fish), scripts em ~/.local/bin, hosts do
~/.ssh/config e os atalhos do niri em DESKTOP_SHORTCUTS.

Uso:
  commands.py [--json | --tsv] [--home DIR]

--json (padrão): {"version":1,"categories":[...],"commands":[...],"warnings":[...]}
--tsv: 5 colunas pro renderizador do `ajuda`:
       categoria(1-5) <TAB> ícone <TAB> nome <TAB> detalhe <TAB> descrição
"""

import argparse
import json
from pathlib import Path
import re
import shlex
import stat
import sys

VERSION = 1

CATEGORIES = [
    {"id": "shell", "title": "Shell", "icon": "terminal"},
    {"id": "scripts", "title": "Scripts", "icon": "code"},
    {"id": "nix", "title": "NixOS", "icon": "deployed_code"},
    {"id": "ssh", "title": "SSH", "icon": "dns"},
    {"id": "desktop", "title": "Atalhos", "icon": "keyboard"},
]
TSV_SECTION = {"shell": "1", "scripts": "2", "nix": "3", "ssh": "4", "desktop": "5"}

# Atalhos do niri (users/config/dms/binds.kdl): lista única, usada pelo `ajuda`
# e pelo widget. Mudou um bind lá? Atualize aqui.
DESKTOP_SHORTCUTS = [
    ("Super + T", "Terminal (kitty)"),
    ("Super + E", "Arquivos (Dolphin)"),
    ("Super + Espaço", "Lançador de aplicativos"),
    ("Super + V", "Histórico da área de transferência"),
    ("Super + M", "Gerenciador de tarefas"),
    ("Super + ,", "Configurações do DMS"),
    ("Super + N", "Central de notificações"),
    ("Super + Shift + N", "Bloco de notas"),
    ("Super + Y", "Escolher wallpaper"),
    ("Super + Ctrl + W", "Carrossel de wallpapers"),
    ("Super + G", "Nord Hub"),
    ("Super + Ctrl + D", "Docker Manager"),
    ("Super + Shift + B", "Bitwarden"),
    ("Super + Shift + C", "Calculadora"),
    ("Super + Tab", "Visão geral das janelas"),
    ("Super + Q", "Fecha a janela"),
    ("Super + L", "Bloqueia a tela"),
    ("Super + Shift + S", "Captura de tela"),
    ("Super + Shift + W", "Cria regra de janela"),
    ("Ctrl + Shift + R", "Renomeia o workspace"),
    ("Super + Shift + /", "Todos os atalhos do niri"),
]

# Funções do users/programs/fish.nix: o home-manager gera sem --description.
# Só valem quando o arquivo não traz descrição (--description ou "#: ").
FALLBACK_DESCRIPTIONS = {
    "fkr": "Aplica a config do ~/RodoNixos (nixos-rebuild switch)",
    "nsh": "Shell temporário com pacotes (ex: nsh htop ncdu); sai com exit",
    "nix-shell": "nix-shell que abre no fish em vez do bash",
    "gc": "git add . + commit (sem mensagem: \"Auto-commit\")",
    "mkcd": "Cria a pasta e entra nela",
    "extract": "Extrai zip, tar, rar, 7z...",
    "y": "yazi que muda de pasta ao sair",
}

# Nerd Font glyphs do renderizador do `ajuda` (só vão no TSV).
GLYPH_FUNCTION = "\U000f0295"
GLYPH_GITHUB = "\uf09b"
GLYPH_TAILSCALE = "\uf132"
GLYPH_LAN = "\uf233"
GLYPH_TUNNEL = "\uf0ec"
GLYPH_SSH = "\uf120"

DESC_PREFIX = "#: "
SCRIPT_HEAD_BYTES = 64 * 1024
TSV_DETAIL_LIMIT = 40

FISH_NAME = re.compile(r"^[^\s;|&<>()'\"$*?~#\\/]+$")
FISH_BLOCK_OPENERS = {"function", "if", "while", "for", "switch", "begin"}
FISH_PREFIX_WORDS = {"and", "or", "not", "!", "command", "builtin", "time", "exec"}
FUNCTION_ARG_OPTIONS = {"-a", "--argument-names", "-d", "--description", "-w", "--wraps",
                        "-e", "--on-event", "-v", "--on-variable", "-j", "--on-job-exit",
                        "-p", "--on-process-exit", "-s", "--on-signal", "-V", "--inherit-variable"}
FUNCTION_EVENT_OPTIONS = {"-e", "--on-event", "-v", "--on-variable", "-j", "--on-job-exit",
                          "-p", "--on-process-exit", "-s", "--on-signal"}
ABBR_ARG_OPTIONS = {"-p", "--position", "-r", "--regex", "-f", "--function", "-c", "--command"}
ABBR_OTHER_ACTIONS = {"-e", "--erase", "--rename", "-s", "--show", "-l", "--list",
                      "-q", "--query", "-h", "--help"}
SAVED_ALIAS = re.compile(r"^alias (\S+?)=(.*)$", re.S)
NIX_COMMAND = re.compile(
    r"(?:^|[;|&(]|\b(?:and|or|not|sudo|command|exec|time)\s)\s*"
    r"(?:nixos-rebuild|nix-shell|nix-env|nix-collect-garbage|nix-store|nix|nh|home-manager)"
    r"(?=\s|$|[;)])", re.M)
QUOTED = re.compile(r"'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\"", re.S)


class Catalog:
    def __init__(self):
        self.commands = []
        self.warnings = []
        self._ids = set()

    def add(self, category, kind, name, command, detail, description, source, glyph=""):
        base = f"{category}:{kind}:{name}"
        uid, n = base, 1
        while uid in self._ids:
            n += 1
            uid = f"{base}#{n}"
        self._ids.add(uid)
        self.commands.append({
            "id": uid,
            "category": category,
            "name": name,
            "command": command,
            "detail": detail,
            "description": description,
            "kind": kind,
            "source": source,
            "_glyph": glyph,
        })


def display_path(path, home):
    try:
        return "~/" + str(Path(path).relative_to(home))
    except ValueError:
        return str(path)


def copy_name(name):
    return name if re.fullmatch(r"[A-Za-z0-9_@%+=:,./-]+", name) else shlex.quote(name)


def read_text(path, catalog, home, limit=None):
    """Conteúdo de um arquivo opcional (segue symlink); ausente -> None sem aviso."""
    try:
        with open(path, "rb") as handle:
            data = handle.read() if limit is None else handle.read(limit)
    except FileNotFoundError:
        return None
    except OSError as error:
        catalog.warnings.append(f"{display_path(path, home)}: {error.strerror or error}")
        return None
    return data.decode("utf-8", errors="replace")


def fish_events(text):
    """Quebra um arquivo fish em eventos, sem interpretar nada além da sintaxe:

    ("desc", texto)       linha inteira "#: texto"
    ("gap",)              linha vazia ou comentário comum
    ("stmt", fonte, n)    um comando (separado por ; ou quebra de linha fora de
                          aspas e de (...)), começando na linha n
    ("unclosed", n)       aspas abertas na linha n e nunca fechadas
    """
    events = []
    buf = []
    blank = True          # buf ainda só tem espaço
    line_used = False     # a linha atual já teve comando ou comentário
    quote = None
    quote_line = 0
    parens = 0
    line = 1
    start_line = 1
    i, n = 0, len(text)

    def emit():
        nonlocal blank
        stmt = "".join(buf).strip()
        buf.clear()
        blank = True
        if stmt:
            events.append(("stmt", stmt, start_line))

    while i < n:
        c = text[i]
        if quote:
            buf.append(c)
            if c == "\\" and i + 1 < n and (text[i + 1] in "\\" + quote or quote == '"'):
                buf.append(text[i + 1])
                line += text[i + 1] == "\n"
                i += 2
                continue
            if c == quote:
                quote = None
            elif c == "\n":
                line += 1
            i += 1
            continue
        if c == "\\" and i + 1 < n:
            if text[i + 1] == "\n":
                buf.append(" ")
                line += 1
            else:
                buf.append(text[i:i + 2])
            i += 2
            continue
        if c == "#" and (blank or buf[-1] in " \t;|&("):
            end = text.find("\n", i)
            end = n if end < 0 else end
            if blank and parens == 0 and not line_used:
                comment = text[i:end]
                events.append(("desc", comment[len(DESC_PREFIX):].strip())
                              if comment.startswith(DESC_PREFIX) else ("gap",))
            line_used = True
            i = end
            continue
        if c in "\n;" and parens == 0:
            if c == "\n" and blank and not line_used:
                events.append(("gap",))
            emit()
            if c == "\n":
                line += 1
                line_used = False
            else:
                line_used = True
            i += 1
            continue
        if c == "\n":
            line += 1
        if blank and not c.isspace():
            blank = False
            start_line = line
        if c in "'\"":
            quote, quote_line = c, line
        elif c == "(":
            parens += 1
        elif c == ")" and parens:
            parens -= 1
        buf.append(c)
        i += 1
    emit()
    if quote:
        events.append(("unclosed", quote_line))
    return events


def fish_words(stmt):
    try:
        return shlex.split(stmt, posix=True)
    except ValueError:
        return stmt.split()


def split_options(words, with_arg):
    """[(opção, valor|None)], [posicionais] no estilo argparse do fish."""
    options, positional = [], []
    only_positional = False
    i = 0
    while i < len(words):
        word = words[i]
        i += 1
        if only_positional or not word.startswith("-") or word == "-":
            positional.append(word)
        elif word == "--":
            only_positional = True
        elif word.startswith("--") and "=" in word:
            key, _, value = word.partition("=")
            options.append((key, value))
        elif word in with_arg:
            options.append((word, words[i] if i < len(words) else ""))
            i += 1
        elif not word.startswith("--") and len(word) > 2 and word[:2] in with_arg:
            options.append((word[:2], word[2:]))
        else:
            options.append((word, None))
    return options, positional


def fish_category(name, text):
    """NixOS se o nome for nix*/home-manager* ou se chamar nix, nixos-rebuild etc.
    como comando (texto entre aspas não conta)."""
    if name.startswith(("nix", "home-manager")) or NIX_COMMAND.search(QUOTED.sub("''", text)):
        return "nix"
    return "shell"


def parse_fish(text, source, catalog):
    """alias/abbr/funções do fish com descrição em --description ou "#: " acima.

    Nada declarado dentro do corpo de uma função vira comando; blocos são
    contados por function/if/while/for/switch/begin ... end. Devolve
    {nome: campos do Catalog.add}; no mesmo arquivo a última definição vence.
    """
    items = {}

    def add(kind, name, detail, desc, text_for_category):
        desc = desc or FALLBACK_DESCRIPTIONS.get(name, "")
        items.pop(name, None)
        items[name] = (fish_category(name, text_for_category), kind, name, copy_name(name),
                       detail, desc, source, GLYPH_FUNCTION if kind == "function" else "")

    def finish(func):
        if not func["listed"]:
            return
        name, desc, body = func["name"], func["desc"], func["body"]
        saved = SAVED_ALIAS.match(desc)
        if saved and saved.group(1) == name:   # `alias --save` vira função assim
            add("alias", name, saved.group(2), "", saved.group(2))
            return
        first = fish_words(body[0])[:1] if len(body) == 1 else []
        detail = body[0] if first and first[0] not in FISH_BLOCK_OPENERS else "função"
        add("function", name, detail, desc, "\n".join(body))

    stack = []        # um item por bloco aberto: dict se for função, senão None
    desc_lines = []
    for event in fish_events(text):
        if event[0] == "desc":
            desc_lines.append(event[1])
            continue
        if event[0] == "gap":
            desc_lines = []
            continue
        if event[0] == "unclosed":
            catalog.warnings.append(f"{source}:{event[1]}: aspas não fechadas até o fim do arquivo")
            continue
        _, stmt, number = event
        desc = " ".join(part for part in desc_lines if part)
        desc_lines = []
        words = fish_words(stmt)
        while words and words[0] in FISH_PREFIX_WORDS:
            words = words[1:]
        if not words:
            continue
        head = words[0]
        func = next((block for block in reversed(stack) if block is not None), None)
        if head == "end":
            if stack:
                block = stack.pop()
                if block is not None:
                    finish(block)
            continue
        if func is not None:
            func["body"].append(stmt)
        if head in FISH_BLOCK_OPENERS:
            if head == "function" and func is None:
                options, positional = split_options(words[1:], FUNCTION_ARG_OPTIONS)
                name = positional[0] if positional else ""
                opts = dict(options)
                for key in ("-d", "--description"):
                    if opts.get(key):
                        desc = opts[key]
                listed = (bool(FISH_NAME.match(name)) and not name.startswith(("_", "fish_"))
                          and not any(key in FUNCTION_EVENT_OPTIONS for key, _ in options))
                stack.append({"name": name, "desc": desc, "body": [], "listed": listed,
                              "line": number})
            else:
                stack.append(None)
            continue
        if func is not None:
            continue
        if head == "alias":
            _, positional = split_options(words[1:], set())
            if not positional:
                continue
            name, sep, value = positional[0].partition("=")
            value = " ".join(([value] if sep else []) + positional[1:]).strip()
            if FISH_NAME.match(name) and value:
                add("alias", name, value, desc, value)
        elif head == "abbr":
            options, positional = split_options(words[1:], ABBR_ARG_OPTIONS)
            if not positional or any(key in ABBR_OTHER_ACTIONS for key, _ in options):
                continue
            function = next((v for k, v in options if k in ("-f", "--function") and v), "")
            expansion = " ".join(positional[1:]) or function
            if expansion:
                add("alias", positional[0], expansion, desc, expansion)
    for block in stack:
        if block is not None:
            catalog.warnings.append(f"{source}:{block['line']}: função {block['name'] or '?'} sem `end`")
            finish(block)
    return items


def scan_fish(home, catalog):
    """Na ordem do fish: conf.d/*.fish e depois config.fish rodam na partida (o
    último a definir vence); functions/*.fish só valem pro que ainda não existe."""
    base = home / ".config" / "fish"

    def fish_files(directory):
        try:
            return sorted((p for p in directory.iterdir() if p.suffix == ".fish"),
                          key=lambda p: p.name)
        except FileNotFoundError:
            return []
        except OSError as error:
            catalog.warnings.append(f"{display_path(directory, home)}: {error.strerror or error}")
            return []

    found = {}
    for path, startup in ([(p, True) for p in fish_files(base / "conf.d")]
                          + [(base / "config.fish", True)]
                          + [(p, False) for p in fish_files(base / "functions")]):
        text = read_text(path, catalog, home)
        if text is None:
            continue
        for name, item in parse_fish(text, display_path(path, home), catalog).items():
            if startup:
                found[name] = item
            else:
                found.setdefault(name, item)
    for item in found.values():
        catalog.add(*item)


def script_description(text):
    """"#: descrição" em qualquer linha; senão o primeiro comentário logo após o shebang."""
    lines = text.splitlines()
    tagged = next((line[len(DESC_PREFIX):].strip() for line in lines
                   if line.startswith(DESC_PREFIX)), None)
    if tagged is not None:
        return tagged
    for line in lines[1:]:
        if not line.startswith("#"):
            break
        body = line.lstrip("#").strip()
        if body and not line.startswith("#!") and not body.startswith(("shellcheck", "-*-")):
            return body
    return ""


def scan_scripts(directory, catalog, home):
    """Só scripts meus: arquivo regular (não symlink) começando com `#!`."""
    try:
        entries = sorted(Path(directory).iterdir(), key=lambda p: p.name)
    except FileNotFoundError:
        return
    except OSError as error:
        catalog.warnings.append(f"{display_path(directory, home)}: {error.strerror or error}")
        return
    for path in entries:
        if path.name.startswith("."):
            continue
        try:
            info = path.lstat()
        except OSError:
            continue
        if not stat.S_ISREG(info.st_mode):
            continue
        text = read_text(path, catalog, home, SCRIPT_HEAD_BYTES)
        if text is None or not text.startswith("#!"):
            continue
        catalog.add("scripts", "script", path.name, copy_name(path.name), "",
                    script_description(text), display_path(path, home))


def ssh_keyword(line):
    """`Key value` / `Key=value` -> (key minúsculo, [args])."""
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return None, []
    match = re.match(r"^([A-Za-z]+)\s*(?:=\s*|\s+)(.*)$", stripped)
    if not match:
        return stripped.lower(), []
    try:
        args = shlex.split(match.group(2), comments=True, posix=True)
    except ValueError:
        args = match.group(2).split()
    return match.group(1).lower(), args


def is_concrete_host(pattern):
    return bool(pattern) and not pattern.startswith("!") and not any(c in pattern for c in "*?%")


def ssh_glyph(hostname, forwards):
    if forwards:
        return GLYPH_TUNNEL
    if "github" in hostname:
        return GLYPH_GITHUB
    if hostname.startswith("100.") or hostname.endswith(".ts.net"):
        return GLYPH_TAILSCALE
    if hostname.startswith("192.168.") or hostname.startswith("10."):
        return GLYPH_LAN
    return GLYPH_SSH


def parse_ssh_config(text, source, catalog):
    """Hosts concretos (sem curingas/negação) com "#: descrição" acima do `Host`."""
    pending = []
    stanza = None

    def flush():
        if not stanza:
            return
        hostname, user, forwards = stanza["hostname"], stanza["user"], stanza["forwards"]
        desc = stanza["desc"]
        if forwards:
            desc = (desc + " · " if desc else "") + "túnel " + ", ".join(forwards)
        for alias in stanza["hosts"]:
            target = hostname or alias
            detail = f"{user}@{target}" if user else target
            catalog.add("ssh", "ssh", alias, "ssh " + shlex.quote(alias), detail, desc, source,
                        ssh_glyph(hostname, forwards))

    for line in text.splitlines():
        if line.startswith(DESC_PREFIX):
            if stanza is not None:
                flush()
                stanza = None
            pending.append(line[len(DESC_PREFIX):].strip())
            continue
        key, args = ssh_keyword(line)
        if key == "host":
            flush()
            stanza = {
                "hosts": [p for p in args if is_concrete_host(p)],
                "desc": " ".join(part for part in pending if part),
                "hostname": "", "user": "", "forwards": [],
            }
            pending = []
        elif key == "match":
            flush()
            stanza = None
            pending = []
        elif stanza is not None and args:
            if key == "hostname" and not stanza["hostname"]:
                stanza["hostname"] = args[0]
            elif key == "user" and not stanza["user"]:
                stanza["user"] = args[0]
            elif key == "localforward" and len(args) >= 2:
                listen = args[0] if ":" in args[0] or "/" in args[0] else "localhost:" + args[0]
                stanza["forwards"].append(f"{listen} → {args[1]}")
    flush()


def collect(home=None):
    home = Path(home) if home is not None else Path.home()
    catalog = Catalog()

    scan_fish(home, catalog)
    scan_scripts(home / ".local" / "bin", catalog, home)

    ssh_config = home / ".ssh" / "config"
    text = read_text(ssh_config, catalog, home)
    if text is not None:
        parse_ssh_config(text, display_path(ssh_config, home), catalog)

    for keys, description in DESKTOP_SHORTCUTS:
        catalog.add("desktop", "shortcut", keys, keys, "", description, "niri")

    return catalog


def to_json(catalog):
    commands = [{k: v for k, v in c.items() if not k.startswith("_")} for c in catalog.commands]
    return {"version": VERSION, "categories": CATEGORIES, "commands": commands,
            "warnings": list(catalog.warnings)}


def tsv_field(value):
    return re.sub(r"[\t\r\n]+", " ", value)


def to_tsv(catalog):
    rows = []
    for c in catalog.commands:
        detail = c["detail"]
        if c["kind"] in ("alias", "function") and len(detail) > TSV_DETAIL_LIMIT:
            detail = detail[:TSV_DETAIL_LIMIT - 1] + "…"
        fields = (TSV_SECTION[c["category"]], c["_glyph"], c["name"], detail, c["description"])
        rows.append("\t".join(tsv_field(f) for f in fields) + "\n")
    return "".join(rows)


def main(argv=None):
    parser = argparse.ArgumentParser(description="Catálogo dos meus comandos (só leitura).")
    fmt = parser.add_mutually_exclusive_group()
    fmt.add_argument("--json", dest="format", action="store_const", const="json")
    fmt.add_argument("--tsv", dest="format", action="store_const", const="tsv")
    parser.add_argument("--home", help="HOME alternativo (padrão: o do usuário)")
    args = parser.parse_args(argv)

    catalog = collect(args.home)
    if args.format == "tsv":
        sys.stdout.write(to_tsv(catalog))
        for warning in catalog.warnings:
            print(f"aviso: {warning}", file=sys.stderr)
    else:
        json.dump(to_json(catalog), sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
