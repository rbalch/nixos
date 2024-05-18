{ pkgs, ... }:

{
    programs.vscode = {
        enable = true;
        # package = (pkgs.vscode).overrideAttrs (oldAttrs: rec {
        #             version = "1.88.1";
        #             src = (builtins.fetchTarball {
        #                 url = "https://update.code.visualstudio.com/1.88.1/linux-x64/stable";
        #                 sha256 = "0nr1dh50skq0qfxxfz6kk6ic9xgqnjh06kaj4mizh774l1apg6ln";
        #             });
        #         });
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
            ms-azuretools.vscode-docker
            ms-vscode.makefile-tools
            ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh
            ms-python.python
            vscodevim.vim
        ];
    };
}
