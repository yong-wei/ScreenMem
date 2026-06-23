#!/bin/sh

crg_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

crg_run() {
  mode="$1"
  repo="$(crg_repo_root)"
  if [ -z "$repo" ]; then
    return 0
  fi

  tool_path="$(command -v code-review-graph || true)"
  if [ -z "$tool_path" ]; then
    return 0
  fi

  graph_dir="$repo/.code-review-graph"
  mkdir -p "$graph_dir"
  log_file="$graph_dir/hooks.log"
  lock_dir="$graph_dir/hook.lock"

  if ! mkdir "$lock_dir" 2>/dev/null; then
    printf '%s [%s] skipped: another code-review-graph hook is running\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$mode" >> "$log_file"
    return 0
  fi

  crg_cleanup() {
    rmdir "$lock_dir" 2>/dev/null || true
  }
  trap crg_cleanup EXIT INT TERM

  crg_command() {
    "$@" >> "$log_file" 2>&1
    status="$?"
    if [ "$status" -ge 128 ]; then
      printf '%s [%s] command exit_status=%s signal=%s: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$mode" "$status" "$((status - 128))" "$*" >> "$log_file"
    else
      printf '%s [%s] command exit_status=%s: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$mode" "$status" "$*" >> "$log_file"
    fi
    return 0
  }

  printf '%s [%s] start tool=%s repo=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$mode" "$tool_path" "$repo" >> "$log_file"
  case "$mode" in
    update)
      crg_command "$tool_path" update --repo "$repo"
      ;;
    build)
      crg_command "$tool_path" build --repo "$repo"
      ;;
    *)
      printf '%s [%s] unknown mode\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$mode" >> "$log_file"
      ;;
  esac
  printf '%s [%s] end\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$mode" >> "$log_file"
  crg_cleanup
  trap - EXIT INT TERM
}

