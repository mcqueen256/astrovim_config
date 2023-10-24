-- sessions from the sessions directory.
function list_sessions()
  local sessions = {}
  local session_dir = os.getenv("HOME") .. "/.local/state/nvim/sessions"

  -- Check if the directory exists
  local f = io.open(session_dir)
  if f ~= nil then
      io.close(f)

      -- list in order of last modified. So the last session is first.
      local pfile = io.popen('ls -t ' .. session_dir)
      for session in pfile:lines() do
          -- Replace the '%<name>%' patterns with the actual path separators
          local path = string.gsub(session, "%%", "/")
          -- Special case: replace '%home%' pattern with '/home/<USER>/'
          path = string.gsub(path, "^home", "/home/" .. os.getenv("USER"))
          -- Replace '/home/<USER>/' with '~'
          path = string.gsub(path, "^/home/" .. os.getenv("USER"), "~")
           -- Remove the '.vim' extension
          path = string.gsub(path, "%.vim$", "")
          table.insert(sessions, {session=session_dir .. "/" .. session, path=path})
      end
      pfile:close()
  end

  return sessions
end

return {
  -- You can also add new plugins here as well:
  -- Add plugins, the lazy syntax
  -- "andweeb/presence.nvim",
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("lsp_signature").setup()
  --   end,
  -- },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    event = "User AstroFile",
  },
  {
    "mbbill/undotree",
    event = "User AstroFile",
  },
  {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
  },
  {
    "folke/zen-mode.nvim",
    keys = {
      { '<leader>z', function() require("zen-mode").toggle() end, mode = 'n', desc = "󱅻 Zen Mode" }
    },
    opts = {
      plugins = {
        alacritty = {
          enabled = true
        }
      },
      float = {
        padding = 4,
        max_height = 32,
      }
    }
  },
  {
    'stevearc/oil.nvim',
    keys = {
      { '<leader>E', function() require('oil').toggle_float() end, mode = 'n', desc = "Oil File Explorer", },
    },
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  {
    "goolord/alpha-nvim",
    url = "https://github.com/mcqueen256/alpha-nvim.git",
    commit = "f3a668479e14a468205d1e6640f0a2613be9b392",
    -- build = "cargo install brain-brainfuck",
    opts = function()
      local dashboard = require "alpha.themes.dashboard"
      require('alpha.term')
      
      dashboard.section.terminal.command = "bf ~/.config/nvim/lua/user/chad-tokyo-night.bf"
      dashboard.section.terminal.width = 42
      dashboard.section.terminal.height = 16
      dashboard.section.terminal.opts.redraw = true
      dashboard.section.terminal.opts.window_config.zindex = 1

      dashboard.section.header.val = {
        "NeoVim",
      }
      dashboard.section.terminal.opts.hl = "DashboardHeader"
      dashboard.section.footer.opts.hl = "DashboardFooter"

      local button, get_icon = require("astronvim.utils").alpha_button, require("astronvim.utils").get_icon
      dashboard.section.buttons.val = {
        button("LDR n  ", get_icon("FileNew", 2, true) .. "New File  "),
        button("LDR f f", get_icon("Search", 2, true) .. "Find File  "),
        button("LDR f o", get_icon("DefaultFile", 2, true) .. "Recents  "),
        button("LDR f w", get_icon("WordFile", 2, true) .. "Find Word  "),
        button("LDR f '", get_icon("Bookmarks", 2, true) .. "Bookmarks  "),
        button("LDR S l", get_icon("Refresh", 2, true) .. "Last Session  "),
      }

      dashboard.config.layout = {
        { type = "padding", val = vim.fn.max { 2, vim.fn.floor(vim.fn.winheight(0) * 0.2) } },
        dashboard.section.terminal,
        { type = "padding", val = 2 },
        dashboard.section.header,
        { type = "padding", val = 3 },
        dashboard.section.buttons,
        { type = "padding", val = 3 },
        dashboard.section.footer,
      }
      dashboard.config.opts.noautocmd = true
      return dashboard
    end,
  }
}
