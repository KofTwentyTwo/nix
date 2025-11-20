-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Better window navigation
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Resize windows
map("n", "<C-Up>", ":resize -2<CR>", opts)
map("n", "<C-Down>", ":resize +2<CR>", opts)
map("n", "<C-Left>", ":vertical resize -2<CR>", opts)
map("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Better indenting
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Move text up and down
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Keep cursor in place when joining lines
map("n", "J", "mzJ`z", opts)

-- Center search results
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- Better search and replace
map("n", "<leader>r", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", { desc = "Replace word under cursor" })

-- Clear search highlights
map("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear search highlights" })

-- Toggle line numbers
map("n", "<leader>n", ":set number!<CR>", { desc = "Toggle line numbers" })

-- Toggle relative line numbers
map("n", "<leader>rn", ":set relativenumber!<CR>", { desc = "Toggle relative line numbers" })

-- Toggle wrap
map("n", "<leader>w", ":set wrap!<CR>", { desc = "Toggle wrap" })

-- Quick save
map("n", "<C-s>", ":w<CR>", opts)
map("i", "<C-s>", "<Esc>:w<CR>a", opts)

-- Quick quit
map("n", "<C-q>", ":q<CR>", opts)

-- Better buffer navigation
map("n", "<S-h>", ":bprevious<CR>", opts)
map("n", "<S-l>", ":bnext<CR>", opts)
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>ba", ":bufdo bdelete<CR>", { desc = "Delete all buffers" })

-- Better tab navigation
map("n", "<leader>tn", ":tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tc", ":tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>to", ":tabonly<CR>", { desc = "Close other tabs" })

-- Terminal
map("t", "<Esc>", "<C-\\><C-n>", opts)
map("t", "<C-h>", "<C-\\><C-n><C-w>h", opts)
map("t", "<C-j>", "<C-\\><C-n><C-w>j", opts)
map("t", "<C-k>", "<C-\\><C-n><C-w>k", opts)
map("t", "<C-l>", "<C-\\><C-n><C-w>l", opts)

-- LSP keymaps
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gr", vim.lsp.buf.references, { desc = "Go to references" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
map("n", "gt", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
map("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "Signature help" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>f", vim.lsp.buf.format, { desc = "Format" })

-- Diagnostic keymaps
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "<leader>de", vim.diagnostic.open_float, { desc = "Open diagnostic" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Set location list" })

-- Toggle diagnostics
map("n", "<leader>td", function()
  local current = vim.diagnostic.is_disabled()
  vim.diagnostic.enable(not current)
  print("Diagnostics " .. (current and "enabled" or "disabled"))
end, { desc = "Toggle diagnostics" })

-- Markdown preview keymaps
map("n", "<leader>mp", ":MarkdownPreviewToggle<CR>", { desc = "Toggle markdown preview" })
map("n", "<leader>ms", ":MarkdownPreviewStop<CR>", { desc = "Stop markdown preview" })


