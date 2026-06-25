{ inputs, ... }:

{
  imports = [ inputs.xremap-flake.nixosModules.default ];

  services.xremap = {
    enable = true;
    serviceMode = "user";
    userName = "ryan";
    withHypr = true;
    watch = true;

    config.keymap = [
      {
        name = "Chrome: SUPER -> Ctrl";
        remap = {
          "Super-a" = "C-a";
          "Super-c" = "C-c";
          "Super-v" = "C-v";
          "Super-x" = "C-x";
          "Super-r" = "C-r";
          "Super-w" = "C-w";
          "Super-n" = "C-n";
          "Super-l" = "C-l";
          "Super-t" = "C-t";
        };
        application.only = [ "google-chrome" ];
      }
      {
        name = "VSCode/Cursor: SUPER -> Ctrl (Mac-style)";
        remap = {
          "Super-b" = "C-b";
          "Super-c" = "C-Shift-c";
          "Super-comma" = "C-comma";
          "Super-equal" = "C-Shift-grave";
          "Super-grave" = "C-Shift-grave";
          "Super-d" = "C-d";
          "Super-e" = "C-e";
          "Super-f" = "C-f";
          "Super-g" = "C-g";
          "Super-k" = "C-k";
          "Super-l" = "C-l";
          "Super-m" = "C-m";
          "Super-n" = "C-n";
          "Super-o" = "C-o";
          "Super-p" = "C-p";
          "Super-q" = "C-q";
          "Super-r" = "C-r";
          "Super-s" = "C-s";
          "Super-slash" = "C-slash";
          "Super-t" = "C-t";
          "Super-v" = "C-Shift-v";
          "Super-w" = "C-w";
          "Super-x" = "C-x";
          "Super-y" = "C-y";
          "Super-z" = "C-z";
        };
        application.only = [ "code" "cursor" "code-url-handler" "cursor-url-handler" ];
      }
      {
        name = "WaveTerm: SUPER -> Ctrl (terminal-safe)";
        remap = {
          "Super-c" = "C-Shift-c";
          "Super-v" = "C-Shift-v";
        };
        application.only = [ "Wave" ];
      }
      {
        name = "Warp: SUPER -> Ctrl (terminal-safe)";
        remap = {
          "Super-c" = "C-Shift-c";
          "Super-v" = "C-Shift-v";
        };
        application.only = [ "dev.warp.Warp" ];
      }
      {
        name = "Slack: SUPER -> Ctrl";
        remap = {
          "Super-c" = "C-c";
          "Super-v" = "C-v";
          "Super-x" = "C-x";
        };
        application.only = [ "slack" ];
      }
    ];
  };
}
