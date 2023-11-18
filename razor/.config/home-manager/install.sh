#!/usr/bin/env bash

# set -e

BOLD_BLUE='\e[0;1;34m'
BOLD_GREEN='\e[0;1;32m'
BOLD_RED='\e[0;1;31m'
BOLD_YELLOW='\e[0;1;33m'

RESET='\e[0m'

# Utilities

err() {
    echo -e "${BOLD_RED}$1${RESET}"
}

warn() {
    echo -e "${BOLD_YELLOW}$1${RESET}"
}

info() {
    echo -e "${BOLD_BLUE}$1${RESET}"
}

success() {
    echo -e "${BOLD_GREEN}$1${RESET}"
}

set_perm() {
    chmod "$2" "$1" && success "--> Set permission of $1 to $2"
}

get_doc() {
    info "-> Fetching $1"
    lpass show --json "$1" > "$2.tmp"
    jq -r '.[0].note' "$2.tmp" > "$2"
    rm "$2.tmp"
    set_perm "$2" "$3"
}

get_lpass() {
    status=$(echo lpass status)
    if [ "$status" == "Not logged in." ]; then
        lpass login --trust ryan@balch.io
    else
        info "lpass already authenticated [skip]"
    fi
}

get_ssh() {
    mkdir -p "$HOME/.ssh" && info "-> Ensuring .ssh folder is present"
    chmod 700 "$HOME/.ssh" && success '--> Setting permissions for the .ssh folder'

    get_doc "ssh/zxrbzx" "$HOME/.ssh/zxrbzx" 600
    get_doc "ssh/github-eviltandem" "$HOME/.ssh/github-eviltandem" 600
    get_doc "ssh/github-huge" "$HOME/.ssh/github-huge" 600
}

add_unstable() {
    sudo nix-channel --add https://nixos.org/channels/nixos-unstable unstable
    sudo nix-channel --update
}

# add_unstable
# get_lpass
get_ssh
