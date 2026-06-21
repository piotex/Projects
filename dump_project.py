from pathlib import Path

# ============================================================
# CONFIGURATION
# ============================================================

# Repository to export
REPO_PATH = r"/home/peter/github/Projects/debugging/process-100-percent-cpu-linux"

# Output file
OUTPUT_FILE = r"repository_dump.txt"

# Skip files larger than this size (MB)
MAX_FILE_SIZE_MB = 5

# Directories excluded from both tree and content export
BLACKLIST_DIRS = {
    ".git",
    ".idea",
    ".vscode",
    ".terraform",
    ".ansible",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    "node_modules",
    ".venv",
    "venv",
    "dist",
    "build",
    ".next",
    ".cache",
}

# Exact file names to exclude
BLACKLIST_FILES = {
    "tfplan.out",
    ".terraform.lock.hcl",
    ".DS_Store",
}

# File extensions to exclude
BLACKLIST_EXTENSIONS = {
    ".pyc",
    ".pyo",
    ".exe",
    ".dll",
    ".so",
    ".zip",
    ".tar",
    ".gz",
    ".7z",
    ".jar",
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".bmp",
    ".ico",
    ".pdf",
    ".mp4",
    ".mov",
    ".avi",
    ".tfstate",
    ".backup",
}

# ============================================================
# HELPERS
# ============================================================


def should_skip(path: Path) -> bool:
    """Return True if path should be ignored."""

    for part in path.parts:
        if part in BLACKLIST_DIRS:
            return True

    if path.name in BLACKLIST_FILES:
        return True

    if path.is_file() and path.suffix.lower() in BLACKLIST_EXTENSIONS:
        return True

    return False


def build_tree(root: Path) -> list[str]:
    """
    Generate tree structure like:

    repo/
    ├── README.md
    ├── app/
    │   ├── main.py
    │   └── Dockerfile
    └── terraform/
        └── main.tf
    """

    lines = [f"{root.name}/"]

    def walk(directory: Path, prefix: str = ""):
        items = sorted(
            [p for p in directory.iterdir() if not should_skip(p)],
            key=lambda p: (p.is_file(), p.name.lower()),
        )

        for index, item in enumerate(items):
            is_last = index == len(items) - 1

            connector = "└── " if is_last else "├── "
            display_name = f"{item.name}/" if item.is_dir() else item.name

            lines.append(f"{prefix}{connector}{display_name}")

            if item.is_dir():
                extension = "    " if is_last else "│   "
                walk(item, prefix + extension)

    walk(root)

    return lines


def collect_files(root: Path) -> list[Path]:
    """Collect files that should be exported."""

    files = []

    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue

        if should_skip(path):
            continue

        try:
            size_mb = path.stat().st_size / (1024 * 1024)

            if size_mb > MAX_FILE_SIZE_MB:
                print(
                    f"Skipping large file ({size_mb:.2f} MB): "
                    f"{path.relative_to(root)}"
                )
                continue

        except OSError:
            continue

        files.append(path)

    return files


# ============================================================
# EXPORT
# ============================================================


def export_repository() -> None:
    repo = Path(REPO_PATH).resolve()
    output = Path(OUTPUT_FILE).resolve()

    if not repo.exists():
        raise FileNotFoundError(f"Repository not found: {repo}")

    print(f"Scanning repository: {repo}")

    tree_lines = build_tree(repo)
    files = collect_files(repo)

    with output.open("w", encoding="utf-8") as f:
        f.write("=== PROJECT TREE ===\n\n")
        f.write("\n".join(tree_lines))
        f.write("\n\n")

        f.write("=== FILE CONTENTS ===\n")

        for file_path in files:
            relative_path = file_path.relative_to(repo)

            f.write("\n---\n")
            f.write(f"{repo.name}/{relative_path.as_posix()}\n\n")

            try:
                content = file_path.read_text(
                    encoding="utf-8",
                    errors="replace",
                )
                f.write(content)

            except Exception as exc:
                f.write(
                    f"<< READ ERROR: "
                    f"{type(exc).__name__}: {exc} >>"
                )

            f.write("\n")

    print(f"Export completed.")
    print(f"Output file: {output}")
    print(f"Files exported: {len(files)}")


if __name__ == "__main__":
    export_repository()