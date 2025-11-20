-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- General settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cursorcolumn = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = "↪ "
vim.opt.list = true
vim.opt.listchars = {
  tab = "→ ",
  eol = "↲",
  nbsp = "␣",
  trail = "•",
  extends = "⟩",
  precedes = "⟨",
}

-- Search settings
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Indentation
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2

-- Performance
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 10

-- UI
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.cmdheight = 1
vim.opt.showmode = false
vim.opt.laststatus = 3
vim.opt.ruler = false
vim.opt.showcmd = false
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Backup and swap
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.undoreload = 10000

-- Folding
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldcolumn = "1"
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- Mouse
vim.opt.mouse = "a"

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Split behavior
vim.opt.splitbelow = true
vim.opt.splitright = true

-- File handling
vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.confirm = true

-- History
vim.opt.history = 1000
vim.opt.shada = "!,'1000,<50,s10,h"

-- Other
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.spell = false
vim.opt.spelllang = { "en" }
vim.opt.conceallevel = 0
vim.opt.pumheight = 10
vim.opt.pumblend = 0
vim.opt.winblend = 0
vim.opt.smarttab = true
vim.opt.shiftround = true
vim.opt.infercase = true
vim.opt.diffopt = { "filler", "internal", "closeoff", "hiddenoff", "algorithm:minimal" }
vim.opt.fillchars = {
  fold = " ",
  vert = "│",
  eob = " ",
  diff = "╱",
  msgsep = "‾",
  foldopen = "▾",
  foldsep = "│",
  foldclose = "▸",
}
