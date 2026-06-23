#!/bin/sh

codegraph_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

codegraph_run() {
  mode="$1"
  repo="$(codegraph_repo_root)"
  if [ -z "$repo" ]; then
    return 0
  fi

  tool_path="$(command -v codegraph || true)"
  if [ -z "$tool_path" ]; then
    return 0
  fi

  graph_dir="$repo/.codegraph"
  mkdir -p "$graph_dir"
  log_file="$graph_dir/hooks.log"
  lock_dir="$graph_dir/hook.lock"

  if ! mkdir "$lock_dir" 2>/dev/null; then
    printf '%s [%s] skipped: another codegraph hook is running\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$mode" >> "$log_file"
    return 0
  fi

  codegraph_cleanup() {
    rmdir "$lock_dir" 2>/dev/null || true
  }
  trap codegraph_cleanup EXIT INT TERM

  codegraph_command() {
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
    sync)
      if [ -f "$graph_dir/codegraph.db" ]; then
        codegraph_command "$tool_path" sync --quiet "$repo"
      else
        codegraph_command "$tool_path" index --quiet "$repo"
      fi
      ;;
    *)
      printf '%s [%s] unknown mode\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$mode" >> "$log_file"
      ;;
  esac
  printf '%s [%s] end\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$mode" >> "$log_file"
  codegraph_cleanup
  trap - EXIT INT TERM
}

