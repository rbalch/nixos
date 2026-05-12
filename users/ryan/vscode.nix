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
                files.autoSave = "afterDelay";
			    window.titleBarStyle = "custom";
                remote.autoForwardPortsSource = "hybrid";
            };
            keybindings = [
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
                    key = "shift+enter";
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
