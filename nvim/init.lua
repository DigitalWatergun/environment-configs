-- PLACE THIS FILE IN YOUR CONFIG FOLDER: ~/.config/nvim/init.lua
--
-- CORE REQUIREMENTS
-- brew install ripgrep git make
--
-- Then add languages as you use them:
-- brew install python3       # When you work on Python projects
-- brew install node          # When you work on JS/TS projects
-- brew install go            # When you work on Go projects
-- brew install terraform     # When you work on Terraform files
-- brew install php composer  # When you work on PHP projects
--
-- Install global eslint
-- npm install -g eslint

vim.g.loaded_netrw = 1 -- fully disable netrw for nvim-tree
vim.g.loaded_netrwPlugin = 1

-- On FocusGained: check for external file changes, refresh Git signs, and reload the file‑tree if open
local focus_grp = vim.api.nvim_create_augroup("FocusActions", { clear = true })
vim.api.nvim_create_autocmd("FocusGained", {
	group = focus_grp,
	callback = function()
		vim.cmd.checktime({ mods = { silent = true, emsg_silent = true } }) -- reload any changed buffers from disk
		pcall(require("gitsigns").refresh) -- refresh gitsigns gutter
		local api = require("nvim-tree.api") -- reload nvim-tree if it's open
		if api.tree.is_visible() then
			api.tree.reload()
		end
	end,
})

-- Auto-reload files when they change on disk (handles CursorHold, BufEnter events)
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI" }, {
	group = focus_grp,
	callback = function()
		if vim.fn.mode() ~= "c" then
			vim.cmd.checktime({ mods = { silent = true, emsg_silent = true } })
		end
	end,
})

-- Notify when file changes on disk and is reloaded
vim.api.nvim_create_autocmd("FileChangedShellPost", {
	group = focus_grp,
	callback = function()
		vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.WARN)
	end,
})

-- This section automatically downloads and installs lazy.nvim if it's not already present
-- Think of this as ensuring the "app store" is installed before we try to download apps
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if vim.fn.isdirectory(lazypath) == 0 then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Set up the leader key before loading plugins
-- The leader key is like a modifier key for custom shortcuts (similar to Ctrl+Shift in VSCode)
vim.g.mapleader = " " -- Using spacebar as the leader key

-- Basic editor settings that make Neovim more familiar coming from VSCode
vim.opt.number = true -- Show line numbers (like VSCode's line numbers)
vim.opt.relativenumber = false -- Use absolute line numbers, not relative ones
vim.opt.tabstop = 2 -- Tab width of 2 spaces
vim.opt.shiftwidth = 2 -- Indentation width of 2 spaces
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.wrap = true -- Wrap long lines
vim.opt.wrapscan = true -- Wrap search back to top of file
vim.opt.incsearch = true -- Show matches as you type
vim.opt.ignorecase = true -- Case-insensitive searching
vim.opt.smartcase = false -- Case-sensitive if search contains uppercase
vim.opt.termguicolors = true -- Enable full color support
vim.opt.signcolumn = "yes" -- Always show the sign column (like VSCode's gutter)
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.splitright = true -- Vertical splits appear on the RIGHT
vim.opt.splitbelow = true -- Horizontal splits appear BELOW (optional)
vim.opt.equalalways = true -- Equalize whenever you open/close a split
vim.opt.eadirection = "both" -- Adjust both height and width
vim.opt.autoread = true -- Autoreload buffers
vim.opt.updatetime = 300 -- Standard updatetime for CursorHold
vim.opt.hidden = true -- "Hide" (keep in memory) modified buffers instead of blocking
vim.opt.autowrite = false -- Don't auto-write buffer
vim.opt.autowriteall = false -- Don't auto-write all buffers
vim.opt.lazyredraw = false -- Lazy redraw to reduce on-save stutters
vim.opt.backup = false -- No backup files (file.txt~)
vim.opt.writebackup = true -- Temporary backup during write
vim.opt.swapfile = false -- No swap files (.file.txt.swp)
vim.opt.undofile = false -- No persistent undo file
vim.opt.undolevels = 500 -- Limit undo history in memory
vim.opt.foldenable = false -- Diasble code folding
vim.opt.foldmethod = "manual" -- Disable Neovim fold calculation
vim.opt.shada = "'50" -- Minimal shada for jumplist only
vim.opt.mousescroll = "ver:1,hor:1" -- Scroll 1 line at a time (vertical and horizontal)

-- Basic keymaps
vim.keymap.set("n", "<C-s>", ":w<CR>", { desc = "Save file with Ctrl+S" })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "Terminal → Normal mode" })
vim.keymap.set("v", "<Tab>", ">gv", { noremap = true, silent = true, desc = "Indent and reselect" })
vim.keymap.set("v", "<S-Tab>", "<gv", { noremap = true, silent = true, desc = "Unindent and reselect" })
vim.keymap.set("n", "<leader>dm", ":delmarks!<Bar>delmarks A-Z0-9<CR>", { desc = "Delete all marks" })
vim.keymap.set("n", "<leader>cp", ':let @+ = expand("%:p")<CR>', { desc = "Copy file path to clipboard" })
vim.keymap.set("n", "<leader>cr", ':let @+ = expand("%:.")<CR>', { desc = "Copy relative path to clipboard" })
vim.keymap.set("n", "gv", function()
	-- Check if LSP is available before splitting
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients > 0 then
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	else
		vim.notify("No LSP client attached", vim.log.levels.WARN)
	end
end, { desc = "Go to definition in vertical split" })
vim.keymap.set("n", "gt", function()
	-- Check if LSP is available before splitting
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients > 0 then
		vim.cmd("tab split")
		vim.lsp.buf.definition()
	else
		vim.notify("No LSP client attached", vim.log.levels.WARN)
	end
end, { desc = "Go to definition in new tab" })

-- Tab navigation
vim.keymap.set("n", "<leader>tc", ":tabnew<CR>", { desc = "New tab" })
vim.keymap.set("n", "<leader>tn", ":tabnext<CR>", { desc = "Next tab" })
vim.keymap.set("n", "<leader>tp", ":tabprevious<CR>", { desc = "Previous tab" })

