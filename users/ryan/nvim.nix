{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = false;
    vimAlias = false;
    defaultEditor = false;
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      tokyonight-nvim
      nvim-web-devicons
      nvim-treesitter.withAllGrammars
      telescope-nvim
      plenary-nvim
      which-key-nvim
      lualine-nvim
      bufferline-nvim
      nvim-tree-lua
      gitsigns-nvim
      indent-blankline-nvim
      nvim-autopairs
      comment-nvim
      vim-sleuth
    ];

    extraPackages = with pkgs; [
      ripgrep
      fd
      tree-sitter
    ];

    extraLuaConfig = builtins.readFile ./configs/nvim/init.lua;
  };
}
