#!/bin/bash

# helper logging method
_e() { echo "$1" >> log; }

_main() {
  local i=1 cmd

  # find the subcommand
  while [[ "$i" -lt "$COMP_CWORD" ]]
  do
    local s="${COMP_WORDS[i]}"
    case "$s" in
      -*) ;;
      *)
        cmd="$s"
        break
        ;;
    esac
    (( i++ ))
  done

  if [[ "$i" -eq "$COMP_CWORD" ]]
  then
    local cur="${COMP_WORDS[COMP_CWORD]}"

    local commands="
    config
    devstack
    firewall
    help
    image
    instance
    local
    version
    workflow
    "

    COMPREPLY=()
    compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

    return # return early if we're still completing the 'current' command
  fi

  # we've completed the 'current' command and now need to call the next
  # completion function.
  # subcommands have their own completion functions
  case "$cmd" in
    config) _main_config ;;
    devstack) _main_devstack ;;
    firewall) _main_firewall ;;
    image) _main_image ;;
    instance) _main_instance ;;
    local) _main_local ;;
    workflow) _main_workflow ;;
    *)          ;;
  esac
}

_main_config ()
{
  local i=1 subcommand_index

  # find the subcommand
  while [[ $i -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[i]}"
    case "$s" in
    subcommand)
      subcommand_index=$i
      break
      ;;
    esac
    (( i++ ))
  done

  while [[ $subcommand_index -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[subcommand_index]}"
    case "$s" in
      init)
        COMPREPLY=()
        return
        ;;
      debug)
        COMPREPLY=()
        return
        ;;
      help)
        COMPREPLY=()
        return
        ;;
    esac
    (( subcommand_index++ ))
  done

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local commands="
  debug
  init
  help
  "

  COMPREPLY=()
  compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

  return # return early if we're still completing the 'current' command
}

_main_devstack ()
{
  while [[ $subcommand_index -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[subcommand_index]}"
    case "$s" in
      up)
        COMPREPLY=()
        return
        ;;
      stop)
        COMPREPLY=()
        return
        ;;
      make)
        COMPREPLY=()
        return
        ;;
      unmount)
        COMPREPLY=()
        return
        ;;
      mount)
        COMPREPLY=()
        return
        ;;
      help)
        COMPREPLY=()
        return
        ;;
    esac
    (( subcommand_index++ ))
  done

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local commands="
  help
  make
  mount
  stop
  unmount
  up
  "

  COMPREPLY=()
  compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

  return # return early if we're still completing the 'current' command
}

_main_firewall ()
{
  local i=1 subcommand_index

  # find the subcommand
  while [[ $i -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[i]}"
    case "$s" in
    subcommand)
      subcommand_index=$i
      break
      ;;
    esac
    (( i++ ))
  done

  while [[ $subcommand_index -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[subcommand_index]}"
    case "$s" in
      allow)
        _main_firewall_action
        return
        ;;
      deny)
        _main_firewall_action
        return
        ;;
      clean)
        COMPREPLY=()
        return
        ;;
      help)
        COMPREPLY=()
        return
        ;;
    esac
    (( subcommand_index++ ))
  done

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local commands="
  allow
  deny
  clean
  help
  "

  COMPREPLY=()
  compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

  return # return early if we're still completing the 'current' command
}

_main_firewall_action ()
{
  while [[ $subcommand_index -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[subcommand_index]}"
    case "$s" in
      create)
        COMPREPLY=()
        return
        ;;
      delete)
        COMPREPLY=()
        return
        ;;
      refresh)
        COMPREPLY=()
        return
        ;;
    esac
    (( subcommand_index++ ))
  done

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local commands="
  create
  delete
  refresh
  "

  COMPREPLY=()
  compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

  return # return early if we're still completing the 'current' command
}

