return {
  "akinsho/flutter-tools.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim",
  },
  config = function()
    require("flutter-tools").setup({
      flutter_path = vim.fn.expand("~/flutter/bin/flutter"),
      flutter_lookup_cmd = nil,
      root_patterns = { ".git", "pubspec.yaml" },
      fvm = false,
      widget_guides = { enabled = true },
      closing_tags = {
        highlight = "ErrorMsg",
        prefix = "//",
        enabled = true,
      },
      dev_log = {
        enabled = true,
        notify_errors = false,
        open_cmd = "tabedit",
      },
      dev_tools = {
        autostart = false,
        auto_open_browser = false,
      },
      outline = {
        open_cmd = "30vnew",
        auto_open = false,
      },
      lsp = {
        color = {
          enabled = false,
          background = false,
          virtual_text = true,
          virtual_text_str = "■",
        },
        on_attach = nil,
        capabilities = nil,
        flags = {},
        settings = {
          showTodos = true,
          completeFunctionCalls = true,
          analysisExcludedFolders = {
            vim.fn.expand("$HOME/AppData/Local/Pub/Cache"),
            vim.fn.expand("$HOME/.pub-cache"),
            vim.fn.expand("/opt/homebrew/"),
            vim.fn.expand("$HOME/tools/flutter/"),
          },
          renameFilesWithClasses = "prompt",
          enableSnippets = true,
        },
      },
    })
  end,
}
