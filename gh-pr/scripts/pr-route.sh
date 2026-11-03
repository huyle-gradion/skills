#!/usr/bin/env python3
import argparse, json, re, shutil, subprocess


def gh_cmd(*args: str) -> list[str]:
    return ["mise", "exec", "--", "gh", *args] if shutil.which("mise") else ["gh", *args]


def probe_pr_status(pr_json_file: str | None = None) -> tuple[dict | None, str | None]:
    if pr_json_file:
        with open(pr_json_file, "r", encoding="utf-8") as f:
            return json.load(f), None
    cmd = gh_cmd("pr", "view", "--json", "number,state,title,baseRefName,headRefName,headRefOid,reviewDecision,mergeStateStatus,url")
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return (json.loads(proc.stdout), None) if proc.returncode == 0 else (None, proc.stderr.strip() or "NO_OPEN_PR")
    except Exception as e:
        return None, str(e)


def main():
    parser = argparse.ArgumentParser(description="Route gh-pr mode based on branch and PR state.")
    parser.add_argument("--file")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--mode-only", action="store_true")
    args = parser.parse_args()

    try:
        branch = subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()
    except Exception:
        branch = "unknown"

    m = re.search(r"issue-(\d+)", branch)
    issue_number = m.group(1) if m else None
    pr_data, pr_error = probe_pr_status(args.file)
    has_open_pr = bool(pr_data and pr_data.get("state") == "OPEN")

    if has_open_pr and pr_data:
        if pr_data.get("mergeStateStatus", "CLEAN") == "DIRTY":
            mode, mode_name, reason = 4, "Mode 4. Rebase or merge after a sibling PR lands", "PR has merge conflicts (mergeStateStatus: DIRTY)."
        elif (pr_data.get("reviewDecision") or "NONE") == "CHANGES_REQUESTED":
            mode, mode_name, reason = 3, "Mode 3. Address review findings and reply inline", "Review requested changes (reviewDecision: CHANGES_REQUESTED)."
        else:
            mode, mode_name, reason = 2, "Mode 2. Commit and push updates to an open pull request", f"Open PR #{pr_data.get('number')} exists with state OPEN and clean merge status."
    else:
        mode, mode_name = 1, "Mode 1. Open a new pull request"
        reason = f"No open pull request on current branch ({pr_error})." if pr_error else "No open pull request on current branch."

    if args.mode_only:
        print(mode)
        return

    out = {
        "mode": mode, "mode_name": mode_name, "branch": branch, "linked_issue": issue_number,
        "has_open_pr": has_open_pr, "pr_number": pr_data.get("number") if pr_data else None,
        "pr_title": pr_data.get("title") if pr_data else None, "pr_url": pr_data.get("url") if pr_data else None,
        "review_decision": pr_data.get("reviewDecision") if pr_data else None,
        "merge_state_status": pr_data.get("mergeStateStatus") if pr_data else None, "reason": reason,
    }
    if args.json:
        print(json.dumps(out, indent=2))
    else:
        print(f"Branch: {branch}")
        if issue_number:
            print(f"Linked Issue: #{issue_number}")
        print(f"Open PR: #{pr_data.get('number')} ({pr_data.get('url')})" if has_open_pr and pr_data else "Open PR: None")
        print(f"Decision: {mode_name}\nReason: {reason}")


if __name__ == "__main__":
    main()
