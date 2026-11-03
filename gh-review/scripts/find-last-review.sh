#!/usr/bin/env python3
import argparse, json, re, shutil, subprocess, sys

FINDINGS_PATTERN = re.compile(r"(^|\n)(- F[0-9]+ · P[123]|Approved\.)")


def gh_cmd(*args: str) -> list[str]:
    return ["mise", "exec", "--", "gh", *args] if shutil.which("mise") else ["gh", *args]


def get_pr_data(pr_arg: str | None, file_path: str | None) -> dict:
    if file_path:
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    args = ["pr", "view"] + ([pr_arg] if pr_arg else []) + ["--json", "number,headRefOid,headRefName,reviews,state,url"]
    res = subprocess.run(gh_cmd(*args), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Failed to query gh pr view: {res.stderr.strip()}")
    return json.loads(res.stdout)


def main():
    parser = argparse.ArgumentParser(description="Find last relevant review and determine next review stage.")
    parser.add_argument("pr", nargs="?")
    parser.add_argument("--file")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    try:
        pr_data = get_pr_data(args.pr, args.file)
    except Exception as e:
        sys.stderr.write(f"Error: {e}\n")
        sys.exit(1)

    head_oid = pr_data.get("headRefOid", "")
    relevant = [
        r for r in pr_data.get("reviews", [])
        if r.get("state") in ("CHANGES_REQUESTED", "APPROVED") or FINDINGS_PATTERN.search(r.get("body") or "")
    ]

    if not relevant:
        stage, stage_name, reason, prev_oid, last_rev = "Stage 2", "Stage 2. Deep code review and structured inline findings", "No prior reviews with findings or approvals found.", None, None
    else:
        last_rev = relevant[-1]
        prev_oid = (last_rev.get("commit") or {}).get("oid")
        body, state = last_rev.get("body") or "", last_rev.get("state")
        if prev_oid == head_oid and (state == "APPROVED" or body.strip().startswith("Approved.")):
            stage, stage_name, reason = "Stage 4", "Stage 4. Approval and pre-merge Coordinator record comment", f"Last review was an approval on current HEAD ({head_oid[:8]})."
        elif prev_oid and prev_oid != head_oid:
            stage, stage_name, reason = "Stage 3", "Stage 3. Incremental re-review and revert-test verification", f"New commits pushed since last review ({prev_oid[:8]} -> {head_oid[:8]})."
        else:
            stage, stage_name, reason = "Stage 2", "Stage 2. Deep code review and structured inline findings", f"Review on current HEAD ({head_oid[:8]}) was {state}."

    result = {
        "pr_number": pr_data.get("number"), "head_oid": head_oid, "prev_reviewed_sha": prev_oid,
        "recommended_stage": stage, "stage_name": stage_name, "reason": reason,
        "last_review": {"state": last_rev.get("state"), "author": (last_rev.get("author") or {}).get("login"), "commit_oid": prev_oid} if last_rev else None,
    }
    print(json.dumps(result, indent=2) if args.json else f"PR: #{pr_data.get('number')}\nCurrent HEAD: {head_oid}\nRecommended: {stage_name}\nReason: {reason}")


if __name__ == "__main__":
    main()
