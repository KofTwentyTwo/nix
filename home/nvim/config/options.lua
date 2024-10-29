local n_keymap = function(lhs, rhs)
   vim.api.nvim_set_keymap('n', lhs, rhs, { noremap = true, silent = true })
end

n_keymap("Y", "Y")

vim.o.tabstop=3
vim.o.shiftwidth=3
vim.o.expandtab = true
vim.o.number = true
vim.o.autoindent = true
vim.o.showmatch = true     
vim.o.ignorecase = true    
vim.o.hlsearch = true      
vim.o.incsearch = true
vim.o.wildmode=longest,list
vim.o.mouse=''                
vim.o.clipboard=unnamedplus
vim.o.cursorline = true    
vim.o.ttyfast = true        


