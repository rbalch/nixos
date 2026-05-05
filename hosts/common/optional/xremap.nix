{ inputs, ... }:

{
  imports = [ inputs.xremap-flake.nixosModules.default ];

  services.xremap = {
    enable = true;
    serviceMode = "user";
    userName = "ryan";
    withHypr = true;

    config.keymap = [
      {
        name = "Chrome: SUPER -> Ctrl";
        remap = {
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
          "Super-a" = "C-a";
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
          "Super-0" = "C-0";
          "Super-1" = "C-1";
          "Super-2" = "C-2";
          "Super-3" = "C-3";
          "Super-4" = "C-4";
          "Super-5" = "C-5";
          "Super-6" = "C-6";
          "Super-7" = "C-7";
          "Super-8" = "C-8";
          "Super-9" = "C-9";
        };
        application.only = [ "code" "cursor" "code-url-handler" "cursor-url-handler" ];
      }
    ];
  };
}
