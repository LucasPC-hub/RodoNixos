"""Conservative, age-gated cleanup of disposable per-user cache units.

Only whole, coherent units below fixed roots are removed (a Hugging Face repo
directory, an npm index bucket, one Codex staging tree, one log file). A unit
is removed only when every file and directory inside it has been inactive for
the category's grace period and no process of this user holds it open, uses it
as cwd/root, executes it, or maps it. Units containing foreign-owned entries,
mount points or unreadable directories are skipped and reported as errors.
"""

import argparse
import os
import re
import shutil
import stat
import subprocess
import sys
import time
import tomllib
from pathlib import Path

HOUR = 3600
DAY = 24 * HOUR
CACHE_GRACE = 7 * DAY  # HF repos, OMP document conversions, npm index buckets
TINY_MODEL_GRACE = 30 * DAY  # OMP prediction models load once per daemon start
LOG_GRACE = 7 * DAY
CODEX_STAGING_GRACE = 1 * HOUR  # staging copies are written in seconds

HOME = Path.home()
UID = os.getuid()
HF_REPO = re.compile(r"^(models|datasets|spaces)--.+")
OMP_LOG = re.compile(r"^omp\..+\.log$")
NPM_LOG = re.compile(r"^.+-debug-\d+\.log$")
BUNDLED_STAGING = re.compile(r"^openai-bundled\.staging-[0-9a-f-]{36}$")
UPGRADE_STAGING = re.compile(r"^marketplace-upgrade-[A-Za-z0-9]+$")


class UnitRejected(Exception):
    pass


class Processes:
    """Snapshot of paths and command lines used by this user's processes."""

    def __init__(self):
        self.paths = set()
        self.cmdlines = []
        self.unreadable = 0
        for entry in os.scandir("/proc"):
            if entry.name.isdigit():
                self._scan(entry)
        if self.unreadable:
            print(f"note: {self.unreadable} own process(es) not inspectable (non-dumpable)")

    def _add_link(self, link):
        try:
            target = os.readlink(link)
        except FileNotFoundError:  # fd closed or process exited meanwhile
            return
        self.paths.add(target.removesuffix(" (deleted)"))

    def _scan(self, entry):
        try:
            if entry.stat(follow_symlinks=False).st_uid != UID:
                return
            self.cmdlines.append(Path(entry.path, "cmdline").read_bytes().split(b"\0"))
            for name in ("cwd", "root", "exe"):
                self._add_link(f"{entry.path}/{name}")
            fd_dir = f"{entry.path}/fd"
            for fd in os.listdir(fd_dir):
                self._add_link(f"{fd_dir}/{fd}")
            with open(f"{entry.path}/maps", encoding="utf-8", errors="surrogateescape") as maps:
                for line in maps:
                    fields = line.rstrip("\n").split(maxsplit=5)
                    if len(fields) == 6 and fields[5].startswith("/"):
                        self.paths.add(fields[5].removesuffix(" (deleted)"))
        except (FileNotFoundError, ProcessLookupError):
            return  # process exited during the scan
        except PermissionError:
            self.unreadable += 1

    def uses(self, path):
        prefix = f"{path}/"
        return any(p == str(path) or p.startswith(prefix) for p in self.paths)

    def runs(self, names, scripts):
        for argv in self.cmdlines:
            # Node rewrites process titles, e.g. argv[0] == "npm exec foo".
            title = argv[0].decode(errors="replace").split(" ")[0] if argv else ""
            if os.path.basename(title) in names:
                return True
            if any(arg.decode(errors="replace").endswith(scripts) for arg in argv):
                return True
        return False


def mount_points():
    """Every mount point path from /proc/self/mountinfo (catches same-device bind mounts)."""
    points = set()
    with open("/proc/self/mountinfo", encoding="utf-8", errors="surrogateescape") as mountinfo:
        for line in mountinfo:
            field = line.split()[4]
            points.add(re.sub(r"\\([0-7]{3})", lambda m: chr(int(m.group(1), 8)), field))
    return points