-- Persistent Terminal
vim.g.persistent_term_buf = vim.g.persistent_term_buf or nil
vim.keymap.set("n", "<leader>tt", function()
	if vim.g.persistent_term_buf and vim.api.nvim_buf_is_valid(vim.g.persistent_term_buf) then
		-- Find if terminal is already visible
		local term_win = nil
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win) == vim.g.persistent_term_buf then
				term_win = win
				break
			end
		end

		if term_win then -- Terminal is visible, focus it
			vim.api.nvim_set_current_win(term_win)
		else -- Terminal exists but not visible, open it
			vim.cmd("botright 20split")
			vim.api.nvim_win_set_buf(0, vim.g.persistent_term_buf)
			vim.wo.winfixheight = true -- Fix the window height
		end
		vim.cmd("startinsert")
	else -- Create new terminal
		vim.cmd("botright 20split | terminal")
		vim.g.persistent_term_buf = vim.api.nvim_get_current_buf()
		vim.bo.bufhidden = "hide"
		vim.bo.buflisted = false
		vim.wo.winfixheight = true -- Fix the window height
	end
end, { desc = "Open persistent terminal" })

-- Kill / Reset Terminal
vim.api.nvim_create_user_command("TermKill", function()
	if vim.g.persistent_term_buf and vim.api.nvim_buf_is_valid(vim.g.persistent_term_buf) then
		-- First close any windows showing the terminal
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win) == vim.g.persistent_term_buf then
				vim.api.nvim_win_close(win, true)
			end
		end

		-- Then delete the buffer
		vim.api.nvim_buf_delete(vim.g.persistent_term_buf, { force = true })
		vim.g.persistent_term_buf = nil
		print("Terminal buffer killed")
	else
		print("No terminal buffer to kill")
	end
end, { desc = "Kill the persistent terminal buffer" })

