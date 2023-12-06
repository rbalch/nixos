{ config, pkgs, ... }:

{
    programs.zsh.enable = true;

    users.users.ryan = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "docker" "input"];
        shell = pkgs.zsh;
    };

    environment.variables.EDITOR = "vim";

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
        packages = [ pkgs.terminus_font ];
        font = "${pkgs.terminus_font}/share/consolefonts/ter-i28b.psf.gz";
        useXkbConfig = true;
    };

    fonts = {
        packages = with pkgs; [
            noto-fonts
            noto-fonts-cjk
            noto-fonts-emoji
            font-awesome
            (nerdfonts.override { fonts = [ "Meslo" ]; })
        ];
        fontconfig = {
            enable = true;
            defaultFonts = {
                monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
                serif = [ "Noto Serif" ];
                sansSerif = [ "Noto Sans" ];
            };
        };
    };

}
