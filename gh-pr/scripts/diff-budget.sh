#!/usr/bin/env python3
import argparse, fnmatch, json, os, subprocess, sys

EXCLUDE_PATTERNS = [
    "*_test.go", "*.test.ts", "*.test.tsx", "*.test.js", "*.test.jsx",
    "*.spec.ts", "*.spec.tsx", "*.spec.js", "*.spec.jsx",
    "*.stories.ts", "*.stories.tsx", "*.stories.js", "*.stories.jsx",
    "scripts/validate-*.sh", "*/validate-*.sh", "CHANGELOG.md", "*/CHANGELOG.md",
    "e2e/*", "*/e2e/*", "docs/plans/*", "*/docs/plans/*",
    "package-lock.json", "*/package-lock.json", "pnpm-lock.yaml", "*/pnpm-lock.yaml",
    "yarn.lock", "*/yarn.lock", "bun.lockb", "*/bun.lockb",
    "Cargo.lock", "*/Cargo.lock", "go.sum", "*/go.sum", "composer.lock", "*/composer.lock",
    "*.min.js", "*.min.css",
]


def is_excluded(path: str) -> bool:
    norm = path.replace("\\", "/")
    return any(fnmatch.fnmatch(norm, p) or fnmatch.fnmatch(os.path.basename(norm), p) for p in EXCLUDE_PATTERNS)


def get_diff_numstat(base_ref: str, include_uncommitted: bool = True) -> list[tuple[int, int, str]]:
    try:
        mb = subprocess.check_output(["git", "merge-base", base_ref, "HEAD"], stderr=subprocess.DEVNULL, text=True).strip()
    except subprocess.CalledProcessError:
        mb = base_ref
    cmd = ["git", "diff", "--numstat", mb] + ([] if include_uncommitted else ["HEAD"])
    records = []
    for line in subprocess.check_output(cmd, text=True).splitlines():
        parts = line.split("\t", 2)
        if len(parts) == 3:
            a, d, p = parts
            records.append((int(a) if a.isdigit() else 0, int(d) if d.isdigit() else 0, p))
    return records


def main():
    parser = argparse.ArgumentParser(description="Check diff size budget against base ref.")
    parser.add_argument("--base", default="origin/main")
    parser.add_argument("--soft-limit", type=int, default=500)
    parser.add_argument("--hard-limit", type=int, default=1000)
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    base_ref = args.base
    for cand in (base_ref, "main", "origin/master", "master", "HEAD~1"):
        if subprocess.run(["git", "rev-parse", "--verify", cand], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            base_ref = cand
            break

    counted, excluded = [], []
    added = deleted = 0
    for a, d, path in get_diff_numstat(base_ref):
        entry = {"path": path, "added": a, "deleted": d, "total": a + d}
        if is_excluded(path):
            excluded.append(entry)
        else:
            counted.append(entry)
            added += a
            deleted += d

    total = added + deleted
    if total <= args.soft_limit:
        verdict, code, msg = "PASS", 0, f"PASS: {total} lines (+{added}/-{deleted}) is within the {args.soft_limit}-line soft limit."
    elif total <= args.hard_limit:
        verdict, code, msg = "WARN", (1 if args.strict else 0), f"WARN: {total} lines (+{added}/-{deleted}) exceeds {args.soft_limit}-line soft limit, but within {args.hard_limit}-line hard limit."
    else:
        verdict, code, msg = "FAIL", 2, f"FAIL: {total} lines (+{added}/-{deleted}) exceeds {args.hard_limit}-line hard limit."

    if args.json:
        print(json.dumps({
            "verdict": verdict, "base_ref": base_ref, "total_counted_lines": total,
            "added": added, "deleted": deleted, "soft_limit": args.soft_limit, "hard_limit": args.hard_limit,
            "counted_files_count": len(counted), "excluded_files_count": len(excluded),
            "counted_files": counted, "excluded_files": excluded, "message": msg,
        }, indent=2))
    else:
        print(f"{msg}\nBase ref: {base_ref} | Counted files: {len(counted)} | Excluded files: {len(excluded)}")
        for f in counted:
            print(f"  +{f['added']:<4} -{f['deleted']:<4} {f['path']}")
        for f in excluded:
            print(f"  [excluded] +{f['added']:<4} -{f['deleted']:<4} {f['path']}")
    sys.exit(code)


if __name__ == "__main__":
    main()
