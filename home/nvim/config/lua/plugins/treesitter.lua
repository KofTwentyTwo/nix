-- TreeSitter configuration for syntax highlighting

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- Core languages
        "lua",
        "vim",
        "vimdoc",
        
        -- Web development
        "html",
        "css",
        "scss",
        "javascript",
        "typescript",
        "tsx",
        "jsx",
        "json",
        "jsonc",
        "yaml",
        "toml",
        
        -- Backend languages
        "python",
        "go",
        "rust",
        "java",
        "c",
        "cpp",
        "c_sharp",
        "php",
        "ruby",
        "swift",
        "kotlin",
        "scala",
        
        -- Scripting
        "bash",
        "fish",
        "zsh",
        "powershell",
        
        -- Markup
        "markdown",
        "markdown_inline",
        "latex",
        
        -- Data formats
        "csv",
        "xml",
        "sql",
        "graphql",
        
        -- Configuration
        "dockerfile",
        "terraform",
        "hcl",
        "nginx",
        "nix",
        
        -- Other
        "gitignore",
        "gitattributes",
        "gitcommit",
        "diff",
        "regex",
        "query",
        "comment",
      },
      sync_install = false,
      auto_install = true,
      ignore_install = {},
      modules = {},
      
      -- Highlighting configuration
      highlight = {
        enable = true,
        disable = {},
        additional_vim_regex_highlighting = false,
      },
      
      -- Indentation
      indent = {
        enable = true,
        disable = {},
      },
      
      -- Incremental selection
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = "<C-s>",
          node_decremental = "<C-backspace>",
        },
      },
      
      -- Text objects
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]m"] = "@function.outer",
            ["]]"] = "@class.outer",
            ["]a"] = "@parameter.inner",
          },
          goto_next_end = {
            ["]M"] = "@function.outer",
            ["]["] = "@class.outer",
            ["]A"] = "@parameter.inner",
          },
          goto_previous_start = {
            ["[m"] = "@function.outer",
            ["[["] = "@class.outer",
            ["[a"] = "@parameter.inner",
          },
          goto_previous_end = {
            ["[M"] = "@function.outer",
            ["[]"] = "@class.outer",
            ["[A"] = "@parameter.inner",
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ["]x"] = "@parameter.inner",
          },
          swap_previous = {
            ["[x"] = "@parameter.inner",
          },
        },
      },
      
    },
  },
  
  -- Autotag for HTML/JSX
  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
  },
}
