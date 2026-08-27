-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
vim.opt.clipboard = 'unnamedplus'

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Additional options not in file_context_0
vim.opt.wrap = false -- Display lines as one long line
vim.opt.linebreak = true -- Companion to wrap, don't split words
vim.opt.autoindent = true -- Copy indent from current line when starting new one
vim.opt.shiftwidth = 2 -- The number of spaces inserted for each indentation
vim.opt.tabstop = 2 -- Insert n spaces for a tab
vim.opt.softtabstop = 2 -- Number of spaces that a tab counts for while performing editing operations
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.sidescrolloff = 8 -- Minimal number of screen columns either side of cursor if wrap is false
vim.opt.hlsearch = false -- Set highlight on search
vim.opt.termguicolors = true -- Set termguicolors to enable highlight groups
vim.opt.whichwrap = 'bs<>[]hl' -- Which "horizontal" keys are allowed to travel to prev/next line
vim.opt.numberwidth = 4 -- Set number column width
vim.opt.swapfile = false -- Creates a swapfile
vim.opt.smartindent = true -- Make indenting smarter again
vim.opt.showtabline = 2 -- Always show tabs
vim.opt.backspace = 'indent,eol,start' -- Allow backspace on
vim.opt.pumheight = 10 -- Pop up menu height
vim.opt.conceallevel = 0 -- So that `` is visible in markdown files
vim.opt.fileencoding = 'utf-8' -- The encoding written to a file
vim.opt.cmdheight = 1 -- More space in the Neovim command line for displaying messages
vim.opt.backup = false -- Creates a backup file
vim.opt.writebackup = false -- If a file is being edited by another program, it is not allowed to be edited
vim.opt.completeopt = 'menuone,noselect' -- Set completeopt to have a better completion experience

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

