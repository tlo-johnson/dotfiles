command -v jj &>/dev/null && source <(jj util completion zsh)

j() {
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
