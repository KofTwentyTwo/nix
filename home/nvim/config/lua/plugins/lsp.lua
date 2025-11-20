-- LSP and language server configuration

return {
  -- LSP servers for common languages
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Lua
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                library = {},
                checkThirdParty = false,
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
        -- Python
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
              },
            },
          },
        },
        -- JavaScript/TypeScript
        tsserver = {
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },
        -- JSON
        jsonls = {
          settings = {
            json = {
              validate = { enable = true },
            },
          },
        },
        -- YAML
        yamlls = {
          settings = {
            yaml = {
              validate = true,
              format = { enable = true },
              hover = true,
              completion = true,
            },
          },
        },
        -- Markdown
        marksman = {},
        -- Docker
        dockerls = {},
        -- Go
        gopls = {},
        -- Rust
        rust_analyzer = {},
        -- C/C++
        clangd = {},
        -- Shell
        bashls = {},
      },
    },
  },

  -- Mason for LSP server management
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- LSP servers
        "lua-language-server",
        "pyright",
        "typescript-language-server",
        "json-lsp",
        "yaml-language-server",
        "marksman",
        "dockerfile-language-server",
        "gopls",
        "rust-analyzer",
        "clangd",
        "bash-language-server",
        -- Formatters
        "stylua",
        "black",
        "prettier",
        "shfmt",
        -- Linters
        "flake8",
        "eslint_d",
        "shellcheck",
        -- DAP
        "debugpy",
        "delve",
      },
    },
  },

  -- LSP signature help
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    config = function()
      require("lsp_signature").setup({
        bind = true,
        handler_opts = {
          border = "rounded",
        },
        hint_enable = true,
        hint_prefix = "💡 ",
        hint_scheme = "String",
        hi_parameter = "LspSignatureActiveParameter",
        max_height = 12,
        max_width = 80,
        transparency = nil,
        toggle_key = nil,
        select_signature_key = "<M-n>",
        move_cursor_key = "<M-c>",
      })
    end,
  },

  -- Schema store for JSON/YAML schemas
  {
    "b0o/schemastore.nvim",
    lazy = true,
  },
}
