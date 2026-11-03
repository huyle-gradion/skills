#!/usr/bin/env python3
import argparse, itertools, json, shutil, subprocess, sys


def gh_cmd(*args: str) -> list[str]:
    return ["mise", "exec", "--", "gh", *args] if shutil.which("mise") else ["gh", *args]


def get_open_prs(file_path: str | None = None) -> list[dict]:
    if file_path:
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    res = subprocess.run(gh_cmd("pr", "list", "--state", "open", "--json", "number,title,author,headRefName,files"), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Failed to query gh pr list: {res.stderr.strip()}")
    return json.loads(res.stdout)


def main():
    parser = argparse.ArgumentParser(description="Find overlapping file conflicts across open PRs.")
    parser.add_argument("--file")
    parser.add_argument("--target-pr", type=int)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    try:
        prs = get_open_prs(args.file)
    except Exception as e:
        sys.stderr.write(f"Error: {e}\n")
        sys.exit(1)

    pr_files = {pr["number"]: {item["path"] for item in pr.get("files", []) if "path" in item} for pr in prs}
    conflicts = []
    for pr_a, pr_b in itertools.combinations(prs, 2):
        num_a, num_b = pr_a["number"], pr_b["number"]
        if args.target_pr and args.target_pr not in (num_a, num_b):
            continue
        overlap = sorted(pr_files[num_a].intersection(pr_files[num_b]))
        if overlap:
            conflicts.append({
                "pr_a": num_a, "author_a": (pr_a.get("author") or {}).get("login"),
                "pr_b": num_b, "author_b": (pr_b.get("author") or {}).get("login"),
                "overlapping_file_count": len(overlap), "overlapping_files": overlap,
            })

    if args.json:
        print(json.dumps({"conflicts": conflicts, "conflict_count": len(conflicts)}, indent=2))
        return
    if not conflicts:
        print("No overlapping file conflicts found across open PRs.")
        return

    involved = sorted({c["pr_a"] for c in conflicts} | {c["pr_b"] for c in conflicts})
    authors = sorted({c["author_a"] for c in conflicts if c.get("author_a")} | {c["author_b"] for c in conflicts if c.get("author_b")})
    mentions = " ".join(f"@{a}" for a in authors) or "@author"
    print(f"{mentions} These {len(involved)} PRs modify overlapping files and will conflict after the first merges:\n")
    for c in conflicts:
        files_str = ", ".join(f"`{p}`" for p in c["overlapping_files"][:5])
        if len(c["overlapping_files"]) > 5:
            files_str += f" and {len(c['overlapping_files']) - 5} more"
        print(f"- #{c['pr_a']} and #{c['pr_b']} conflict in {c['overlapping_file_count']} files ({files_str}).")
    print(f"\nMerge order: {', then '.join(f'#{n}' for n in involved)}. After each merge, rebase the next PR onto `main`.")


if __name__ == "__main__":
    main()
