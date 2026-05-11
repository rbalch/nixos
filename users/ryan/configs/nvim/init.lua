-- leader must be set before any plugin loads
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.wrap = false
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.hlsearch = false
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.updatetime = 50
opt.cursorline = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.splitbelow = true
opt.splitright = true
opt.completeopt = "menuone,noselect"

require("tokyonight").setup({
  style = "night",
  transparent = false,
})
vim.cmd.colorscheme("tokyonight")

require("nvim-web-devicons").setup({})

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

require("telescope").setup({
  defaults = {
    layout_strategy = "horizontal",
    layout_config = { prompt_position = "top" },
    sorting_strategy = "ascending",
  },
})

require("which-key").setup({})

require("lualine").setup({
  options = {
    theme = "tokyonight",
    globalstatus = true,
  },
})

require("bufferline").setup({})

require("nvim-tree").setup({
  view = { width = 35 },
  renderer = { group_empty = true },
  filters = { dotfiles = false },
})

require("gitsigns").setup({})
require("ibl").setup({})
require("nvim-autopairs").setup({})
require("Comment").setup({})

local map = vim.keymap.set
local builtin = require("telescope.builtin")

map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
map("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
map("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
map("n", "<leader>fh", builtin.help_tags, { desc = "Help" })
map("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })
map("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })

map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle tree" })

map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })

map("v", "<", "<gv")
map("v", ">", ">gv")

map("v", "J", ":m '>+1<cr>gv=gv")
map("v", "K", ":m '<-2<cr>gv=gv")

map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- uncomment to disable arrow keys and force hjkl muscle memory
-- for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
--   map({ "n", "i", "v" }, key, "<Nop>")
-- end
