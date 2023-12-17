{ pkgs, ... }:

{
    programs.vscode = {
        enable = true;
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
        };
        # don't use ~/.vscode/extensions (ie: false here means you cannot install from vscode b/c of permissions)
        mutableExtensionsDir = false;
        extensions = with pkgs.vscode-extensions; [
            bbenoist.nix
            dracula-theme.theme-dracula
            github.copilot
            github.copilot-chat
            donjayamanne.githistory
            ms-vscode.makefile-tools
            ms-python.python
            # vscodevim.vim
        ];
    };
}
