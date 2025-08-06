-- CORE REQUIREMENTS
-- brew install ripgrep git make
--
-- # Then add languages as you use them:
-- brew install python3       # When you work on Python projects
-- brew install node          # When you work on JS/TS projects
-- brew install go            # When you work on Go projects
-- brew install terraform     # When you work on Terraform files
-- brew install php composer  # When you work on PHP projects

-- Safely clear any existing write‑based groups (no error if they don't exist)
pcall(vim.api.nvim_clear_autocmds, { group = "AutoRefresh" })
pcall(vim.api.nvim_clear_autocmds, { group = "NvimTreeAutoRefresh" })

-- On FocusGained: check for external file changes, refresh Git signs, and reload the file‑tree if open
local focus_grp = vim.api.nvim_create_augroup("FocusActions", { clear = true })
vim.api.nvim_create_autocmd("FocusGained", {
	group = focus_grp,
	callback = function()
		pcall(vim.cmd, "silent! checktime") -- reload any changed buffers from disk
		pcall(require("gitsigns").refresh) -- refresh gitsigns gutter
		local api = require("nvim-tree.api") -- reload nvim-tree if it’s open
		if api.tree.is_visible() then
			api.tree.reload()
		end
	end,
})

-- This section automatically downloads and installs lazy.nvim if it's not already present
-- Think of this as ensuring the "app store" is installed before we try to download apps
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
vim.opt.wrap = true -- Don't wrap long lines
vim.opt.wrapscan = true -- Wrapp search back to top of file
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
vim.opt.updatetime = 100 -- Make CursorHold and friends fire more responsively
vim.opt.hidden = true -- "Hide" (keep in memory) modified buffers instead of blockiing
vim.opt.autowrite = true -- Write current buffer if modified commands like :edit, :make, :checktime
vim.opt.autowriteall = true -- Write all modified buffers before :next, :rewind, :last, external shell commands, etc.
vim.opt.lazyredraw = true -- Enable lazy redraw to reduce on-save stutters

-- Basic keymaps
vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
vim.keymap.set("n", "<C-s>", ":w<CR>", { desc = "Save file with Ctrl+S" })
vim.keymap.set(
	"n",
	"<leader>tt",
	":belowright 20split | terminal<CR>",
	{ desc = "Open terminal in split with 20-lines height" }
)
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "Terminal → Normal mode" })
vim.keymap.set("v", "<Tab>", ">gv", { noremap = true, silent = true, desc = "Indent and reselect" })
vim.keymap.set("v", "<S-Tab>", "<gv", { noremap = true, silent = true, desc = "Unindent and reselect" })
vim.keymap.set("n", "<leader>dm", ":delmarks!<Bar>delmarks A-Z0-9<CR>", { desc = "Delete all marks" })
vim.keymap.set("n", "gv", function()
	vim.cmd("vsplit")
	vim.lsp.buf.definition()
end)

