#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for script in "${REPO_DIR}"/gh-*/scripts/* "${REPO_DIR}"/scripts/*; do
  [ -f "${script}" ] && [ ! -x "${script}" ] && chmod +x "${script}" || true
done

for target_dir in "${HOME}/.agents/skills" "${HOME}/.claude/skills" "${HOME}/.gemini/config/skills"; do
  parent_dir="$(dirname "${target_dir}")"
  if [ -d "${target_dir}" ] && [ -w "${target_dir}" ]; then
    :
  elif [ ! -e "${target_dir}" ] && [ -w "${parent_dir}" ]; then
    mkdir -p "${target_dir}"
  else
    echo "Skipping ${target_dir} (not writable in current environment)"
    continue
  fi

  for skill_md in "${REPO_DIR}"/*/SKILL.md; do
    skill_dir="$(dirname "${skill_md}")"
    skill_name="$(basename "${skill_dir}")"
    ln -sfn "${skill_dir}" "${target_dir}/${skill_name}"
    echo "Linked ${skill_name} -> ${target_dir}/${skill_name}"
  done
done
