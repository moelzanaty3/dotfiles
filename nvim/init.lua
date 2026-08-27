require 'core.options'
require 'core.keymaps'

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- Common plugins shared between VSCode and regular Neovim
local common_plugins = {
  'github/copilot.vim',
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  require 'plugins.treesitter',
  require 'plugins.indent_line',
  require 'plugins.todo-comments',
  require 'plugins.autopairs',
}

-- Additional plugins for regular Neovim only
local neovim_plugins = {
  require 'plugins.which-key',
  require 'plugins.telescope',
  require 'plugins.lsp',
  require 'plugins.conform',
  require 'plugins.completion',
  require 'plugins.mini',
  require 'plugins.debug',
  require 'plugins.lint',
  require 'plugins.neo-tree',
  require 'plugins.gitsigns', -- adds gitsigns recommend keymaps
  require 'plugins.tokyo-night-theme',
}

if vim.g.vscode then
  -- VSCode extension
  require('lazy').setup(common_plugins)
else
  -- ordinary Neovim
  require('lazy').setup(vim.list_extend(common_plugins, neovim_plugins), {
    ui = {
      -- If you are using a Nerd Font: set icons to an empty table which will use the
      -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
      icons = vim.g.have_nerd_font and {} or {
        cmd = '⌘',
        config = '🛠',
        event = '📅',
        ft = '📂',
        init = '⚙',
        keys = '🗝',
        plugin = '🔌',
        runtime = '💻',
        require = '🌙',
        source = '📄',
        start = '🚀',
        task = '📌',
        lazy = '💤 ',
      },
    },
  })
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
