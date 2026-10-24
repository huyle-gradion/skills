#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SKILLS_DIR="${HOME}/.agents/skills"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"

mkdir -p "${AGENTS_SKILLS_DIR}" "${CLAUDE_SKILLS_DIR}"

for skill_dir in "${REPO_DIR}"/gh-*; do
  [ -d "${skill_dir}" ] || continue
  skill_name="$(basename "${skill_dir}")"
  ln -sfn "${skill_dir}" "${AGENTS_SKILLS_DIR}/${skill_name}"
  ln -sfn "../../.agents/skills/${skill_name}" "${CLAUDE_SKILLS_DIR}/${skill_name}"
  echo "Linked ${skill_name} -> ${AGENTS_SKILLS_DIR}/${skill_name} and ${CLAUDE_SKILLS_DIR}/${skill_name}"
done
