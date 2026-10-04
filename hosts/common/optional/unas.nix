{ pkgs, ... }:

# UniFi UNAS 4 at nas.braindongle.com, mounted over SMB with a password.
# NFS on the UNAS has no user auth (All Squash maps every client to one
# anonymous user), so SMB is the authenticated path.
#
# The login lives in /etc/unas-credentials, created by hand on each host and
# kept out of git and the Nix store:
#
#   username=ryan
#   password=...
#
#   sudo install -m 600 -o root -g root /dev/stdin /etc/unas-credentials
#
# Copy with `rsync -rlt`, not `-a`: SMB cannot keep Linux owners or modes;
# uid/gid below make every file show as ryan's. `nas-mv` wraps that.
#
# Share limits, tested 2026-10-03: names are case-insensitive (`movies`
# overwrites `Movies`), `\` is rejected, symlinks are unsupported. Other
# Windows-illegal characters (: * ? " < > |) work through mapposix.
let
    # mv for the NAS: rsync, verify, then delete the source. Refuses up front
    # on names the share cannot hold, so nothing is half-moved.
    nas-mv = pkgs.writeShellApplication {
        name = "nas-mv";
        runtimeInputs = with pkgs; [ rsync coreutils findutils gnugrep ];
        text = ''
            usage() {
                cat >&2 <<EOF
            usage: nas-mv [-c] SRC... DEST

            rsync SRC to DEST, verify the copy, then delete SRC. Paths follow rsync:
              nas-mv ~/other/movies/ /mnt/unas/media/movies/   contents of movies -> media/movies
              nas-mv ~/other/movies  /mnt/unas/media/          movies -> media/movies
            Missing parent directories of DEST are created.
            Safe to rerun after an interruption; finished files are skipped.

              -c  verify by checksum (reads every file back over the network)
                  instead of size and modification time
            EOF
                exit 2
            }

            verify_flag=()
            if [[ ''${1:-} == -c ]]; then
                verify_flag=(--checksum)
                shift
            fi
            (( $# >= 2 )) || usage

            dest="''${*: -1}"
            srcs=("''${@:1:$#-1}")

            # Preflight: refuse anything the share would mangle or reject.
            fail=0
            for src in "''${srcs[@]}"; do
                if [[ ! -e $src ]]; then
                    echo "nas-mv: no such file: $src" >&2; fail=1; continue
                fi
                bad=$(find "$src" -name '*\\*')
                if [[ -n $bad ]]; then
                    printf 'nas-mv: names with \\ (the share rejects them):\n%s\n' "$bad" >&2; fail=1
                fi
                links=$(find "$src" -type l)
                if [[ -n $links ]]; then
                    printf 'nas-mv: symlinks (the share cannot store them):\n%s\n' "$links" >&2; fail=1
                fi
                dupes=$(find "$src" | sort -f | uniq -Di)
                if [[ -n $dupes ]]; then
                    printf 'nas-mv: names differing only by case (one would overwrite the other):\n%s\n' "$dupes" >&2; fail=1
                fi
            done
            (( fail == 0 )) || { echo "nas-mv: nothing copied or deleted" >&2; exit 1; }

            rsync -rlt --mkpath --partial --modify-window=1 --info=progress2 -- "''${srcs[@]}" "$dest"

            # Verify: a dry run that would still send any file means the copy is
            # incomplete. Lines starting with '.' are attribute-only (e.g. dir times).
            echo "nas-mv: verifying..."
            pending=$(rsync -rlt --modify-window=1 --dry-run --itemize-changes "''${verify_flag[@]}" \
                -- "''${srcs[@]}" "$dest" | grep -v '^\.' || true)
            if [[ -n $pending ]]; then
                printf 'nas-mv: copy does not match source; keeping originals:\n%s\n' "$pending" >&2
                exit 1
            fi

            for src in "''${srcs[@]}"; do
                rm -rf -- "$src"
                echo "nas-mv: moved $src -> $dest"
            done
        '';
    };
in
{
    environment.systemPackages = [ pkgs.cifs-utils nas-mv ];

    fileSystems."/mnt/unas" = {
        device = "//nas.braindongle.com/Personal-Drive";
        fsType = "cifs";
        options = [
            "credentials=/etc/unas-credentials"
            "uid=ryan"
            "gid=users"
            "file_mode=0644"
            "dir_mode=0755"
            # No `seal`: SMB encryption capped the UNAS CPU at ~90 MB/s write
            # and ~170 MB/s read; without it, 157 and 290 (2.5 Gb line rate).
            # Login stays protected; file data crosses the LAN in the clear.
            # Tested 2026-10-03, 4 GiB with fsync.
            "vers=3.1.1"
            # Mount on first access, unmount after 10 idle minutes. A missing
            # NAS then cannot block boot or resume; access just fails fast.
            "noauto"
            "_netdev"
            "x-systemd.automount"
            "x-systemd.idle-timeout=600"
            "x-systemd.mount-timeout=10s"
        ];
    };
}