-- Auto-detect project venv for python3_host_prog
local function find_project_python()
	local cwd = vim.fn.getcwd()
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
						num_pickers = 5,
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
							["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
							["<Esc>"] = actions.close,
							["<C-u>"] = false,
						},
						n = {
							["q"] = actions.close,
							["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
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
						find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
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
					update_root = true,
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
				end,
			})

			-- Gray out the “ignored” status (icon + name)
			vim.api.nvim_set_hl(0, "NvimTreeGitIgnoredHL", { fg = "#5c6370" })

			-- your existing auto-refresh logic for the tree view
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
		build = ":TSUpdate", -- Automatically update language parsers
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
				highlight = { enable = true }, -- Enable syntax highlighting
				indent = { enable = true }, -- Enable smart indentation
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
					"eslint_d",
					"stylua",
					"gopls",
					"goimports",
					"gofumpt",
					"golangci-lint",
					"php-cs-fixer",
					"phpstan",
					"pyright",
					"black",
					"isort",
					"flake8",
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
					isort = {
						command = "isort",
						args = { "--profile", "black", "-" },
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

					-- Lua
					stylua = {
						args = { "--stdin-filepath", "$FILENAME", "-" },
						stdin = true,
					},

					-- Go
					goimports = {
						args = { "-srcdir=" .. vim.fn.getcwd(), "-" },
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
					go = { "goimports" },
					php = { "php-cs-fixer" },
					python = { "isort", "black" },
					terraform = { "terraform_fmt" },
				},

				-- (optional) your existing save hook settings
				format_after_save = false,
				notify_on_error = true,
			})
		end,
	},

	-- Linting with selective loading based on project detection
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			local util = require("lspconfig.util")

			-- Project detection function (same as LSP config) - detects what linters are needed
			local function detect_project_features()
				local cwd = vim.fn.getcwd()

				-- Helper function to check if file exists
				local function file_exists(path)
					return vim.fn.filereadable(path) == 1
				end

				-- Helper function to check if directory exists
				local function dir_exists(path)
					return vim.fn.isdirectory(path) == 1
				end

				-- Only check for config files and common directories - no recursive searches (performance optimized)
				local features = {}

				-- JavaScript/TypeScript detection - looks for config files and source files
				features.has_js_ts = file_exists(cwd .. "/package.json")
					or file_exists(cwd .. "/tsconfig.json")
					or dir_exists(cwd .. "/node_modules")

				-- ESLint detection (more specific) - only if there's actually ESLint config
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

				-- Go detection - looks for go.mod or .go files
				features.has_go = file_exists(cwd .. "/go.mod")

				-- Python detection - looks for Python project files or .py files
				features.has_python = file_exists(cwd .. "/requirements.txt")
					or file_exists(cwd .. "/pyproject.toml")
					or file_exists(cwd .. "/setup.py")
					or file_exists(cwd .. "/Pipfile")

				-- PHP detection - looks for composer.json or .php files
				features.has_php = file_exists(cwd .. "/composer.json")

				-- Terraform detection - looks for .tf files or terraform lock file
				features.has_terraform = file_exists(cwd .. "/.terraform.lock.hcl") or dir_exists(cwd .. "/.terraform")

				return features
			end

			local project = detect_project_features()

			-- Configure ESLint linter only if project uses it
			if project.has_eslint then
				local eslint = lint.linters.eslint_d

				eslint.cwd = function(bufnr)
					return util.root_pattern(
						".eslintrc.js",
						".eslintrc.cjs",
						".eslintrc.json",
						"eslint.config.js",
						"package.json"
					)(vim.api.nvim_buf_get_name(bufnr)) or vim.fn.getcwd()
				end

				-- Skip eslint_d completely if no config is found
				eslint.condition = function(ctx)
					return vim.fn.filereadable(ctx.cwd .. "/package.json") == 1
						or vim.fn.glob(ctx.cwd .. "/.eslintrc.*") ~= ""
				end
			end

			-- Configure PHP linter (PHPStan) based on project detection
			if project.has_php then
				lint.linters.phpstan = {
					cmd = "phpstan",
					args = { "analyse", "--error-format", "raw", "$FILENAME" },
					stream = "stdout",
					ignore_exitcode = true,
				}
			end

			-- Configure Python linter (Flake8) based on project detection
			if project.has_python then
				lint.linters.flake8 = {
					cmd = "flake8",
					args = { "--format=%f:%l:%c: %m" },
					stdin = false,
					stream = "stdout",
					ignore_exitcode = true,
					parser = require("lint.parser").from_errorformat("%f:%l:%c: %m"),
				}
			end

			-- Only set up linters for detected project types (memory efficient approach)
			local linters_by_ft = {}

			-- ESLint for JavaScript/TypeScript projects (using eslint_d for better performance)
			if project.has_eslint then
				linters_by_ft.javascript = { "eslint_d" }
				linters_by_ft.typescript = { "eslint_d" }
				linters_by_ft.javascriptreact = { "eslint_d" }
				linters_by_ft.typescriptreact = { "eslint_d" }
				print("🟢 ESLint linting enabled for this project")
			end

			-- Go linting (golangci-lint) - comprehensive Go linter
			if project.has_go then
				linters_by_ft.go = { "golangcilint" }
				print("🟢 Go linting enabled for this project")
			end

			-- PHP linting (PHPStan) - static analysis for PHP
			if project.has_php then
				linters_by_ft.php = { "phpstan" }
				print("🟢 PHP linting enabled for this project")
			end

			-- Python linting (Flake8) - style and error checking for Python
			if project.has_python then
				linters_by_ft.python = { "flake8" }
				print("🟢 Python linting enabled for this project")
			end

			-- Terraform linting (TFLint) - Terraform configuration linter
			if project.has_terraform then
				linters_by_ft.terraform = { "tflint" }
				print("🟢 Terraform linting enabled for this project")
			end

			-- Apply the detected linter configuration
			lint.linters_by_ft = linters_by_ft

			-- Show summary of what was configured
			if next(linters_by_ft) == nil then
				print("⚪ No linters configured for this project type")
			end
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
			local ok, err = pcall(function()
				local lspconfig = require("lspconfig")

				-- Shared on_attach function to avoid repetition
				local function on_attach(_, bufnr)
					local bufopts = { noremap = true, silent = true, buffer = bufnr }

					-- LSP-related keymaps for navigating and interacting with language server features
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts) -- Go to declaration of symbol
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts) -- Go to definition of symbol
					vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts) -- Show hover information (documentation)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts) -- Go to implementation of symbol
					vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts) -- Show function signature help
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts) -- Rename symbol under cursor
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts) -- Trigger code action menu
					vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts) -- Show references to symbol

					-- Diagnostic keymaps for working with errors, warnings, hints, etc.
					vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, bufopts) -- Open floating window with diagnostic info
					vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, bufopts) -- Go to previous diagnostic in buffer
					vim.keymap.set("n", "]d", vim.diagnostic.goto_next, bufopts) -- Go to next diagnostic in buffer
					vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, bufopts) -- Populate location list with diagnostics
				end

				local short_flags = { debounce_text_changes = 50 }

				-- Project detection function - automatically detects what LSP servers are needed
				local function detect_project_features()
					local cwd = vim.fn.getcwd()

					-- Helper function to check if file exists
					local function file_exists(path)
						return vim.fn.filereadable(path) == 1
					end

					-- Helper function to check if directory exists
					local function dir_exists(path)
						return vim.fn.isdirectory(path) == 1
					end

					-- Only check for config files and common directories - no recursive searches (performance optimized)
					local features = {}

					-- Lua detection - looks for Lua project files or nvim config
					local nvim_config_path = vim.fn.stdpath("config")
					local current_file = vim.fn.expand("%:p") -- get full path of current file
					features.has_lua = file_exists(cwd .. "/.luarc.json")
						or file_exists(cwd .. "/init.lua")
						or string.find(cwd, nvim_config_path, 1, true) -- nvim config directory (working dir)
						or string.find(current_file, nvim_config_path, 1, true) -- nvim config file (current file)
						or dir_exists(cwd .. "/lua") -- common Lua project structure

					-- JavaScript/TypeScript detection - looks for config files and source files
					features.has_js_ts = file_exists(cwd .. "/package.json")
						or file_exists(cwd .. "/tsconfig.json")
						or dir_exists(cwd .. "/node_modules")

					-- ESLint detection (more specific) - only if there's actually ESLint config
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

					-- Go detection - looks for go.mod or .go files
					features.has_go = file_exists(cwd .. "/go.mod")

					-- Python detection - looks for Python project files or .py files
					features.has_python = file_exists(cwd .. "/requirements.txt")
						or file_exists(cwd .. "/pyproject.toml")
						or file_exists(cwd .. "/setup.py")
						or file_exists(cwd .. "/Pipfile")

					-- PHP detection - looks for composer.json or .php files
					features.has_php = file_exists(cwd .. "/composer.json")

					-- SQL detection - looks for SQL directories or files
					features.has_sql = dir_exists(cwd .. "/sql")
						or dir_exists(cwd .. "/migrations")
						or file_exists(cwd .. "/schema.sql")

					-- Terraform detection - looks for .tf files or terraform lock file
					features.has_terraform = file_exists(cwd .. "/.terraform.lock.hcl")
						or dir_exists(cwd .. "/.terraform")

					return features
				end

				-- Detect current project features
				local project = detect_project_features()

				print("🔍 LSP Detection Results:")
				print("  Lua: " .. (project.has_lua and "✅" or "❌"))
				print("  JS/TS: " .. (project.has_js_ts and "✅" or "❌"))
				print("  ESLint: " .. (project.has_eslint and "✅" or "❌"))
				print("  Go: " .. (project.has_go and "✅" or "❌"))
				print("  Python: " .. (project.has_python and "✅" or "❌"))
				print("  PHP: " .. (project.has_php and "✅" or "❌"))
				print("  SQL: " .. (project.has_sql and "✅" or "❌"))
				print("  Terraform: " .. (project.has_terraform and "✅" or "❌"))

				-- Lua setup - only for Lua projects and nvim configuration
				if project.has_lua then
					print("🟢 Starting Lua LSP")
					lspconfig.lua_ls.setup({
						on_attach = on_attach,
						flags = short_flags,
						settings = {
							Lua = {
								diagnostics = {
									globals = { "vim" },
								},
							},
						},
					})
				end

				-- TypeScript setup - only for JavaScript/TypeScript projects
				if project.has_js_ts then
					print("🟢 Starting TypeScript LSP")
					lspconfig.ts_ls.setup({
						on_attach = on_attach,
						flags = short_flags,
					})
				end

				-- ESLint setup - only if project has ESLint configuration. Need to run "npm install -g vscode-langservers-extracted"
				if project.has_eslint then
					print("🟢 Starting ESLint LSP")
					lspconfig.eslint.setup({
						on_attach = on_attach,
						flags = short_flags,
						root_dir = function(fname)
							local root = require("lspconfig.util").root_pattern(
								".eslintrc.js",
								".eslintrc.cjs",
								".eslintrc.json",
								"eslint.config.js",
								"package.json"
							)(fname)

							-- Only start if we have ESLint config
							if root then
								local has_config = vim.fn.filereadable(root .. "/package.json") == 1
									or vim.fn.glob(root .. "/.eslintrc.*") ~= ""
								return has_config and root or nil
							end
							return nil
						end,
						settings = {
							eslint = {
								enable = true,
								packageManager = "npm",
								autoFixOnSave = true,
							},
						},
					})
				end

				-- Golang setup - only for Go projects
				if project.has_go then
					print("🟢 Starting Go LSP")
					lspconfig.gopls.setup({
						on_attach = on_attach,
						flags = short_flags,
						settings = {
							gopls = {
								analyses = { unusedparams = true, shadow = true },
								staticcheck = true,
							},
						},
					})
				end

				-- Python setup - only for Python projects
				if project.has_python then
					print("🟢 Starting Python LSP")
					lspconfig.pyright.setup({
						on_attach = on_attach,
						flags = short_flags,
						before_init = function(_, config)
							config.settings = config.settings or {}
							config.settings.python = config.settings.python or {}
							config.settings.python.pythonPath = find_project_python()
						end,
						settings = {
							python = {
								analysis = {
									typeCheckingMode = "basic",
									autoSearchPaths = true,
									useLibraryCodeForTypes = true,
								},
							},
						},
					})
				end

				-- PHP setup - only for PHP projects
				if project.has_php then
					print("🟢 Starting PHP LSP")
					lspconfig.phpactor.setup({
						on_attach = on_attach,
						flags = short_flags,
						filetypes = { "php" },
						init_options = {
							["language_server.diagnostics_on_update"] = false,
							["language_server.diagnostics_on_save"] = false,
						},
					})
				end

				-- SQL setup - only for projects with SQL files
				if project.has_sql then
					print("🟢 Starting SQL LSP")
					lspconfig.sqls.setup({
						on_attach = on_attach,
						flags = short_flags,
						filetypes = { "sql" },
						settings = {
							sqls = {
								connections = {
									-- You can add database connections here if needed
									-- {
									--   name = "mydb",
									--   adapter = "mysql",
									--   host = "localhost",
									--   port = 3306,
									--   user = "root",
									--   database = "mydb"
									-- }
								},
							},
						},
					})
				end

				-- Terraform setup - only for Terraform projects
				if project.has_terraform then
					print("🟢 Starting Terraform LSP")
					lspconfig.terraformls.setup({
						on_attach = on_attach,
						flags = short_flags,
						filetypes = { "terraform", "tf" },
						settings = {
							terraform = {
								format = {
									enable = true,
								},
								validate = {
									enable = true,
								},
							},
						},
					})
				end
			end)

			if not ok then
				print("❌ LSP Configuration Error: " .. tostring(err))
			end

			-- Add command to show the same detection info you see on startup
			vim.api.nvim_create_user_command("LspStatus", function()
				local cwd = vim.fn.getcwd()

				-- Helper functions (same as above)
				local function file_exists(path)
					return vim.fn.filereadable(path) == 1
				end

				local function dir_exists(path)
					return vim.fn.isdirectory(path) == 1
				end

				-- Re-run the same detection logic
				local features = {}
				local nvim_config_path = vim.fn.stdpath("config")
				local current_file = vim.fn.expand("%:p") -- get full path of current file
				features.has_lua = file_exists(cwd .. "/.luarc.json")
					or file_exists(cwd .. "/init.lua")
					or string.find(cwd, nvim_config_path, 1, true) -- nvim config directory (working dir)
					or string.find(current_file, nvim_config_path, 1, true) -- nvim config file (current file)
					or dir_exists(cwd .. "/lua") -- common Lua project structure
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
				features.has_sql = dir_exists(cwd .. "/sql")
					or dir_exists(cwd .. "/migrations")
					or file_exists(cwd .. "/schema.sql")
				features.has_terraform = file_exists(cwd .. "/.terraform.lock.hcl") or dir_exists(cwd .. "/.terraform")

				-- Show the exact same format as startup
				print("🔍 LSP Detection Results:")
				print("  Lua: " .. (features.has_lua and "✅" or "❌"))
				print("  JS/TS: " .. (features.has_js_ts and "✅" or "❌"))
				print("  ESLint: " .. (features.has_eslint and "✅" or "❌"))
				print("  Go: " .. (features.has_go and "✅" or "❌"))
				print("  Python: " .. (features.has_python and "✅" or "❌"))
				print("  PHP: " .. (features.has_php and "✅" or "❌"))
				print("  SQL: " .. (features.has_sql and "✅" or "❌"))
				print("  Terraform: " .. (features.has_terraform and "✅" or "❌"))

				-- Show which LSP servers are currently running (using new API)
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

					-- Show all configured linters by project
					if features.has_eslint then
						print("  📁 Project: ESLint (eslint_d)")
					end
					if features.has_go then
						print("  📁 Project: Go (golangci-lint)")
					end
					if features.has_python then
						print("  📁 Project: Python (flake8)")
					end
					if features.has_php then
						print("  📁 Project: PHP (phpstan)")
					end
					if features.has_terraform then
						print("  📁 Project: Terraform (tflint)")
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

					-- Show all configured formatters by project
					if features.has_lua then
						print("  📁 Project: Lua (stylua)")
					end
					if features.has_js_ts then
						print("  📁 Project: JS/TS (prettier)")
					end
					if features.has_go then
						print("  📁 Project: Go (goimports)")
					end
					if features.has_python then
						print("  📁 Project: Python (isort, black)")
					end
					if features.has_php then
						print("  📁 Project: PHP (php-cs-fixer)")
					end
					if features.has_terraform then
						print("  📁 Project: Terraform (terraform_fmt)")
					end
				else
					print("  Formatting not available")
				end
			end, { desc = "Show LSP detection results, running servers, linters, and formatters" })

			-- Shorter alias for quick access
			vim.api.nvim_create_user_command("Lsp", "LspStatus", { desc = "Show LSP status (alias)" })
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
			local custom_theme = {
				normal = {
					a = { bg = "#4a90c2", fg = "#ffffff", gui = "bold" },
					b = { bg = "#84d675", fg = "#000000" },
					c = { bg = "#1c1c1c", fg = "#ffffff" },
				},
				insert = {
					a = { bg = "#4a90c2", fg = "#ffffff", gui = "bold" },
					b = { bg = "#84d675", fg = "#000000" },
					c = { bg = "#1c1c1c", fg = "#ffffff" },
				},
				visual = {
					a = { bg = "#4a90c2", fg = "#ffffff", gui = "bold" },
					b = { bg = "#84d675", fg = "#000000" },
					c = { bg = "#1c1c1c", fg = "#ffffff" },
				},
				replace = {
					a = { bg = "#4a90c2", fg = "#ffffff", gui = "bold" },
					b = { bg = "#84d675", fg = "#000000" },
					c = { bg = "#1c1c1c", fg = "#ffffff" },
				},
				command = {
					a = { bg = "#4a90c2", fg = "#ffffff", gui = "bold" },
					b = { bg = "#84d675", fg = "#000000" },
					c = { bg = "#1c1c1c", fg = "#ffffff" },
				},
				inactive = {
					a = { bg = "#2c2c2c", fg = "#666666" },
					b = { bg = "#2c2c2c", fg = "#666666" },
					c = { bg = "#1c1c1c", fg = "#666666" },
				},
			}

			require("lualine").setup({
				options = {
					theme = custom_theme,
					component_separators = { left = "\u{E0B1}", right = "\u{E0B3}" },
					section_separators = { left = "\u{E0B0}", right = "\u{E0B2}" },
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = {
						{
							"branch",
							icon = "",
						},
					},
					lualine_c = {
						{
							function()
								-- Get diagnostics
								local diagnostics = vim.diagnostic.get(0)
								local error_count = #vim.tbl_filter(function(d)
									return d.severity == 1
								end, diagnostics)
								local warn_count = #vim.tbl_filter(function(d)
									return d.severity == 2
								end, diagnostics)
								local info_count = #vim.tbl_filter(function(d)
									return d.severity == 3
								end, diagnostics)
								local hint_count = #vim.tbl_filter(function(d)
									return d.severity == 4
								end, diagnostics)

								-- Get git diff info
								local diff_added = vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.added or 0
								local diff_modified = vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.changed
									or 0
								local diff_removed = vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.removed
									or 0

								-- Build diagnostics and git diff string
								local status_str = ""

								-- Add diagnostics
								if error_count > 0 then
									status_str = status_str .. "◯" .. error_count .. " "
								end
								if warn_count > 0 then
									status_str = status_str .. "△" .. warn_count .. " "
								end
								if info_count > 0 then
									status_str = status_str .. "○" .. info_count .. " "
								end
								if hint_count > 0 then
									status_str = status_str .. "◇" .. hint_count .. " "
								end

								-- Add git diff info
								if diff_added > 0 then
									status_str = status_str .. "+" .. diff_added .. " "
								end
								if diff_modified > 0 then
									status_str = status_str .. "~" .. diff_modified .. " "
								end
								if diff_removed > 0 then
									status_str = status_str .. "-" .. diff_removed .. " "
								end

								-- Get relative path from current working directory
								local filename = vim.fn.expand("%:.")
								if filename == "" then
									filename = "[No Name]"
								end

								-- Combine with custom styling
								if status_str ~= "" then
									return string.format(
										"%%#DiagnosticSection#%s%%#Arrow#\u{E0B0}%%#FilenameSection# %s",
										status_str:gsub("%s+$", ""),
										filename
									)
								else
									return filename
								end
							end,
							color = { fg = "#ffffff", bg = "#1c1c1c" },
						},
					},
					lualine_x = { "encoding", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			})

			-- Create custom highlight groups
			vim.cmd([[
			highlight DiagnosticSection guifg=#ffffff guibg=#2a2a2a
			highlight Arrow guifg=#2a2a2a guibg=#1c1c1c
			highlight FilenameSection guifg=#ffffff guibg=#1c1c1c
		]])
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

		-- Skip formatting for SQL files entirely
		if ft ~= "sql" then
			conform.format({ lsp_fallback = true })
		end

		if lint.linters_by_ft[ft] then
			lint.try_lint()
		end
	end,
})
