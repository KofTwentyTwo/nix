set tabstop=3
set shiftwidth=3
set expandtab 
set number
set autoindent

set nocompatible            " disable compatibility to old-time vi
set showmatch               " show matching 
set ignorecase              " case insensitive 
set mouse=v                 " middle-click paste with 
set hlsearch                " highlight search 
set incsearch
nnoremap Y Y                " Make Shift-Y yank the current line old school style


set wildmode=longest,list   " get bash-like tab completions
set cc=200                  " set an 120 column border for good coding style
filetype plugin indent on   " allow auto-indenting depending on file type
syntax on                   " syntax highlighting
set mouse=                  " Turn off neovim mouse - work like a normal terminal 
set clipboard=unnamedplus   " Just use the global clipboard - works between terms 

filetype plugin on
set cursorline              " highlight current cursorline
set ttyfast                 " Speed up scrolling in Vim

