{ pkgs, ... }:

{
    environment.variables.EDITOR = "vim";

    environment.systemPackages = with pkgs; [
        ((vim_configurable.override { }).customize{
            name = "vim";
            # plugins
            vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
                start = [
                    nerdtree
                    python-syntax
                    undotree
                    vim-airline
                    vim-lastplace
                    vim-nix
                ];
                opt = [ ];
            };
            vimrcConfig.customRC = ''
                set tabstop=4
                set mouse=a "allow mouse in vim"
                set number relativenumber
                set clipboard=unnamedplus "remaps to system clipboard"
                syntax on
                filetype on
                nmap <F2> :NERDTreeToggle<CR>
                nnoremap <F5> :UndotreeToggle<CR>
            '';
        }
        )];
}