_main_image ()
{
  local i=1 subcommand_index

  # find the subcommand
  while [[ $i -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[i]}"
    case "$s" in
    subcommand)
      subcommand_index=$i
      break
      ;;
    esac
    (( i++ ))
  done

  while [[ $subcommand_index -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[subcommand_index]}"
    case "$s" in
      create)
        COMPREPLY=()
        return
        ;;
      delete)
        COMPREPLY=()
        return
        ;;
      help)
        COMPREPLY=()
        return
        ;;
    esac
    (( subcommand_index++ ))
  done

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local commands="
  create
  delete
  help
  "

  COMPREPLY=()
  compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

  return # return early if we're still completing the 'current' command
}

_main_instance ()
{
  local i=1 subcommand_index

  # find the subcommand
  while [[ $i -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[i]}"
    case "$s" in
    subcommand)
      subcommand_index=$i
      break
      ;;
    esac
    (( i++ ))
  done

  while [[ $subcommand_index -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[subcommand_index]}"
    case "$s" in
      create)
        COMPREPLY=()
        return
        ;;
      delete)
        COMPREPLY=()
        return
        ;;
      deploy)
        COMPREPLY=()
        return
        ;;
      describe)
        COMPREPLY=()
        return
        ;;
      ip)
        COMPREPLY=()
        return
        ;;
      ping)
        COMPREPLY=()
        return
        ;;
      provision)
        COMPREPLY=()
        return
        ;;
      restart)
        COMPREPLY=()
        return
        ;;
      restrict)
        COMPREPLY=()
        return
        ;;
      run)
        COMPREPLY=()
        return
        ;;
      setup)
        COMPREPLY=()
        return
        ;;
      start)
        COMPREPLY=()
        return
        ;;
      status)
        COMPREPLY=()
        return
        ;;
      stop)
        COMPREPLY=()
        return
        ;;
      help)
        COMPREPLY=()
        return
        ;;
    esac
    (( subcommand_index++ ))
  done

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local commands="
  create
  delete
  deploy
  describe
  help
  ip
  ping
  provision
  restart
  restrict
  run
  setup
  start
  status
  stop
  "

  COMPREPLY=()
  compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

  return # return early if we're still completing the 'current' command
}

_main_local ()
{
  local i=1 subcommand_index

  # find the subcommand
  while [[ $i -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[i]}"
    case "$s" in
    subcommand)
      subcommand_index=$i
      break
      ;;
    esac
    (( i++ ))
  done

  while [[ $subcommand_index -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[subcommand_index]}"
    case "$s" in
      config)
        COMPREPLY=()
        return
        ;;
      help)
        COMPREPLY=()
        return
        ;;
      hosts)
        _main_local_hosts
        return
        ;;
      ssh)
        _main_local_ssh
        return
        ;;
    esac
    (( subcommand_index++ ))
  done

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local commands="
  config
  help
  hosts
  ssh
  "

  COMPREPLY=()
  compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

  return # return early if we're still completing the 'current' command
}

_main_local_hosts ()
{
  while [[ $subcommand_index -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[subcommand_index]}"
    case "$s" in
      revert)
        COMPREPLY=()
        return
        ;;
      config)
        COMPREPLY=()
        return
        ;;
    esac
    (( subcommand_index++ ))
  done

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local commands="
  revert
  config
  "

  COMPREPLY=()
  compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

  return # return early if we're still completing the 'current' command
}

_main_local_ssh ()
{
  while [[ $subcommand_index -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[subcommand_index]}"
    case "$s" in
      config)
        COMPREPLY=()
        return
        ;;
    esac
    (( subcommand_index++ ))
  done

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local commands="
  config
  "

  COMPREPLY=()
  compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

  return # return early if we're still completing the 'current' command
}

_main_workflow ()
{
  while [[ $subcommand_index -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[subcommand_index]}"
    case "$s" in
      help)
        COMPREPLY=()
        return
        ;;
      resume)
        COMPREPLY=()
        return
        ;;
      suspend)
        COMPREPLY=()
        return
        ;;
    esac
    (( subcommand_index++ ))
  done

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local commands="
  help
  resume
  suspend
  "

  COMPREPLY=()
  compgen -W "$commands" -- "$cur" | while IFS="" read -r line; do COMPREPLY+=("$line"); done

  return # return early if we're still completing the 'current' command
}

complete -o bashdefault -F _main sultan