class Cleaner:
    def __init__(self, dry_run):
        self.dry_run = dry_run
        self.errors = 0
        self.freed = 0
        self.removed = 0
        self.mounts = mount_points()

    def error(self, message):
        print(f"ERROR: {message}", file=sys.stderr)
        self.errors += 1

    def root(self, path):
        """Return path if it is a real, user-owned directory, None if absent."""
        if not os.path.lexists(path):
            print(f"skip {path}: absent")
            return None
        st = os.lstat(path)
        if os.path.realpath(path) != str(path) or not stat.S_ISDIR(st.st_mode):
            self.error(f"{path}: not a real directory (symlink in path?); category skipped")
            return None
        if st.st_uid != UID:
            self.error(f"{path}: not owned by uid {UID}; category skipped")
            return None
        return path

    def inspect(self, unit):
        """Walk unit without following symlinks; return (last_activity, bytes, locked_dirs)."""
        if os.path.realpath(unit.parent) != str(unit.parent):
            raise UnitRejected(f"parent {unit.parent} is reached through a symlink")
        top = os.lstat(unit)
        if top.st_dev != os.lstat(unit.parent).st_dev:
            raise UnitRejected("is a mount point")
        newest, size, locked = 0.0, 0, []
        pending = [(unit, top)]
        while pending:
            path, st = pending.pop()
            if st.st_uid != UID:
                raise UnitRejected(f"{path} is owned by uid {st.st_uid}")
            if st.st_dev != top.st_dev or str(path) in self.mounts:
                raise UnitRejected(f"{path} is a mount point")
            newest = max(newest, st.st_mtime, st.st_ctime)
            size += st.st_blocks * 512
            if stat.S_ISREG(st.st_mode):
                newest = max(newest, st.st_atime)  # relatime: reads refresh at least daily
            elif stat.S_ISDIR(st.st_mode):
                if st.st_mode & 0o700 != 0o700:
                    locked.append(path)
                try:
                    with os.scandir(path) as entries:
                        pending.extend((Path(e.path), e.stat(follow_symlinks=False)) for e in entries)
                except PermissionError as exc:
                    raise UnitRejected(f"cannot list {path}: {exc.strerror}") from exc
        return newest, size, locked

    def prune(self, units, grace, procs, label):
        """Remove each unit (Path or tuple of Paths removed together) once fully inactive."""
        now = time.time()
        for unit in units:
            group = unit if isinstance(unit, tuple) else (unit,)
            try:
                reports = [self.inspect(p) for p in group if os.path.lexists(p)]
            except FileNotFoundError:
                print(f"skip {group[0]}: changed while scanning")
                continue
            except (UnitRejected, OSError) as exc:
                self.error(f"{label} {group[0]}: {exc}; kept")
                continue
            if not reports:
                continue  # vanished since discovery
            idle = now - max(r[0] for r in reports)
            if idle < grace:
                continue
            if any(procs.uses(p) for p in group):
                print(f"keep {group[0]}: in use by a running process")
                continue
            size = sum(r[1] for r in reports)
            locked = [d for r in reports for d in r[2]]
            verb = "would remove" if self.dry_run else "remove"
            print(f"{verb} {label} {group[0]} ({human(size)}, idle {idle / DAY:.1f}d)")
            if self.dry_run:
                self.freed += size
                self.removed += 1
                continue
            try:
                if any(os.path.realpath(p.parent) != str(p.parent) for p in group):
                    raise OSError(f"parent of {group[0]} became a symlink")
                for directory in locked:
                    make_owner_writable(directory)
                for path in group:
                    if not os.path.lexists(path):
                        continue
                    if stat.S_ISDIR(os.lstat(path).st_mode):
                        shutil.rmtree(path)
                    else:
                        os.unlink(path)
            except OSError as exc:
                self.error(f"removing {group[0]} failed: {exc}")
                continue
            self.freed += size
            self.removed += 1


