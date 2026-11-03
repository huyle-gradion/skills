#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"

echo "=== 1. Validating SKILL.md frontmatter ==="
ERRORS=0

for skill_md in */SKILL.md; do
  [ -f "$skill_md" ] || continue
  echo "Checking $skill_md..."

  first_line=$(head -n 1 "$skill_md")
  if [ "$first_line" != "---" ]; then
    echo "  [FAIL] Missing starting frontmatter delimiter '---' in $skill_md"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  name=$(grep -E '^name:[[:space:]]*[a-zA-Z0-9_-]+' "$skill_md" || true)
  if [ -z "$name" ]; then
    echo "  [FAIL] Missing or invalid 'name' in $skill_md"
    ERRORS=$((ERRORS + 1))
  fi

  desc=$(grep -E '^description:' "$skill_md" || true)
  if [ -z "$desc" ]; then
    echo "  [FAIL] Missing 'description' in $skill_md"
    ERRORS=$((ERRORS + 1))
  fi
done

echo "=== 2. Validating Semantic Versioning (VERSION and CHANGELOG.md) ==="
if [ ! -f "VERSION" ]; then
  echo "  [FAIL] Missing VERSION file"
  ERRORS=$((ERRORS + 1))
else
  version_str=$(tr -d '[:space:]' < VERSION)
  if ! [[ "$version_str" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
    echo "  [FAIL] Invalid SemVer in VERSION: '$version_str'"
    ERRORS=$((ERRORS + 1))
  else
    echo "  [OK] VERSION '$version_str' is valid SemVer."
  fi

  if [ ! -f "CHANGELOG.md" ]; then
    echo "  [FAIL] Missing CHANGELOG.md"
    ERRORS=$((ERRORS + 1))
  elif ! grep -qF "## [$version_str]" CHANGELOG.md; then
    echo "  [FAIL] CHANGELOG.md is missing section '## [$version_str]'"
    ERRORS=$((ERRORS + 1))
  else
    echo "  [OK] CHANGELOG.md documents version [$version_str]."
  fi
fi

echo "=== 3. Validating markdown relative links ==="
if ! python3 - << 'EOF'
import os
import re
import sys

link_pattern = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')
errors = 0

for root, _, files in os.walk('.'):
    if '/.git' in root:
        continue
    for file in files:
        if not file.endswith('.md'):
            continue
        filepath = os.path.join(root, file)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        for match in link_pattern.finditer(content):
            target = match.group(2).strip()
            if target.startswith(('http://', 'https://', '#', 'mailto:')) or '<' in target:
                continue

            clean_target = target.split('#')[0]
            if not clean_target:
                continue

            base_dir = os.path.dirname(filepath)
            resolved = os.path.normpath(os.path.join(base_dir, clean_target))
            if not os.path.exists(resolved):
                print(f"  [FAIL] Broken link in {filepath}: '{target}' -> '{resolved}' does not exist")
                errors += 1

if errors > 0:
    sys.exit(1)
print("  [OK] All markdown relative links resolve.")
EOF
then
  ERRORS=$((ERRORS + 1))
fi

echo "=== 4. Validating helper scripts syntax and execution permissions ==="
for script in */scripts/* scripts/*; do
  [ -f "$script" ] || continue
  if [ ! -x "$script" ]; then
    echo "  [FAIL] Script is not executable: $script"
    ERRORS=$((ERRORS + 1))
  fi

  first_line=$(head -n 1 "$script")
  if [[ "$first_line" == *"python"* ]]; then
    if ! python3 -B -c "import ast, sys; ast.parse(open(sys.argv[1], encoding='utf-8').read(), sys.argv[1])" "$script"; then
      echo "  [FAIL] Python syntax error in $script"
      ERRORS=$((ERRORS + 1))
    else
      echo "  [OK] Python syntax valid: $script"
    fi
  elif [[ "$first_line" == *"bash"* ]] || [[ "$first_line" == *"sh"* ]]; then
    if ! bash -n "$script"; then
      echo "  [FAIL] Bash syntax error in $script"
      ERRORS=$((ERRORS + 1))
    else
      echo "  [OK] Bash syntax valid: $script"
    fi
  fi
done

echo "=== 5. Running unit tests on helper scripts ==="
if ! python3 - << 'EOF'
import json
import subprocess
import tempfile
import sys
import os

res = subprocess.run(["./gh-pr/scripts/diff-budget.sh", "--json"], capture_output=True, text=True)
if res.returncode != 0:
    print(f"  [FAIL] diff-budget.sh failed: {res.stderr}")
    sys.exit(1)
data = json.loads(res.stdout)
assert "verdict" in data and "total_counted_lines" in data, "diff-budget JSON missing fields"
print("  [OK] diff-budget.sh correctly executed and produced JSON verdict.")

with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
    json.dump({"number": 42, "state": "OPEN", "mergeStateStatus": "CLEAN", "reviewDecision": "CHANGES_REQUESTED", "url": "https://github.com/test/pull/42"}, f)
    tmp_name = f.name

try:
    res = subprocess.run(["./gh-pr/scripts/pr-route.sh", "--file", tmp_name, "--json"], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"  [FAIL] pr-route.sh failed: {res.stderr}")
        sys.exit(1)
    route_data = json.loads(res.stdout)
    assert route_data["mode"] == 3, f"Expected Mode 3 for CHANGES_REQUESTED, got {route_data['mode']}"
    print("  [OK] pr-route.sh correctly routed to Mode 3 on CHANGES_REQUESTED.")
finally:
    os.remove(tmp_name)

with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
    json.dump([
        {"number": 1, "author": {"login": "dev1"}, "files": [{"path": "a.txt"}]},
        {"number": 2, "author": {"login": "dev2"}, "files": [{"path": "a.txt"}]}
    ], f)
    tmp_name = f.name

try:
    res = subprocess.run(["./gh-review/scripts/check-sibling-conflicts.sh", "--file", tmp_name, "--json"], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"  [FAIL] check-sibling-conflicts.sh failed: {res.stderr}")
        sys.exit(1)
    conflict_data = json.loads(res.stdout)
    assert conflict_data["conflict_count"] == 1, "Expected 1 conflict"
    print("  [OK] check-sibling-conflicts.sh successfully identified conflicting files.")
finally:
    os.remove(tmp_name)

with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
    json.dump({
        "number": 10,
        "headRefOid": "2222222222222222222222222222222222222222",
        "reviews": [{
            "state": "APPROVED",
            "commit": {"oid": "1111111111111111111111111111111111111111"},
            "body": "Approved."
        }]
    }, f)
    tmp_name = f.name

try:
    res = subprocess.run(["./gh-review/scripts/find-last-review.sh", "--file", tmp_name, "--json"], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"  [FAIL] find-last-review.sh failed: {res.stderr}")
        sys.exit(1)
    rev_data = json.loads(res.stdout)
    assert rev_data["recommended_stage"] == "Stage 3", f"Expected Stage 3, got {rev_data['recommended_stage']}"
    print("  [OK] find-last-review.sh successfully detected incremental diff requirement.")
finally:
    os.remove(tmp_name)

print("  [OK] All script unit tests passed.")
EOF
then
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
  echo "Validation FAILED with $ERRORS error(s)."
  exit 1
fi

echo "All skill validations and tests PASSED."
exit 0