-- Enhanced buffer cleanup - delete abandoned buffers and notify LSP servers
vim.api.nvim_create_user_command("CleanBuffers", function()
	local buffers = vim.api.nvim_list_bufs()
	local closed = 0
	local lsp_closed = {}

	for _, buf in ipairs(buffers) do
		-- Skip persistent terminal buffer
		if buf == vim.g.persistent_term_buf then
			goto continue
		end

		-- Skip all terminal buffers (buftype == 'terminal')
		local buftype = vim.bo[buf].buftype
		if buftype == "terminal" then
			goto continue
		end

		-- Only delete if: loaded, not modified, no windows, no LSP attached
		if
			vim.api.nvim_buf_is_loaded(buf)
			and not vim.bo[buf].modified
			and #vim.fn.win_findbuf(buf) == 0
			and #vim.lsp.get_clients({ bufnr = buf }) == 0
		then
			-- Get the file URI before closing
			local bufname = vim.api.nvim_buf_get_name(buf)
			if bufname ~= "" then
				table.insert(lsp_closed, vim.uri_from_bufnr(buf))
			end

			if pcall(vim.api.nvim_buf_delete, buf, { force = false }) then
				closed = closed + 1
			end
		end

		::continue::
	end

	-- Tell LSP clients to close these files
	if #lsp_closed > 0 then
		local clients = vim.lsp.get_clients()
		for _, client in ipairs(clients) do
			for _, uri in ipairs(lsp_closed) do
				-- Send didClose notification to free memory
				pcall(function()
					client.notify("textDocument/didClose", {
						textDocument = { uri = uri },
					})
				end)
			end
		end
		print(string.format("Cleaned %d buffers and notified LSP about %d closed files", closed, #lsp_closed))
	else
		print(string.format("Cleaned %d buffers", closed))
	end
end, { desc = "Clean up abandoned buffers and notify LSP" })

-- Auto-clean every 10 minutes
vim.fn.timer_start(10 * 60 * 1000, function()
	vim.cmd("CleanBuffers")
end, { ["repeat"] = -1 })

-- Manually free / clean up memory
vim.api.nvim_create_user_command("MemClean", function()
	vim.cmd("CleanBuffers")
	collectgarbage("collect")
	print("Memory cleaned")
end, { desc = "Clean buffers and garbage collect" })

-- Universal LSP restart timer - restarts ALL attached LSP clients every 3 hours
vim.fn.timer_start(3 * 60 * 60 * 1000, function()
	vim.schedule(function()
		local clients = vim.lsp.get_clients()
		if #clients == 0 then
			return
		end

		local client_names = {}
		for _, client in ipairs(clients) do
			table.insert(client_names, client.name)
			vim.lsp.stop_client(client.id, true)
		end

		-- Notify user about the restart
		vim.notify(
			string.format("Auto-restarted LSP servers for memory management: %s", table.concat(client_names, ", ")),
			vim.log.levels.INFO
		)

		-- Wait a moment then reload buffers to reattach LSP
		vim.defer_fn(function()
			vim.cmd("checktime")
		end, 500)
	end)
end, { ["repeat"] = -1 })

-- Removed detect_project_features() - now loading all LSP servers
-- Auto-detect project venv for python3_host_prog
local function find_project_python()
	local cwd = vim.fn.getcwd()

	-- First, check for Poetry virtual environment
	local poetry_env = vim.fn.system("cd " .. cwd .. " && poetry env info --path 2>/dev/null"):gsub("\n", "")
	if poetry_env and poetry_env ~= "" and vim.fn.isdirectory(poetry_env) == 1 then
		local poetry_py = poetry_env .. "/bin/python"
		if vim.fn.executable(poetry_py) == 1 then
			return poetry_py
		end
	end

	-- Then check for standard venv directories
	for _, name in ipairs({ ".venv", "venv", "env" }) do
		local py = cwd .. "/" .. name .. "/bin/python"
		if vim.fn.executable(py) == 1 then
			return py
		end
	end

	return vim.fn.exepath("python3")
end

local function set_python_host()
	vim.g.python3_host_prog = find_project_python()
end

vim.api.nvim_create_autocmd("VimEnter", { callback = set_python_host })
vim.api.nvim_create_autocmd("DirChanged", { callback = set_python_host })

-- Plugin definitions
require("lazy").setup({
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					cache_picker = {
						num_pickers = 1,
					},
					dynamic_preview_title = true,

					file_ignore_patterns = {
						"node_modules/.*",
						"%.git/.*",
						"%.DS_Store",
						"package%-lock%.json",
						"yarn%.lock",
						"target/.*",
						"build/.*",
						"dist/.*",
						"%.o$",
						"%.a$",
						"%.out$",
						"%.class$",
						"%.pdf$",
						"%.mkv$",
						"%.mp4$",
						"%.zip$",
					},

					layout_config = {
						horizontal = {
							prompt_position = "top",
							preview_width = 0.55,
							results_width = 0.8,
						},
						vertical = {
							mirror = false,
						},
						width = 0.87,
						height = 0.80,
						preview_cutoff = 120,
					},

					mappings = {
						i = {
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
							["<C-q>"] = function(prompt_bufnr)
								actions.send_to_qflist(prompt_bufnr)
								actions.open_qflist(prompt_bufnr)
							end,
							["<Esc>"] = actions.close,
							["<C-u>"] = false,
						},
						n = {
							["q"] = actions.close,
							["<C-q>"] = function(prompt_bufnr)
								actions.send_to_qflist(prompt_bufnr)
								actions.open_qflist(prompt_bufnr)
							end,
						},
					},

					vimgrep_arguments = {
						"rg",
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
						"--hidden", -- Search hidden files
						"--glob=!.git/", -- But ignore .git
					},
				},

				pickers = {
					find_files = {
						find_command = {
							"sh",
							"-c",
							"(rg --files --glob '!.git/*'; ls .env .env.* 2>/dev/null) | sort -u",
						},
					},

					live_grep = {
						additional_args = function()
							return { "--hidden", "--glob=!.git/" }
						end,
					},

					buffers = {
						show_all_buffers = true,
						sort_lastused = true,
						theme = "dropdown",
						previewer = false,
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
			})

			telescope.load_extension("fzf") -- Load the fzf extension for much better performance
		end,
		keys = {
			{ "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
			{ "<C-f>", "<cmd>Telescope live_grep<cr>", desc = "Live grep search" },
			{ "<C-h>", "<cmd>Telescope resume<cr>", desc = "Resume live grep search" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
			{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
			{ "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "Find word under cursor" },
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
			{ "<leader>fc", "<cmd>Telescope git_commits<cr>", desc = "Git commits" },
			{ "<leader>fs", "<cmd>Telescope git_status<cr>", desc = "Git status" },
			{ "<leader>kk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps browser" },
		},
	},

	-- Molokai theme here
	{
		"tomasr/molokai",
		name = "molokai",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("molokai")

			local blue = "#4A90C2"
			local green = "#84d675"
			local terminal_bg = "#1e1e1e"

			-- Match terminal background color
			vim.api.nvim_set_hl(0, "Normal", { bg = terminal_bg })
			vim.api.nvim_set_hl(0, "NormalFloat", { bg = terminal_bg })
			vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = terminal_bg })

			-- Fix the statusline background under nvim-tree
			vim.api.nvim_set_hl(0, "StatusLine", { bg = terminal_bg, fg = "#ffffff" })
			vim.api.nvim_set_hl(0, "StatusLineNC", { bg = terminal_bg, fg = "#666666" })

			-- folder icons & names
			vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = blue, bold = true })
			vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = blue, bold = true })

			-- (optional) file icons & names
			vim.api.nvim_set_hl(0, "NvimTreeFileIcon", { fg = blue })
			vim.api.nvim_set_hl(0, "NvimTreeFileName", { fg = blue })

			-- opened folders/icons
			vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderIcon", { fg = green, bold = true })
			vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = green, bold = true })

			vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderIcon", { fg = green, bold = true })
			vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = green, bold = true })
		end,
	},

	-- File explorer - like VSCode's file sidebar
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local api = require("nvim-tree.api")

			require("nvim-tree").setup({
				view = { width = 40 },
				filters = {
					dotfiles = false,
					git_ignored = false,
				},
				renderer = {
					group_empty = true,
					icons = {
						show = {
							git = true,
							folder = true,
							file = true,
							folder_arrow = true,
						},
					},
					highlight_git = "all",
				},
				update_focused_file = {
					enable = true,
					update_root = false,
				},
				git = {
					enable = true,
					ignore = false,
					timeout = 500,
				},
				diagnostics = {
					enable = true,
					show_on_dirs = true,
					debounce_delay = 50,
					icons = {
						hint = "",
						info = "",
						warning = "",
						error = "",
					},
				},

				-- on_attach runs when the tree buffer is first initialized
				on_attach = function(bufnr)
					local default_on_attach = require("nvim-tree.api").config.mappings.default_on_attach

					default_on_attach(bufnr)

					local function buf_opts(desc)
						return { buffer = bufnr, noremap = true, silent = true, desc = desc }
					end

					-- helper: save the previously active buffer if it was modified
					local function save_prev()
						if vim.bo.modifiable and vim.bo.modified then
							vim.cmd("silent! update")
						end
					end

					-- remap <CR>, o, <2-LeftMouse> to save-first, then open
					vim.keymap.set("n", "<CR>", function()
						save_prev()
						api.node.open.edit()
					end, buf_opts("Open file"))
					vim.keymap.set("n", "o", function()
						save_prev()
						api.node.open.edit()
					end, buf_opts("Open file"))
					vim.keymap.set("n", "<2-LeftMouse>", function()
						save_prev()
						api.node.open.edit()
					end, buf_opts("Open file"))

					vim.keymap.set("n", "a", function() -- override 'a' to save then create file
						save_prev()
						api.fs.create()
					end, buf_opts("Add file"))

					vim.keymap.set("n", "A", function() -- override 'A' to save then create directory
						save_prev()
						api.fs.create({ dir = true })
					end, buf_opts("Add directory"))
					vim.keymap.set("n", "d", function() -- override 'd' to save then delete
						save_prev()
						api.fs.remove()
					end, buf_opts("Delete"))
					vim.keymap.set("n", "<C-t>", function()
						save_prev()
						api.node.open.tab()
					end, buf_opts("Open file in new tab"))
				end,
			})

			-- Gray out the “ignored” status (icon + name)
			vim.api.nvim_set_hl(0, "NvimTreeGitIgnoredHL", { fg = "#5c6370" })

			vim.api.nvim_create_augroup("NvimTreeAutoRefresh", { clear = true })
			vim.api.nvim_create_autocmd("FocusGained", {
				group = "NvimTreeAutoRefresh",
				callback = function()
					if api.tree.is_visible() then
						api.tree.reload()
					end
				end,
			})
		end,
		keys = {
			{ "<leader>e", ":NvimTreeToggle<CR>", desc = "Toggle file explorer" },
		},
	},

	-- Syntax highlighting - makes code colorful and properly formatted
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				-- Install parsers for these languages automatically
				ensure_installed = {
					"lua",
					"python",
					"javascript",
					"typescript",
					"html",
					"css",
					"go",
					"gomod",
					"gosum",
					"php",
					"sql",
					"terraform",
				},
				-- Add these fields to satisfy the type checker
				sync_install = false, -- Install parsers synchronously (only applied to `ensure_installed`)
				auto_install = false, -- Automatically install missing parsers when entering buffer
				ignore_install = {}, -- List of parsers to ignore installing

				highlight = {
					enable = true, -- Enable syntax highlighting
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true, -- Enable smart indentation
				},

				-- This is technically optional but helps with type checking
				modules = {},
			})
		end,
	},

	-- Treesitter context
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("treesitter-context").setup({
				enable = true, -- Enable this plugin
				throttle = true, -- Throttle redraws for performance
				max_lines = 0, -- How many lines the window should span (0 = no limit)
				patterns = { -- Match patterns for TS nodes to show in context
					default = {
						"class",
						"function",
						"method",
						"for",
						"while",
						"if",
						"switch",
						"case",
					},
				},
			})
		end,
	},

	-- Vim signature to show marks in the signcolumn/gutter
	{
		"kshenoy/vim-signature",
		event = "BufReadPre", -- load early, but lazily
		config = function()
			-- use a simple triangle for your marks
			vim.g.signature_mark_text = "▶"
			-- also highlight the marked line
			vim.g.signature_line_enabled = 1
			-- how high priority in the signcolumn
			vim.g.signature_priority = 10
		end,
	},

	-- Mason for development tools
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},

	-- Mason Tool installer
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"typescript-language-server",
					"lua-language-server",
					"eslint-lsp",
					"prettier",
					"stylua",
					"gopls",
					"goimports",
					"gofumpt",
					"golangci-lint",
					"php-cs-fixer",
					"phpstan",
					"pyright",
					"black",
					"ruff",
					"ruff-lsp",
					"sqls",
					"terraform-ls",
					"tflint",
					"phpactor",
				},
			})
		end,
	},

	-- Formatting
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local conform = require("conform")

			-- helper to detect a Python venv and prepend its bin/ to PATH
			local function venv_path()
				local venv = os.getenv("VIRTUAL_ENV")
				if venv and #venv > 0 then
					return venv .. "/bin:" .. vim.env.PATH
				end
				return vim.env.PATH
			end

			conform.setup({
				formatters = {
					-- Python
					ruff_format = {
						command = "ruff",
						args = { "format", "--stdin-filename", "$FILENAME", "-" },
						stdin = true,
						env = { PATH = venv_path() },
					},
					ruff_organize_imports = {
						command = "ruff",
						args = { "check", "--fix", "--select", "I", "--stdin-filename", "$FILENAME", "-" },
						stdin = true,
						env = { PATH = venv_path() },
					},
					black = {
						command = "black",
						args = { "--quiet", "-" },
						stdin = true,
						env = { PATH = venv_path() },
					},

					-- JS/TS via Prettier
					prettier = {
						args = { "--stdin-filepath", "$FILENAME" },
						stdin = true,
					},

					-- Go - goimports handles import sorting automatically
					goimports = {
						command = "goimports",
						args = { "-srcdir", "$DIRNAME" },
						stdin = true,
					},
					gofumpt = {
						command = "gofumpt",
						stdin = true,
					},

					-- Lua
					stylua = {
						args = { "--stdin-filepath", "$FILENAME", "-" },
						stdin = true,
					},

					-- PHP
					["php-cs-fixer"] = {
						command = "php-cs-fixer",
						args = {
							"fix",
							"--using-cache=no",
							"-",
						},
						stdin = true,
						env = { PATH = vim.fn.getcwd() .. "/vendor/bin:" .. vim.env.PATH },
					},

					-- Terraform
					terraform_fmt = {
						command = "terraform",
						args = { "fmt", "-" },
						stdin = true,
					},
				},

				formatters_by_ft = {
					javascript = { "prettier" },
					typescript = { "prettier" },
					javascriptreact = { "prettier" },
					typescriptreact = { "prettier" },
					json = { "prettier" },
					css = { "prettier" },
					html = { "prettier" },
					markdown = { "prettier" },
					lua = { "stylua" },
					go = { "goimports", "gofumpt" },
					php = { "php-cs-fixer" },
					python = { "ruff_organize_imports", "ruff_fix", "ruff_format", "black" },
					terraform = { "terraform_fmt" },
				},

				-- (optional) your existing save hook settings
				format_after_save = false,
				notify_on_error = true,
			})
		end,
	},

	-- Linting
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			-- Configure Typescript / Javascript linter
			-- Check for project-local eslint first, then fallback to global
			local eslint_linter = require("lint.linters.eslint")
			eslint_linter.cmd = function()
				local local_eslint = vim.fn.fnamemodify("./node_modules/.bin/eslint", ":p")
				if vim.fn.executable(local_eslint) == 1 then
					return local_eslint
				end
				-- Fallback to global eslint
				if vim.fn.executable("eslint") == 1 then
					return "eslint"
				end
				-- Last resort: use npx eslint
				return "npx"
			end
			-- Keep the default args structure but update as needed
			-- The default eslint linter already has the right args structure

			-- Custom parser to filter out "file ignored" warnings
			local original_parser = eslint_linter.parser
			eslint_linter.parser = function(output, bufnr, linter_cwd)
				-- Filter out the "file ignored" warnings
				local diagnostics = original_parser(output, bufnr, linter_cwd)
				if type(diagnostics) ~= "table" then
					return {}
				end
				local filtered = {}
				for _, diagnostic in ipairs(diagnostics) do
					if not diagnostic.message:match("File ignored because of a matching ignore pattern") then
						table.insert(filtered, diagnostic)
					end
				end
				return filtered
			end

			-- Configure PHP linter (PHPStan) with better configuration
			-- Check for project-local phpstan first
			local phpstan_cmd = "phpstan"
			local vendor_phpstan = vim.fn.getcwd() .. "/vendor/bin/phpstan"
			if vim.fn.executable(vendor_phpstan) == 1 then
				phpstan_cmd = vendor_phpstan
			end

			lint.linters.phpstan = {
				cmd = phpstan_cmd,
				stdin = false,
				args = {
					"analyse",
					"--error-format=raw",
					"--no-progress",
				},
				stream = "stdout",
				ignore_exitcode = true,
				parser = function(output, bufnr)
					local diagnostics = {}
					for line in output:gmatch("[^\r\n]+") do
						local file, lnum, message = line:match("^(.+):(%d+):(.+)$")
						if file and lnum and message then
							table.insert(diagnostics, {
								bufnr = bufnr,
								lnum = tonumber(lnum) - 1,
								col = 0,
								message = vim.trim(message),
								severity = vim.diagnostic.severity.ERROR,
							})
						end
					end
					return diagnostics
				end,
			}

			-- Alternative PHP CS linter
			lint.linters.php = {
				cmd = "php",
				args = { "-l" },
				stdin = false,
				stream = "both",
				ignore_exitcode = true,
				parser = function(output)
					local diagnostics = {}
					for line in output:gmatch("[^\r\n]+") do
						local message, lnum = line:match("Parse error: (.+) on line (%d+)")
						if message and lnum then
							table.insert(diagnostics, {
								lnum = tonumber(lnum) - 1,
								col = 0,
								message = message,
								severity = vim.diagnostic.severity.ERROR,
							})
						end
					end
					return diagnostics
				end,
			}

			-- Configure Python linter
			local mason_ruff = vim.fn.stdpath("data") .. "/mason/bin/ruff"
			if vim.fn.executable(mason_ruff) == 1 then
				lint.linters.ruff = lint.linters.ruff or {}
				lint.linters.ruff.cmd = mason_ruff
			end

			-- Configure Go linter
			-- golangci-lint is already configured by default in nvim-lint
			-- Just ensure it uses the right settings
			lint.linters.golangcilint = {
				cmd = "golangci-lint",
				stdin = false,
				args = { "run", "--out-format", "json" },
				stream = "stdout",
				ignore_exitcode = true,
				parser = function(output, bufnr)
					local diagnostics = {}
					local ok, decoded = pcall(vim.json.decode, output)
					if not ok or not decoded or not decoded.Issues then
						return diagnostics
					end

					for _, issue in ipairs(decoded.Issues) do
						if issue.Pos then
							table.insert(diagnostics, {
								bufnr = bufnr,
								lnum = (issue.Pos.Line or 1) - 1,
								col = (issue.Pos.Column or 1) - 1,
								message = issue.Text or "unknown issue",
								severity = vim.diagnostic.severity.WARN,
								source = issue.FromLinter,
							})
						end
					end
					return diagnostics
				end,
			}

			local linters_by_ft = {
				javascript = { "eslint" },
				typescript = { "eslint" },
				javascriptreact = { "eslint" },
				typescriptreact = { "eslint" },
				go = { "golangcilint" },
				php = { "php", "phpstan" },
				python = { "ruff" },
				terraform = { "tflint" },
				tf = { "tflint" },
			}

			-- Apply the configuration
			lint.linters_by_ft = linters_by_ft

			-- Setup autocommand to lint on save and insert leave (removed TextChanged for performance)
			vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
				callback = function()
					-- Only lint if we have linters for this filetype
					local ft = vim.bo.filetype
					if lint.linters_by_ft[ft] then
						lint.try_lint()
					end
				end,
			})
		end,
	},

	-- Git signs in the gutter (added/changed/removed lines)
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "▎" },
					change = { text = "▎" },
					delete = { text = "契" },
					topdelete = { text = "契" },
					changedelete = { text = "▎" },
				},
				current_line_blame = false, -- disable inline blame by default
			})
		end,
	},

	-- Git blame in the gutter and virtual text
	{
		"f-person/git-blame.nvim",
		event = "BufReadPost", -- load on buffer read so it's available as soon as you open a file
		cond = vim.fn.executable("git") == 1, -- only load if 'git' is installed
		config = function()
			require("gitblame").setup({
				enabled = false, -- enable virtual text blame (default: false)
				delay = 500, -- delay in ms before blame appears (default: 1000)
				virtual_text_pos = "eol", -- where to show the text: 'eol' | 'inline' | 'right_align' (default: 'eol')
				date_format = "%Y-%m-%d", -- date format (same as strftime)
				filetype_exclude = { "NvimTree", "toggleterm", "dashboard" }, -- filetypes to disable in
			})
			vim.keymap.set("n", "<leader>gb", "<cmd>GitBlameToggle<CR>", { desc = "Toggle Git blame virtual text" }) -- toggle with <leader>gb
		end,
	},

	-- LSP with selective starting based on project detection
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			-- Wrap everything in pcall to catch errors
			local ok, lsp_error = pcall(function()
				-- Use LspAttach autocmd instead of on_attach in config (Neovim 0.11 best practice)
				vim.api.nvim_create_autocmd("LspAttach", {
					callback = function(ev)
						local bufnr = ev.buf
						local bufopts = { noremap = true, silent = true, buffer = bufnr }

						-- LSP keymaps
						vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
						vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
						vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
						vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
						vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
						vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
						vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
						vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)

						-- Diagnostic keymaps
						vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, bufopts)
						if vim.diagnostic.jump then
							vim.keymap.set("n", "[d", function()
								vim.diagnostic.jump({ count = -1 })
							end, bufopts)
							vim.keymap.set("n", "]d", function()
								vim.diagnostic.jump({ count = 1 })
							end, bufopts)
						end
						vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, bufopts)
					end,
				})

				-- Lua LSP
				vim.lsp.config.lua_ls = {
					cmd = { "lua-language-server" },
					filetypes = { "lua" },
					root_markers = {
						".luarc.json",
						".luarc.jsonc",
						".luacheckrc",
						".stylua.toml",
						"stylua.toml",
						"selene.toml",
						"selene.yml",
						".git",
					},
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
					settings = {
						Lua = {
							runtime = {
								version = "LuaJIT",
							},
							diagnostics = {
								globals = { "vim" },
							},
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
								maxPreload = 2000, -- Limit preloaded files
								preloadFileSize = 500, -- Limit file size (KB)
							},
							telemetry = {
								enable = false,
							},
							completion = {
								callSnippet = "Replace",
							},
							type = {
								checkTableShape = false,
							},
						},
					},
				}
				vim.lsp.enable("lua_ls")

				-- TypeScript LSP
				vim.lsp.config.ts_ls = {
					cmd = { "typescript-language-server", "--stdio" },
					filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
					root_markers = { "tsconfig.json", "package.json", "jsconfig.json", ".git" },
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
					settings = {
						typescript = {
							tsserver = {
								maxTsServerMemory = 4096, -- Cap memory at 4GB
							},
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
				}
				vim.lsp.enable("ts_ls")

				-- ESLint LSP
				vim.lsp.config.eslint = {
					cmd = { "vscode-eslint-language-server", "--stdio" },
					filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
					root_markers = {
						".eslintrc",
						".eslintrc.js",
						".eslintrc.json",
						".eslintrc.cjs",
						".eslintrc.mjs",
						".eslintrc.yaml",
						".eslintrc.yml",
						"eslint.config.js",
						"eslint.config.mjs",
						"eslint.config.cjs",
						"package.json",
						".git",
					},
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
					settings = {
						eslint = {
							enable = true,
							packageManager = "npm",
							autoFixOnSave = true,
							codeActionsOnSave = {
								mode = "all",
								rules = false,
							},
							lintTask = {
								options = "--no-warn-ignored",
							},
							run = "onSave", -- Changed from "onType" to reduce memory pressure
							quiet = false,
							rulesCustomizations = {},
							problems = {
								shortenToSingleLine = false,
							},
						},
					},
				}
				vim.lsp.enable("eslint")

				-- Go LSP
				vim.lsp.config.gopls = {
					cmd = { "gopls" },
					filetypes = { "go", "gomod", "gowork", "gotmpl" },
					root_markers = { "go.work", "go.mod", ".git" },
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
					settings = {
						gopls = {
							memoryMode = "DegradeClosed",
							analyses = {
								unusedparams = true,
								shadow = true,
								nilness = true,
								unusedwrite = true,
							},
							staticcheck = true,
							gofumpt = true,
							usePlaceholders = true,
							codelenses = {
								gc_details = false,
								generate = true,
								regenerate_cgo = true,
								test = true,
								tidy = true,
								upgrade_dependency = true,
								vendor = true,
							},
						},
					},
				}
				vim.lsp.enable("gopls")

				-- Python LSP
				vim.lsp.config.pyright = {
					cmd = { "pyright-langserver", "--stdio" },
					filetypes = { "python" },
					root_markers = {
						"pyproject.toml",
						"setup.py",
						"setup.cfg",
						"requirements.txt",
						"Pipfile",
						"pyrightconfig.json",
						".git",
					},
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
					settings = {
						python = {
							pythonPath = find_project_python(),
							analysis = {
								typeCheckingMode = "basic",
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
								diagnosticMode = "openFilesOnly", -- Changed from "workspace" to reduce memory
								autoImportCompletions = true,
							},
						},
					},
				}
				vim.lsp.enable("pyright")

				-- PHP LSP
				vim.lsp.config.phpactor = {
					cmd = { "phpactor", "language-server" },
					filetypes = { "php" },
					root_markers = { "composer.json", ".git" },
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
				}
				vim.lsp.enable("phpactor")

				-- SQL LSP
				vim.lsp.config.sqls = {
					cmd = { "sqls" },
					filetypes = { "sql", "mysql" },
					root_markers = { ".git" },
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
					settings = {
						sqls = {
							connections = {
								-- Add your database connections here if needed
							},
						},
					},
				}
				vim.lsp.enable("sqls")

				-- Terraform LSP
				vim.lsp.config.terraformls = {
					cmd = { "terraform-ls", "serve" },
					filetypes = { "terraform", "tf", "hcl" },
					root_markers = { ".terraform", ".git" },
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
				}
				vim.lsp.enable("terraformls")
			end)

			if not ok then
				print("❌ LSP Configuration Error: " .. tostring(lsp_error))
			end

			vim.api.nvim_create_user_command("LspStatus", function()
				local cwd = vim.fn.getcwd()

				-- Helper functions
				local function file_exists(path)
					return vim.fn.filereadable(path) == 1
				end

				local function dir_exists(path)
					return vim.fn.isdirectory(path) == 1
				end

				-- Re-run detection logic
				local features = {}
				local nvim_config_path = vim.fn.stdpath("config")
				local current_file = vim.fn.expand("%:p")

				features.has_lua = file_exists(cwd .. "/.luarc.json")
					or file_exists(cwd .. "/init.lua")
					or string.find(cwd, nvim_config_path, 1, true)
					or string.find(current_file, nvim_config_path, 1, true)
					or dir_exists(cwd .. "/lua")

				features.has_js_ts = file_exists(cwd .. "/package.json")
					or file_exists(cwd .. "/tsconfig.json")
					or dir_exists(cwd .. "/node_modules")

				features.has_eslint = file_exists(cwd .. "/package.json")
					and (
						file_exists(cwd .. "/.eslintrc.js")
						or file_exists(cwd .. "/.eslintrc.json")
						or file_exists(cwd .. "/.eslintrc.cjs")
						or file_exists(cwd .. "/.eslintrc.mjs")
						or file_exists(cwd .. "/.eslintrc.yaml")
						or file_exists(cwd .. "/.eslintrc.yml")
						or file_exists(cwd .. "/eslint.config.js")
						or file_exists(cwd .. "/eslint.config.mjs")
						or file_exists(cwd .. "/eslint.config.cjs")
					)

				features.has_go = file_exists(cwd .. "/go.mod")

				features.has_python = file_exists(cwd .. "/requirements.txt")
					or file_exists(cwd .. "/pyproject.toml")
					or file_exists(cwd .. "/setup.py")
					or file_exists(cwd .. "/Pipfile")

				features.has_php = file_exists(cwd .. "/composer.json")
					or file_exists(cwd .. "/index.php")
					or dir_exists(cwd .. "/vendor")

				features.has_sql = dir_exists(cwd .. "/sql")
					or dir_exists(cwd .. "/migrations")
					or file_exists(cwd .. "/schema.sql")

				features.has_terraform = file_exists(cwd .. "/.terraform.lock.hcl") or dir_exists(cwd .. "/.terraform")

				-- Show detection results
				print("🔍 LSP Detection Results:")
				print("  Lua: " .. (features.has_lua and "✅" or "❌"))
				print("  JS/TS: " .. (features.has_js_ts and "✅" or "❌"))
				print("  ESLint: " .. (features.has_eslint and "✅" or "❌"))
				print("  Go: " .. (features.has_go and "✅" or "❌"))
				print("  Python: " .. (features.has_python and "✅" or "❌"))
				print("  PHP: " .. (features.has_php and "✅" or "❌"))
				print("  SQL: " .. (features.has_sql and "✅" or "❌"))
				print("  Terraform: " .. (features.has_terraform and "✅" or "❌"))

				-- Show running LSP servers
				print("")
				print("🔧 Currently Running LSP Servers:")
				local clients = vim.lsp.get_clients()
				if #clients == 0 then
					print("  No LSP servers running")
				else
					for _, client in ipairs(clients) do
						print("  🟢 " .. client.name)
					end
				end

				-- Show current buffer's attached clients
				local current_buf_clients = vim.lsp.get_clients({ bufnr = 0 })
				if #current_buf_clients > 0 then
					print("")
					print("📎 Attached to current buffer:")
					for _, client in ipairs(current_buf_clients) do
						print("  🟢 " .. client.name)
						if client.config.root_dir then
							print("     Root: " .. client.config.root_dir)
						end
					end
				end

				-- Show enabled linters
				print("")
				print("🔍 Enabled Linters:")
				local lint_ok, lint = pcall(require, "lint")
				if lint_ok and lint.linters_by_ft then
					local current_ft = vim.bo.filetype
					if current_ft and current_ft ~= "" then
						local linters = lint.linters_by_ft[current_ft]
						if linters and #linters > 0 then
							print("  For " .. current_ft .. ":")
							for _, linter in ipairs(linters) do
								print("    🟢 " .. linter)
							end
						else
							print("  No linters configured for filetype: " .. current_ft)
						end
					else
						print("  No filetype detected")
					end
				else
					print("  Linting not available")
				end

				-- Show enabled formatters
				print("")
				print("🎨 Enabled Formatters:")
				local conform_ok, conform = pcall(require, "conform")
				if conform_ok and conform.formatters_by_ft then
					local current_ft = vim.bo.filetype
					if current_ft and current_ft ~= "" then
						local formatters = conform.formatters_by_ft[current_ft]
						if formatters and #formatters > 0 then
							print("  For " .. current_ft .. ":")
							for _, formatter in ipairs(formatters) do
								print("    🎨 " .. formatter)
							end
						else
							print("  No formatters configured for filetype: " .. current_ft)
						end
					end
				else
					print("  Formatting not available")
				end
			end, { desc = "Show LSP detection results, running servers, linters, and formatters" })

			-- Shorter alias
			vim.api.nvim_create_user_command("Lsp", "LspStatus", { desc = "Show LSP status (alias)" })

			-- ============================================
			-- GENERIC LSP RESTART COMMAND
			-- ============================================

			vim.api.nvim_create_user_command("LspRestart", function()
				local clients = vim.lsp.get_clients({ bufnr = 0 })
				if #clients == 0 then
					print("No LSP clients to restart")
					return
				end

				local client_names = {}
				for _, client in ipairs(clients) do
					table.insert(client_names, client.name)
					vim.lsp.stop_client(client.id)
				end

				print("Stopped: " .. table.concat(client_names, ", "))

				vim.defer_fn(function()
					vim.cmd("edit") -- Reload buffer to trigger LSP attachment
					print("Restarted LSP clients")
				end, 500)
			end, { desc = "Restart all LSP clients for current buffer" })

			-- ============================================
			-- FILTER ESLINT "FILE IGNORED" WARNINGS
			-- ============================================
			local original_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

			---@diagnostic disable-next-line: duplicate-set-field
			vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, handler_config)
				-- Check if this is from ESLint
				local client = vim.lsp.get_client_by_id(ctx.client_id)
				if client and client.name == "eslint" then
					-- Filter out the "file ignored" warnings
					if result and result.diagnostics and type(result.diagnostics) == "table" then
						local filtered = {}
						for _, diagnostic in ipairs(result.diagnostics) do
							if not diagnostic.message:match("File ignored because of a matching ignore pattern") then
								table.insert(filtered, diagnostic)
							end
						end
						result.diagnostics = filtered
					end
				end

				-- Call the original handler
				return original_handler(err, result, ctx, handler_config)
			end
		end,
	},

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
			"hrsh7th/cmp-buffer", -- Buffer completions
			"hrsh7th/cmp-path", -- Path completions
			"hrsh7th/cmp-cmdline", -- Command line completions
			"L3MON4D3/LuaSnip", -- Snippet engine
			"saadparwaiz1/cmp_luasnip", -- Snippet completions
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				completion = {
					completeopt = "menu,menuone,noselect",
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" }, -- LSP completions (this is the important one!)
					{ name = "luasnip" }, -- Snippet completions
				}, {
					{ name = "buffer" }, -- Buffer completions
					{ name = "path" }, -- Path completions
				}),
			})
		end,
	},

	-- Autopairs
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter", -- loads only when you start typing
		opts = { -- pass options here or omit for defaults
			fast_wrap = {}, -- Alt-e surrounds the word under cursor
			disable_filetype = { "TelescopePrompt", "vim" },
		},
	},

	-- Smear Cursor
	{
		"sphamba/smear-cursor.nvim",
		dependencies = { "lewis6991/gitsigns.nvim" },
		opts = {
			smear_between_buffers = true, -- smear when switching buffers
			smear_between_neighbor_lines = true, -- smear when moving line-to-line
			scroll_buffer_space = true, -- draw smear in buffer space when scrolling
			smear_insert_mode = true, -- enable in insert mode
			hide_target_hack = false,
			never_draw_over_target = true,
			stiffness = 0.8,
			trailing_stiffness = 0.5,
			stiffness_insert_mode = 0.7,
			trailing_stiffness_insert_mode = 0.7,
			damping = 0.8,
			damping_insert_mode = 0.8,
			distance_stop_animating = 0.5,
			time_interval = 7,
		},
	},

	--Lualine
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local dark_gray = "#2a2a2a"

			local custom_theme = {
				normal = {
					a = { bg = dark_gray, fg = "#4a90c2", gui = "bold" },
					b = { bg = dark_gray, fg = "#ffffff" },
					c = { bg = dark_gray, fg = "#ffffff" },
				},
				insert = {
					a = { bg = dark_gray, fg = "#4a90c2", gui = "bold" },
					b = { bg = dark_gray, fg = "#ffffff" },
					c = { bg = dark_gray, fg = "#ffffff" },
				},
				visual = {
					a = { bg = dark_gray, fg = "#4a90c2", gui = "bold" },
					b = { bg = dark_gray, fg = "#ffffff" },
					c = { bg = dark_gray, fg = "#ffffff" },
				},
				replace = {
					a = { bg = dark_gray, fg = "#4a90c2", gui = "bold" },
					b = { bg = dark_gray, fg = "#ffffff" },
					c = { bg = dark_gray, fg = "#ffffff" },
				},
				command = {
					a = { bg = dark_gray, fg = "#4a90c2", gui = "bold" },
					b = { bg = dark_gray, fg = "#ffffff" },
					c = { bg = dark_gray, fg = "#ffffff" },
				},
				inactive = {
					a = { bg = dark_gray, fg = "#666666" },
					b = { bg = dark_gray, fg = "#666666" },
					c = { bg = dark_gray, fg = "#666666" },
				},
			}

			require("lualine").setup({
				options = {
					theme = custom_theme,
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = {},
					lualine_b = {
						{
							"branch",
							icon = "",
							padding = { left = 1, right = 1 },
							color = { fg = "#4a90c2", bg = dark_gray, gui = "bold" },
						},
						{
							"filename",
							color = { fg = "#ffffff", bg = dark_gray },
							padding = { left = 1, right = 1 },
						},
					},
					lualine_c = {},
					lualine_x = { "encoding", "fileformat" },
					lualine_y = {
						"filetype",
						{
							"progress",
							padding = { left = 1, right = 1 },
						},
						{
							"location",
							padding = { left = 1, right = 1 },
						},
						{
							"mode",
							color = { fg = "#4a90c2", bg = dark_gray, gui = "bold" },
							padding = { left = 1, right = 1 },
						},
					},
					lualine_z = {},
				},
			})
		end,
	},

	-- DirDiff
	{
		"will133/vim-dirdiff",
		config = function()
			-- Optional configuration
			vim.g.DirDiffExcludes = "CVS,*.class,*.exe,.*.swp"
			vim.g.DirDiffIgnore = "Id:,Revision:,Date:"
			vim.g.DirDiffSort = 1
			vim.g.DirDiffWindowSize = 14
			vim.g.DirDiffInteractive = 0
			vim.g.DirDiffIgnoreCase = 0
		end,
		cmd = { "DirDiff", "DirDiffVim" },
	},
}, {
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrw",
				"netrwPlugin",
				"tar",
				"tarPlugin",
				"zip",
				"zipPlugin",
			},
		},
	},
})

-- Overwrite tab space for Python
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		vim.bo.shiftwidth = 4
		vim.bo.tabstop = 4
	end,
})

local conform = require("conform")
local lint = require("lint")

-- Async format+lint before write
local save_hooks = vim.api.nvim_create_augroup("SaveHooks", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
	group = save_hooks,
	pattern = "*",
	callback = function()
		local ft = vim.bo.filetype

		-- Organize imports for TypeScript/JavaScript files FIRST
		if ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact" then
			-- Check if LSP client is attached
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients > 0 then
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "source.organizeImports" },
						diagnostics = {},
					},
				})
				-- Wait for organize imports to complete
				vim.wait(100)
			end
		end

		-- Then format (skip SQL files)
		if ft ~= "sql" then
			conform.format({ lsp_fallback = true })
		end

		-- Finally lint
		if lint.linters_by_ft[ft] then
			lint.try_lint()
		end
	end,
})