def make_owner_writable(directory):
    """Grant u+rwx on one directory without following a symlink at its final component."""
    fd = os.open(directory, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        os.fchmod(fd, stat.S_IMODE(os.fstat(fd).st_mode) | 0o700)
    finally:
        os.close(fd)


def human(size):
    for unit in ("B", "KiB", "MiB", "GiB"):
        if size < 1024:
            return f"{size:.0f}{unit}"
        size /= 1024
    return f"{size:.1f}TiB"


def children(directory, pattern, kind):
    """Direct children matching pattern whose lstat type is kind (S_ISDIR/S_ISREG)."""
    if not directory.is_dir() or directory.is_symlink():
        return []
    return sorted(
        Path(e.path)
        for e in os.scandir(directory)
        if pattern.match(e.name) and kind(e.stat(follow_symlinks=False).st_mode)
    )


def hf_hub_dir():
    if os.environ.get("HF_HUB_CACHE"):
        return Path(os.environ["HF_HUB_CACHE"])
    cache = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache"))
    return Path(os.environ.get("HF_HOME", cache / "huggingface")) / "hub"


def clean_huggingface(cleaner):
    # Only repo trees inside hub/ (blobs+refs+snapshots together) and their lock
    # directory; tokens and everything else at the HF root are never visited.
    hub = cleaner.root(hf_hub_dir())
    if hub is None:
        return
    procs = Processes()
    repos = [(repo, hub / ".locks" / repo.name) for repo in children(hub, HF_REPO, stat.S_ISDIR)]
    cleaner.prune(repos, CACHE_GRACE, procs, "huggingface repo")


def clean_omp(cleaner):
    procs = Processes()
    logs = cleaner.root(HOME / ".omp" / "logs")
    if logs is not None:
        cleaner.prune(children(logs, OMP_LOG, stat.S_ISREG), LOG_GRACE, procs, "omp log")
    # ~/.omp/agent/cache also holds composer.db (SQLite); only per-entry
    # subdirectories of the two regenerable caches below are candidates.
    cache = cleaner.root(HOME / ".omp" / "agent" / "cache")
    if cache is None:
        return
    any_entry = re.compile(r"^[^.]")
    for name, grace in (("document-conversions", CACHE_GRACE), ("tiny-models", TINY_MODEL_GRACE)):
        sub = cache / name
        if os.path.lexists(sub) and cleaner.root(sub) is not None:
            entries = [p for p in sorted(sub.iterdir()) if any_entry.match(p.name)]
            cleaner.prune(entries, grace, procs, f"omp {name}")


def clean_npm(cleaner, npm):
    result = subprocess.run([npm, "config", "get", "cache"], capture_output=True, text=True)
    if result.returncode != 0:
        cleaner.error(f"npm config get cache failed ({result.returncode}): {result.stderr.strip()}")
        return
    cache_root = cleaner.root(Path(result.stdout.strip()))
    if cache_root is None:
        return
    procs = Processes()
    logs = cache_root / "_logs"
    if os.path.lexists(logs) and cleaner.root(logs) is not None:
        cleaner.prune(children(logs, NPM_LOG, stat.S_ISREG), LOG_GRACE, procs, "npm log")
    index = cache_root / "_cacache" / "index-v5"
    if not os.path.lexists(index) or cleaner.root(index) is None:
        return
    if procs.runs({"npm", "npx"}, ("npm-cli.js", "npx-cli.js")) or procs.uses(cache_root / "_cacache"):
        print(f"keep {cache_root / '_cacache'}: npm/npx is running")
        return
    # Index buckets are the cache entries; content-v2 blobs are only reachable
    # through them, so expired buckets go first and `npm cache verify` then
    # garbage-collects the content no remaining entry references.
    buckets = sorted(Path(d, f) for d, _, files in os.walk(index) for f in files)
    before = cleaner.removed
    cleaner.prune(buckets, CACHE_GRACE, procs, "npm index bucket")
    if cleaner.dry_run or cleaner.removed == before:
        return
    verify = subprocess.run([npm, "cache", "verify", "--cache", str(cache_root)], capture_output=True, text=True)
    print(verify.stdout.strip())
    if verify.returncode != 0:
        cleaner.error(f"npm cache verify failed ({verify.returncode}): {verify.stderr.strip()}")


def codex_protected(codex):
    """Paths Codex is configured to read (marketplace sources and live symlink targets).

    Raises ValueError for any source it cannot normalise, so cleanup fails closed.
    """
    protected = set()
    config = codex / "config.toml"
    if config.exists():
        with open(config, "rb") as handle:
            marketplaces = tomllib.load(handle).get("marketplaces", {})
        if not isinstance(marketplaces, dict):
            raise ValueError("[marketplaces] is not a table")
        for name, entry in marketplaces.items():
            if not isinstance(entry, dict):
                raise ValueError(f"marketplace {name!r} is not a table")
            if "source" not in entry:
                continue
            source = entry["source"]
            if not isinstance(source, str) or not os.path.isabs(os.path.expanduser(source)):
                raise ValueError(f"marketplace {name!r} has non-absolute source {source!r}")
            protected.add(Path(os.path.realpath(os.path.expanduser(source))))
    for parent in (codex / ".tmp" / "bundled-marketplaces", codex / ".tmp" / "marketplaces"):
        if parent.is_dir():
            protected.update(Path(os.path.realpath(e)) for e in parent.iterdir() if e.is_symlink())
    return protected


def clean_codex_tmp(cleaner):
    codex = HOME / ".codex"
    tmp = cleaner.root(codex / ".tmp")
    if tmp is None:
        return
    try:
        protected = codex_protected(codex)
    except (OSError, ValueError, tomllib.TOMLDecodeError) as exc:
        cleaner.error(f"cannot read Codex marketplace sources: {exc}; Codex cleanup skipped")
        return
    # Only staging copies; the live bundled-marketplaces/openai-bundled and any
    # other non-staging marketplace never match these patterns.
    staging = children(tmp / "bundled-marketplaces", BUNDLED_STAGING, stat.S_ISDIR)
    staging += children(tmp / "marketplaces" / ".staging", UPGRADE_STAGING, stat.S_ISDIR)
    candidates = []
    for unit in staging:
        if any(p == unit or unit in p.parents for p in protected):
            print(f"keep {unit}: referenced as a live marketplace source")
        else:
            candidates.append(unit)
    cleaner.prune(candidates, CODEX_STAGING_GRACE, Processes(), "codex staging")


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("target", choices=("cache", "codex-tmp"))
    parser.add_argument("--dry-run", action="store_true", help="report candidates without changing anything")
    parser.add_argument("--npm", default="npm", help="npm executable (absolute path in the systemd unit)")
    args = parser.parse_args()

    cleaner = Cleaner(args.dry_run)
    if args.target == "cache":
        steps = (("huggingface", clean_huggingface), ("omp", clean_omp), ("npm", lambda c: clean_npm(c, args.npm)))
    else:
        steps = (("codex", clean_codex_tmp),)
    for name, step in steps:
        try:
            step(cleaner)
        except OSError as exc:  # e.g. a root vanished mid-scan; other categories still run
            cleaner.error(f"{name}: {exc}")
    verb = "would free" if args.dry_run else "freed"
    print(f"{args.target}: {cleaner.removed} unit(s), {verb} {human(cleaner.freed)}, {cleaner.errors} error(s)")
    return 1 if cleaner.errors else 0


if __name__ == "__main__":
    sys.exit(main())
