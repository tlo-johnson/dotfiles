command -v jj &>/dev/null && source <(jj util completion zsh)

jj-pull() {
  local is_empty
  is_empty=$(jj log -r '@' --no-graph -T 'if(empty, "yes", "no")' 2>/dev/null)

  local target_bookmark=""
  if [[ "$is_empty" == "yes" ]]; then
    target_bookmark=$(jj log -r '@|@-' --no-graph -T 'separate("\n", bookmarks.map(|b| b.name()))' 2>/dev/null \
      | grep -v '@' | grep -v '^$' | head -1)
  fi

  jj git fetch "$@"

  if [[ -n "$target_bookmark" ]]; then
    echo "Switching to updated: $target_bookmark"
    jj new "$target_bookmark"
  fi
}

jj-push() {
  local bookmark="" extra_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --bookmark) bookmark="$2"; shift 2 ;;
      *)          extra_args+=("$1"); shift ;;
    esac
  done

  if [[ -z "$bookmark" ]]; then
    jj git push "${extra_args[@]}"
    return
  fi

  local is_empty target_rev
  is_empty=$(jj log -r '@' --no-graph -T 'if(empty, "yes", "no")' 2>/dev/null)
  target_rev="@"
  [[ "$is_empty" == "yes" ]] && target_rev="@-"

  if jj log -r "$bookmark" --no-graph --quiet &>/dev/null; then
    echo "Updating bookmark '$bookmark' to $target_rev"
    jj bookmark set "$bookmark" -r "$target_rev" --allow-backwards || return $?
  else
    echo "Creating bookmark '$bookmark' at $target_rev"
    jj bookmark create "$bookmark" -r "$target_rev" || return $?
  fi

  local remote
  if jj git remote list 2>/dev/null | grep -q '^origin '; then
    remote="origin"
  elif jj git remote list 2>/dev/null | grep -q '^main '; then
    remote="main"
  else
    echo "No 'origin' or 'main' remote configured" >&2
    return 1
  fi

  jj bookmark track "$bookmark" --remote "$remote" &>/dev/null

  jj git push --bookmark "$bookmark" --remote "$remote" "${extra_args[@]}"
}

j() {
  if [[ "$1" == "pl" ]]; then
    shift
    jj-pull "$@"
    return
  fi

  if [[ "$1" == "ps" ]]; then
    shift
    jj-push "$@"
    return
  fi

  if [[ "$1" != "m" ]]; then
    jj "$@"
    return
  fi

  local description="" pair_alias="" new_alias_def=""

  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pair)        pair_alias="$2";     shift 2 ;;
      --pair-alias)  new_alias_def="$2";  shift 2 ;;
      *)             description="$1";    shift   ;;
    esac
  done

  if [[ -n "$new_alias_def" ]]; then
    local alias_key="${new_alias_def%%=*}"
    local alias_value="${new_alias_def#*=}"
    jj-pair add "$alias_key" "$alias_value"
    pair_alias="$alias_key"
  fi

  if [[ -n "$description" ]]; then
    jj describe -m "$description" || return $?
  else
    jj describe || return $?
  fi

  if [[ -n "$pair_alias" ]]; then
    jj-pair "$pair_alias"
  fi
}
