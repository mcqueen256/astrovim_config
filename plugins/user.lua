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

local Path = require'plenary.path'

local function resolve_path(relative_path)
    -- Create a Path object for the relative path
    local path_obj = Path:new(relative_path)

    -- Make the path absolute and normalize it (resolving "..")
    local absolute_path = path_obj:absolute()

    return absolute_path
end


local function escape_pattern(text)
    return text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end


-- Nvim command to open a the next file relative to this file.
local function open_next(relative_to, then_open, ...)
    if relative_to == nil then
        relative_to = "."
    end

    -- Function to split the path into directory and file
    local function split_path(path)
        local i = path:match("^.*()/")
        if not i then return '.', path end
        return path:sub(1, i-1), path:sub(i+1)
    end

    -- Get the current buffer's full path and separate directory and filename
    local current_file_path = vim.api.nvim_buf_get_name(0)
    local current_dir, current_filename = split_path(current_file_path)
    local target_dir = resolve_path(current_dir .. "/" .. relative_to):gsub("/%.$", "")
    -- Get the path from the referenced relative path to the current file.
    local len_of_target_dir = #target_dir
    -- +2 removes the trailing slash as well
    local descendant_path_to_file = string.sub(current_file_path, len_of_target_dir + 2)
    -- local descendant_path_to_file = string.match(escape_pattern(current_file_path).. "/(.+)")
    local first_descendant = string.match(descendant_path_to_file, "([^/]+)")
    -- List all files in the directory
    local entries = vim.fn.readdir(target_dir)

    -- Debug arguments.
    -- print('relative_to: ', vim.inspect(relative_to))
    -- print('then_open: ', vim.inspect(then_open))
    -- print("current_dir: ", current_dir)
    -- print("pre abs target dir: ", current_dir .. "/" .. relative_to)
    -- print("target_dir: ", target_dir)
    -- print("current_file_path: ", current_file_path)
    -- print("len_of_target_dir: ", len_of_target_dir)
    -- print("descendant_path_to_file: ", descendant_path_to_file)
    -- print("first_descendant: ", first_descendant)

    -- Sort files to ensure order
    table.sort(entries)

    for i, entry in ipairs(entries) do
        if entry == first_descendant then
            local next_entry_index = i + 1
            if next_entry_index < #entries then
                local next_entry = entries[next_entry_index]
                local target_file_path = current_dir .. '/' .. next_entry
                if then_open ~= nil then
                    target_file_path = target_dir .. '/' .. next_entry .. '/' .. then_open
                end
                -- Open the next file
                vim.cmd('edit ' .. target_file_path)
                break
            end
        end
    end
end

local function call_command(opts)
    open_next(unpack(opts.fargs))
end

vim.api.nvim_create_user_command('OpenNext', call_command, {nargs='*'})

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
    "elkowar/yuck.vim",
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
    build = "cargo install brain-brainfuck",
    opts = function()
      local dashboard = require "alpha.themes.dashboard"
      require('alpha.term')
      
      dashboard.section.terminal.command = "brainfuck ~/.config/nvim/lua/user/chad-tokyo-night.bf"
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
