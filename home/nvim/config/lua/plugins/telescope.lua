-- Telescope configuration for file finding and searching

return {
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
          width = 0.9,
          height = 0.8,
        },
        sorting_strategy = "ascending",
        winblend = 0,
        border = {},
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        color_devicons = true,
        set_env = { ["COLORTERM"] = "truecolor" },
        file_ignore_patterns = {
          "%.git/",
          "%.cache/",
          "%.DS_Store",
          "node_modules/",
          "%.pyc",
          "%.pyo",
          "%.pyd",
          "%.so",
          "%.dylib",
          "%.dll",
          "%.exe",
        },
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-n>"] = "cycle_history_next",
            ["<C-p>"] = "cycle_history_prev",
            ["<C-q>"] = "smart_send_to_qflist",
            ["<C-s>"] = "select_horizontal",
            ["<C-t>"] = "select_tab",
            ["<C-v>"] = "select_vertical",
            ["<C-u>"] = "preview_scrolling_up",
            ["<C-d>"] = "preview_scrolling_down",
            ["<C-f>"] = "preview_scrolling_up",
            ["<C-b>"] = "preview_scrolling_down",
            ["<C-h>"] = "which_key",
            ["<C-c>"] = "close",
            ["<C-/>"] = "which_key",
            ["<C-_>"] = "which_key",
            ["<C-w>"] = "which_key",
          },
          n = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-q>"] = "smart_send_to_qflist",
            ["<C-s>"] = "select_horizontal",
            ["<C-t>"] = "select_tab",
            ["<C-v>"] = "select_vertical",
            ["<C-u>"] = "preview_scrolling_up",
            ["<C-d>"] = "preview_scrolling_down",
            ["<C-f>"] = "preview_scrolling_up",
            ["<C-b>"] = "preview_scrolling_down",
            ["<C-h>"] = "which_key",
            ["<C-c>"] = "close",
            ["<C-/>"] = "which_key",
            ["<C-_>"] = "which_key",
            ["<C-w>"] = "which_key",
          },
        },
      },
      pickers = {
        find_files = {
          find_command = { "fd", "--type", "f", "--strip-cwd-prefix" },
        },
        live_grep = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob=!.git/",
          },
        },
        grep_string = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob=!.git/",
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    },
    keys = {
      -- Find files
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fF", "<cmd>Telescope find_files hidden=true<cr>", desc = "Find files (hidden)" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>fR", "<cmd>Telescope oldfiles only_cwd=true<cr>", desc = "Recent files (cwd)" },
      
      -- Live grep
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fG", "<cmd>Telescope live_grep cwd=false<cr>", desc = "Live grep (cwd)" },
      { "<leader>fb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer fuzzy find" },
      { "<leader>fs", "<cmd>Telescope grep_string<cr>", desc = "Grep string" },
      
      -- Git
      { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git commits" },
      { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git status" },
      { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Git branches" },
      
      -- LSP
      { "<leader>ld", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
      { "<leader>lr", "<cmd>Telescope lsp_references<cr>", desc = "LSP references" },
      { "<leader>li", "<cmd>Telescope lsp_implementations<cr>", desc = "LSP implementations" },
      { "<leader>ld", "<cmd>Telescope lsp_definitions<cr>", desc = "LSP definitions" },
      { "<leader>lt", "<cmd>Telescope lsp_type_definitions<cr>", desc = "LSP type definitions" },
      { "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", desc = "LSP document symbols" },
      { "<leader>lS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "LSP workspace symbols" },
      
      -- Other
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>fC", "<cmd>Telescope command_history<cr>", desc = "Command history" },
      { "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks" },
      { "<leader>fM", "<cmd>Telescope man_pages<cr>", desc = "Man pages" },
      { "<leader>fq", "<cmd>Telescope quickfix<cr>", desc = "Quickfix" },
      { "<leader>fQ", "<cmd>Telescope quickfixhistory<cr>", desc = "Quickfix history" },
      { "<leader>fj", "<cmd>Telescope jumplist<cr>", desc = "Jumplist" },
      { "<leader>f<space>", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    },
  },

  -- FZF extension for better fuzzy finding
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    config = function()
      require("telescope").load_extension("fzf")
    end,
  },
}
