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
            };
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
    };
}
