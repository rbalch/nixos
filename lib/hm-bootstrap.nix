{ lib, pkgs, timeout ? 120 }:

# Home Manager activation step that runs a network installer once. It waits
# for Home Manager's files and packages, skips when ~/.local/bin/<name> already
# exists, and caps each run so a stalled download cannot abort activation or
# hit the unit timeout. The tool's own updater handles later upgrades.
name: { path ? [ ] }: commands:
let
    installer = pkgs.writeShellScript "bootstrap-${name}" ''
        set -euo pipefail
        export PATH=${lib.makeBinPath ([ pkgs.nodejs_24 pkgs.bash pkgs.coreutils ] ++ path)}:"$PATH"
        ${commands}
    '';
in lib.hm.dag.entryAfter [ "linkGeneration" "installPackages" ] ''
    if [ ! -x "$HOME/.local/bin/${name}" ]; then
        if run ${pkgs.coreutils}/bin/timeout ${toString timeout} ${installer}; then
            :
        else
            status=$?
            if [ "$status" -eq 124 ]; then
                printf '%s\n' "Warning: ${name} install timed out after ${toString timeout}s; the next rebuild will retry if it is still missing." >&2
            else
                printf '%s\n' "Warning: ${name} install failed (exit $status); the next rebuild will retry if it is still missing." >&2
            fi
        fi
    fi
''
