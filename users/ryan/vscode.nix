{ pkgs, ... }:

{
    programs.vscode = {
        enable = true;
        mutableExtensionsDir = false;

        profiles.default = {
            userSettings = {
                fontFamily = "MesloLGS NF";
                editor.fontFamily = "MesloLGS Nerd Font";
                editor.fontSize = 14;
				extensions.autoCheckUpdates = false;
				extensions.autoUpdate = false;
                terminal.integrated.fontFamily = "MesloLGS Nerd Font Mono";
                workbench.colorTheme = "Dracula";
                workbench.panel.defaultLocation = "right";
                files.autoSave = "afterDelay";
			    window.titleBarStyle = "custom";
                remote.autoForwardPortsSource = "hybrid";
                vim.handleKeys = { "<C-f>" = false; };
            };
            keybindings = [
                {
                    # Super+A → select-all. xremap leaves Super+A alone
                    # for VSCode so vim's <C-a> (increment) doesn't eat it.
                    key = "super+a";
                    command = "editor.action.selectAll";
                    when = "editorTextFocus";
                }
                {
                    key = "ctrl+j";
                    command = "-workbench.action.togglePanel";
                }
                {
                    key = "ctrl+shift+c";
                    command = "-workbench.action.terminal.openNativeConsole";
                }
                {
                    key = "ctrl+shift+c";
                    command = "editor.action.clipboardCopyAction";
                    when = "editorTextFocus";
                }
                {
                    key = "ctrl+shift+v";
                    command = "editor.action.clipboardPasteAction";
                    when = "editorTextFocus";
                }
                {
                    key = "ctrl+e";
                    command = "-workbench.action.quickOpen";
                    when = "terminalFocus";
                }
                {
                    # Ctrl+E → ENQ (0x05) so readline gets end-of-line.
                    # Nix strings have no \x escape, so decode via JSON.
                    key = "ctrl+e";
                    command = "workbench.action.terminal.sendSequence";
                    args = { text = builtins.fromJSON ''"\u0005"''; };
                    when = "terminalFocus";
                }
                {
                    # Shift+Enter → "\" + CR. Claude Code's TUI treats
                    # this as line continuation (matches what its own
                    # `/terminal-setup` writes for VSCode). Bare LF
                    # doesn't trigger newline-insert in the TUI even
                    # though Ctrl+J does — different code paths.
                    key = "shift+enter";
                    command = "workbench.action.terminal.sendSequence";
                    args = { text = "\\\r"; };
                    when = "terminalFocus";
                }
                {
                    key = "super+enter";
                    command = "workbench.action.terminal.sendSequence";
                    args = { text = "\n"; };
                    when = "terminalFocus";
                }
                {
                    # Shift+Tab → CSI Z (back-tab). Claude Code uses this
                    # to cycle modes (Plan / Accept-edits / Default).
                    # VSCode otherwise eats Shift+Tab for panel focus nav.
                    # NOTE: the args.text string contains a literal ESC
                    # byte (0x1B) before "[Z" — invisible in plain text
                    # but real. `xxd` to confirm if it looks like just "[Z".
                    key = "shift+tab";
                    command = "workbench.action.terminal.sendSequence";
                    args = { text = "[Z"; };
                    when = "terminalFocus";
                }
            ];
            extensions = with pkgs.vscode-extensions; [
                bbenoist.nix
                bierner.markdown-mermaid
                charliermarsh.ruff
                dracula-theme.theme-dracula
                donjayamanne.githistory
                # googlecloudtools.cloudcode
                ms-azuretools.vscode-docker
                ms-vscode.makefile-tools
                ms-vscode-remote.remote-containers
                ms-vscode-remote.remote-ssh
                ms-python.python
                vscodevim.vim
            ];
        };
    };
}
