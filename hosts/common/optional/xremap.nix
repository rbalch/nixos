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
        # Most Linux apps use Ctrl+C/V for copy and paste. Terminal apps and
        # mixed editor/terminal apps stay out of this rule so Super+C never
        # turns into SIGINT in a shell.
        name = "Global Super+C/V -> Ctrl+C/V";
        remap = {
          "Super-c" = "C-c";
          "Super-v" = "C-v";
        };
        application.not = [
          "com.mitchellh.ghostty"
          "code"
          "code-url-handler"
          "cursor"
          "cursor-url-handler"
          "dev.zed.Zed"
          "zed"
          "Wave"
          "dev.warp.Warp"
        ];
      }
      {
        # VSCode's Home Manager keybindings map Ctrl+Shift+C/V to copy and
        # paste in both its editor and terminal.
        name = "VSCode: terminal-safe copy/paste";
        remap = {
          "Super-c" = "C-Shift-c";
          "Super-v" = "C-Shift-v";
        };
        application.only = [ "code" "code-url-handler" ];
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
    ];
  };
}
