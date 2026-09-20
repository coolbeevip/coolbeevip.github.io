#!/usr/bin/env bash

set -euo pipefail

readonly START_MARKER="# >>> codex gateway wrapper >>>"
readonly END_MARKER="# <<< codex gateway wrapper <<<"

if [[ -z "${HOME:-}" ]]; then
  printf 'Installation failed: HOME is not set.\n' >&2
  exit 1
fi

detect_shell_rc() {
  if [[ -n "${CODEX_SHELL_RC:-}" ]]; then
    printf '%s\n' "$CODEX_SHELL_RC"
    return
  fi

  case "${SHELL:-}" in
    */zsh)
      printf '%s\n' "${ZDOTDIR:-$HOME}/.zshrc"
      ;;
    */bash)
      if [[ "$(uname -s)" == "Darwin" ]]; then
        printf '%s\n' "$HOME/.bash_profile"
      else
        printf '%s\n' "$HOME/.bashrc"
      fi
      ;;
    *)
      printf 'Installation failed: only Bash and Zsh are detected automatically.\n' >&2
      printf 'Set CODEX_SHELL_RC to the shell startup file you want to update.\n' >&2
      exit 1
      ;;
  esac
}

shell_rc="$(detect_shell_rc)"
shell_rc_dir="$(dirname "$shell_rc")"

mkdir -p "$shell_rc_dir"
touch "$shell_rc"

start_count="$(grep -Fxc "$START_MARKER" "$shell_rc" || true)"
end_count="$(grep -Fxc "$END_MARKER" "$shell_rc" || true)"

if [[ "$start_count" -gt 1 || "$end_count" -gt 1 || "$start_count" != "$end_count" ]]; then
  printf 'Installation failed: the managed block in %s is incomplete.\n' "$shell_rc" >&2
  exit 1
fi

tmp_file="$(mktemp "${TMPDIR:-/tmp}/codex-gateway.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

strip_managed_block() {
  awk -v start="$START_MARKER" -v end="$END_MARKER" '
    $0 == start { skipping = 1; blank_lines = ""; next }
    $0 == end   { skipping = 0; next }
    !skipping && $0 == "" { blank_lines = blank_lines ORS; next }
    !skipping {
      printf "%s", blank_lines
      blank_lines = ""
      print
    }
  ' "$shell_rc"
}

backup_shell_rc() {
  if [[ -s "$shell_rc" ]]; then
    backup_path="${shell_rc}.codex-gateway.bak.$(date +%Y%m%d%H%M%S)"
    cp -p "$shell_rc" "$backup_path"
    printf 'Backup created: %s\n' "$backup_path"
  fi
}

if [[ "${1:-}" == "--uninstall" ]]; then
  if [[ "$start_count" == "0" ]]; then
    printf 'Codex gateway wrapper is not installed.\n'
    exit 0
  fi

  strip_managed_block > "$tmp_file"
  backup_shell_rc
  cp "$tmp_file" "$shell_rc"
  printf 'Codex gateway wrapper removed from %s.\n' "$shell_rc"
  printf 'Restart your terminal to apply the change.\n'
  exit 0
fi

strip_managed_block > "$tmp_file"

cat >> "$tmp_file" <<'EOF'

# >>> codex gateway wrapper >>>
# Override Codex with CODEX_MODEL / CODEX_BASE_URL / CODEX_API_KEY for this shell.
codex() {
  local args=()
  [[ -n "${CODEX_MODEL:-}" ]] && args+=( -m "$CODEX_MODEL" )
  [[ -n "${CODEX_BASE_URL:-}" ]] && args+=( -c "model_providers.gateway.base_url=\"$CODEX_BASE_URL\"" )
  command codex "${args[@]}" "$@"
}
# <<< codex gateway wrapper <<<
EOF

if cmp -s "$tmp_file" "$shell_rc"; then
  printf 'Codex gateway wrapper is already up to date: %s\n' "$shell_rc"
  exit 0
fi

backup_shell_rc
cp "$tmp_file" "$shell_rc"

printf 'Codex gateway wrapper installed in %s.\n' "$shell_rc"
printf 'Restart your terminal, then run codex.\n'

if ! command -v codex >/dev/null 2>&1; then
  printf 'Note: codex was not found. Install Codex CLI before using the wrapper.\n'
fi
