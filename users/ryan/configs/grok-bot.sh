set -euo pipefail

app_dir="${XDG_DATA_HOME:-$HOME/.local/share}/grok-bot"
app="$app_dir/Grok_Bot.AppImage"
previous="$app_dir/Grok_Bot.previous.AppImage"
feed='https://api2.cursor.sh/updates/api/update/linux-x64/sand/0.0.0/00000000-0000-0000-0000-000000000000/stable'
download=''
backup=''

cleanup() {
    if [ -n "$download" ]; then rm -f -- "$download"; fi
    if [ -n "$backup" ]; then rm -f -- "$backup"; fi
}
trap cleanup EXIT

install_latest() {
    mkdir -p -- "$app_dir"
    exec 9>"$app_dir/.update.lock"
    flock -x 9

    # Another launcher may have finished the first install while we waited.
    if [ "$mode" = launch ] && [ -f "$app" ]; then
        exec 9>&-
        return
    fi

    release="$(curl -fsSL --connect-timeout 10 --max-time 30 "$feed")"
    version="$(jq -er '.version | select(type == "string")' <<<"$release")"
    url="$(jq -er '.url | select(type == "string")' <<<"$release")"
    hash="$(jq -er '.sha256hash | select(type == "string")' <<<"$release")"

    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
       [[ ! "$url" =~ ^https://downloads\.cursor\.com/grokbot/stable/[a-f0-9]+/linux/x64/Grok_Bot_[0-9]+\.[0-9]+\.[0-9]+\.AppImage$ ]] ||
       [[ "${url##*/}" != "Grok_Bot_${version}.AppImage" ]] ||
       [[ ! "$hash" =~ ^[a-fA-F0-9]{64}$ ]]; then
        echo 'Grok Bot: release feed has invalid data' >&2
        exit 1
    fi

    hash="${hash,,}"
    if [ -f "$app" ] && [ "$(sha256sum "$app" | cut -d ' ' -f 1)" = "$hash" ]; then
        echo "Grok Bot $version is already installed."
        exec 9>&-
        return
    fi

    download="$(mktemp "$app_dir/.Grok_Bot.XXXXXX")"
    echo "Downloading Grok Bot $version..."
    curl -fL --connect-timeout 10 --max-time 300 "$url" -o "$download"
    printf '%s  %s\n' "$hash" "$download" | sha256sum -c -
    chmod +x -- "$download"

    if [ -f "$app" ]; then
        upgraded=yes
        backup="$(mktemp "$app_dir/.previous.XXXXXX")"
        cp -p --reflink=auto -- "$app" "$backup"
        mv -f -- "$backup" "$previous"
        backup=''
    fi
    mv -f -- "$download" "$app"
    download=''
    echo "Installed Grok Bot $version."
    if [ "${upgraded:-}" = yes ]; then
        echo 'Quit and reopen Grok Bot to use this release.'
    fi
    exec 9>&-
}

if [ "$#" -eq 1 ] && [[ "$1" = --help || "$1" = -h || "$1" = help ]]; then
    printf 'Usage: grok-bot [update|--help|APP_ARGS...]\n'
    printf '  update    Download and verify the current Grok Bot release.\n'
    exit
fi

if [ "${1:-}" = update ] && [ "$#" -eq 1 ]; then
    mode=update
    install_latest
    exit
fi

mode=launch
if [ ! -f "$app" ]; then
    install_latest
fi

printf -v GROK_BOT_ARGS '%q ' \
    --ozone-platform=wayland --password-store=gnome-libsecret "$@"
export GROK_BOT_ARGS
exec appimage-run "$app"
