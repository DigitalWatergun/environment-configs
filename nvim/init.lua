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
vim.opt.updatetime = 300 -- Make CursorHold and friends fire more responsively
vim.opt.hidden = true -- "Hide" (keep in memory) modified buffers instead of blockiing
vim.opt.autowrite = true -- Write current buffer if modified commands like :edit, :make, :checktime
vim.opt.autowriteall = true -- Write all modified buffers before :next, :rewind, :last, external shell commands, etc.

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
			-- This native extension makes sorting much faster
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
						-- Use fd if available (faster than find)
						find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
						-- Alternative if you don't have rg:
						-- find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
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

			-- Load the fzf extension for much better performance
			telescope.load_extension("fzf")
		end,
		keys = {
			{ "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
			{ "<C-f>", "<cmd>Telescope live_grep<cr>", desc = "Live grep search" },
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
		"tomasr/molokai", -- This is the GitHub repository for the molokai theme
		name = "molokai", -- Give it a friendly name for lazy.nvim to reference
		priority = 1000, -- Load this plugin early (themes should load before other plugins)
		config = function()
			-- This function runs after the plugin loads and activates the theme
			vim.cmd.colorscheme("molokai") -- This is equivalent to running :colorscheme molokai
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
			vim.api.nvim_create_autocmd("BufWritePost", {
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

	-- Oil plugin for file management / view / explorer
	{
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local oil = require("oil")
			local columns = require("oil.columns")

			oil.setup({
				-- pick exactly the columns you want to see:
				columns = {
					columns.icon, -- file/folder icon
					columns.permissions, -- unix perms
					columns.size, -- file size
					columns.mtime, -- last-modified timestamp
					columns.git_status, -- ▶ staged/unstaged/untracked marks
					columns.diagnostics, -- ▶ LSP error/warning/hint counts
				},
				-- allow two sign-columns (index + worktree / diagnostics)
				win_options = {
					-- two sign-columns for index+worktree,
					-- plus enable absolute line-numbers
					signcolumn = "yes:2",
					number = true,
					relativenumber = false,
				},

				experimental_watch_for_changes = true,

				view_options = {
					show_hidden = true,
				},
			})
		end,
		keys = {
			{
				"<leader>o",
				function()
					require("oil").open_float()
				end,
				desc = "Open oil.nvim file browser",
			},
		},
	},

	{
		"refractalize/oil-git-status.nvim",
		dependencies = { "stevearc/oil.nvim" },
		config = function()
			require("oil-git-status").setup({})
		end,
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
					"intelephense",
					"php-cs-fixer",
					"phpstan",
					"pyright",
					"black",
					"isort",
					"flake8",
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
					-- override built-in isort
					isort = {
						args = { "--profile", "black", "$FILENAME" },
						env = { PATH = venv_path() },
					},
					-- override built-in black
					black = {
						args = { "--quiet", "$FILENAME" },
						env = { PATH = venv_path() },
					},
					-- override built-in php-cs-fixer
					["php-cs-fixer"] = {
						args = { "fix", "--quiet", "$FILENAME" },
						env = { PATH = vim.fn.getcwd() .. "/vendor/bin:" .. vim.env.PATH },
					},
				},

				-- 2) Map each ft to a list of *formatter names*
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
				},

				-- (optional) your existing save hook settings
				format_after_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
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
			local util = require("lspconfig.util")
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

			lint.linters.phpstan = {
				cmd = "phpstan",
				args = { "analyse", "--error-format", "raw", "$FILENAME" },
				stream = "stdout",
				ignore_exitcode = true,
			}

			lint.linters.flake8 = {
				cmd = "flake8",
				args = { "--format=default", "-" }, -- read from stdin
				stdin = true,
				stream = "stdout",
				ignore_exitcode = true,
			}

			lint.linters_by_ft = {
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				go = { "golangcilint" },
				php = { "phpstan" },
				python = { "flake8" },
			}

			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd("BufWritePost", {
				group = lint_augroup,
				pattern = "*",
				callback = function()
					local ft = vim.bo.filetype
					if not lint.linters_by_ft[ft] then
						return
					end
					vim.defer_fn(function()
						lint.try_lint()
					end, 200)
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
				enabled = true, -- enable virtual text blame (default: false)
				delay = 500, -- delay in ms before blame appears (default: 1000)
				virtual_text_pos = "eol", -- where to show the text: 'eol' | 'inline' | 'right_align' (default: 'eol')
				date_format = "%Y-%m-%d", -- date format (same as strftime)
				filetype_exclude = { "NvimTree", "toggleterm", "dashboard" }, -- filetypes to disable in
			})
			vim.keymap.set("n", "<leader>gb", "<cmd>GitBlameToggle<CR>", { desc = "Toggle Git blame virtual text" }) -- toggle with <leader>gb
		end,
	},

	-- Git Conflicts (git-conflict.nvim)
	-- Buffer-local mappings installed when a Git conflict is detected:
	--   co   → choose “ours”   (keep your current changes)
	--   ct   → choose “theirs” (keep incoming changes)
	--   cb   → choose both     (keep both sets of changes)
	--   c0   → choose none     (remove all conflict markers)
	--   ]x   → jump to NEXT conflict hunk
	--   [x   → jump to PREVIOUS conflict hunk
	{
		"akinsho/git-conflict.nvim",
		version = "*",
		event = "BufReadPre",
		config = true, -- auto-runs require('git-conflict').setup()
	},

	-- LSP
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
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

			-- TypeScript setup
			lspconfig.ts_ls.setup({
				on_attach = on_attach,
			})

			-- Lua setup
			lspconfig.lua_ls.setup({
				on_attach = on_attach,
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
					},
				},
			})

			-- Golang setup
			lspconfig.gopls.setup({
				on_attach = on_attach,
				settings = {
					gopls = {
						analyses = { unusedparams = true, shadow = true },
						staticcheck = true,
					},
				},
			})

			-- ESLint setup. Need to run "npm install -g vscode-langservers-extracted"
			lspconfig.eslint.setup({
				on_attach = on_attach,
				settings = {
					eslint = {
						enable = true,
						packageManager = "npm",
						autoFixOnSave = true,
					},
				},
				root_dir = function(fname)
					return require("lspconfig.util").root_pattern(
						".eslintrc.js",
						".eslintrc.cjs",
						".eslintrc.json",
						"eslint.config.js",
						"package.json"
					)(fname)
				end,
			})

			lspconfig.pyright.setup({
				on_attach = on_attach, -- reuse your shared on_attach
				settings = {
					python = {
						analysis = {
							typeCheckingMode = "basic", -- or "strict"
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
						},
					},
				},
			})

			lspconfig.pyright.setup({
				on_attach = on_attach,
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

			lspconfig.intelephense.setup({
				on_attach = on_attach, -- reuse your shared on_attach
				settings = {
					intelephense = {
						files = { maxSize = 5000000 }, -- Allow larger files if needed
						environment = {
							includePaths = { "vendor/" }, -- Composer dependencies
						},
						-- licenceKey = "your-key-here", -- uncomment if you have a paid licence
					},
				},
			})
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
			never_draw_over_target = true, -- and never draw your smear exactly under the real cursor
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

-- Auto-refresh everything in one place
local auto_refresh = vim.api.nvim_create_augroup("AutoRefresh", { clear = true })

-- On idle/focus/write/etc: stat files, refresh git signs, and restart dead LSPs
vim.api.nvim_create_autocmd({ "FocusGained", "BufWritePost" }, {
	group = auto_refresh,
	callback = function(ev)
		pcall(vim.cmd, "silent! checktime") -- Re-stat and reload changed files on disk
		pcall(vim.cmd, "Gitsigns refresh")
		-- Restart any LSP client that’s stopped
		for _, client in ipairs(vim.lsp.get_clients()) do
			-- only try to restart if both the check and the start method are present
			if type(client.is_stopped) == "function" and client:is_stopped() and type(client.start) == "function" then
				pcall(client.start, client)
			end
		end
	end,
})

-- If a file changed on disk via an external shell command, show a warning
vim.api.nvim_create_autocmd("FileChangedShellPost", {
	group = auto_refresh,
	pattern = "*",
	callback = function()
		vim.cmd("echohl WarningMsg | echo 'File changed on disk, reloaded.' | echohl None")
	end,
})

-- Helper to save the current buffer if it's dirty
local function save_current()
	-- skip non-file buffers (oil, netrw, etc.)
	if vim.bo.buftype ~= "" then
		return
	end

	-- only write real, modified files
	if vim.bo.modifiable and vim.bo.modified then
		vim.cmd("silent! update")
	end
end

-- Auto-save any dirty buffer on *every* BufLeave (window/nav change, buffer switch, ctrl-^, etc.)
vim.api.nvim_create_autocmd("BufLeave", {
	group = auto_refresh, -- reuse your existing AutoRefresh group
	callback = save_current, -- calls your helper which does `silent! update`
})

-- Wrap split-motion keys (<C-w>h/j/k/l)
for _, d in ipairs({ "h", "j", "k", "l" }) do
	vim.keymap.set("n", "<C-w>" .. d, function()
		save_current()
		vim.cmd("wincmd " .. d)
	end, { noremap = true, silent = true })
end

-- Wrap Telescope shortcuts (use built-in functions, not raw :Telescope commands)
local tb = require("telescope.builtin")
vim.keymap.set("n", "<C-p>", function()
	save_current()
	tb.find_files()
end, { noremap = true, silent = true })

vim.keymap.set("n", "<C-f>", function()
	save_current()
	tb.live_grep()
end, { noremap = true, silent = true })
