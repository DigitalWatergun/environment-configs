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

-- Autoreload buffer and silent warnings
local auto_read_grp = vim.api.nvim_create_augroup("AutoRead", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained", "BufWritePost" }, {
	group = auto_read_grp,
	callback = function()
		vim.cmd("checktime")
	end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
	group = auto_read_grp,
	pattern = "*",
	callback = function()
		vim.cmd("echohl WarningMsg | echo 'File changed on disk, reloaded.' | echohl None")
	end,
})

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
			require("nvim-tree").setup({
				view = {
					width = 40, -- Sidebar width
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
			})

			vim.api.nvim_create_augroup("NvimTreeAutoRefresh", { clear = true })

			vim.api.nvim_create_autocmd("FocusGained", {
				group = "NvimTreeAutoRefresh",
				callback = function()
					if require("nvim-tree.view").is_visible() then
						vim.cmd("NvimTreeRefresh")
					end
				end,
			})

			vim.api.nvim_create_autocmd("BufWritePost", {
				group = "NvimTreeAutoRefresh",
				callback = function()
					if require("nvim-tree.view").is_visible() then
						vim.cmd("NvimTreeRefresh")
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
				},
				highlight = { enable = true }, -- Enable syntax highlighting
				indent = { enable = true }, -- Enable smart indentation
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
				},
			})
		end,
	},

	-- Formatting
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("conform").setup({
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
				},
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

			lint.linters_by_ft = {
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				go = { "golangcilint" },
			}

			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
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
			local function on_attach(client, bufnr)
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
})
