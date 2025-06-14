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
vim.opt.ignorecase = true -- Case-insensitive searching
vim.opt.smartcase = true -- But case-sensitive if search contains uppercase
vim.opt.termguicolors = true -- Enable full color support
vim.opt.signcolumn = "yes" -- Always show the sign column (like VSCode's gutter)
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.splitright = true -- vertical splits appear on the RIGHT
vim.opt.splitbelow = true -- horizontal splits appear BELOW (optional)
vim.opt.equalalways = true -- equalize whenever you open/close a split
vim.opt.eadirection = "both" -- adjust both height and width

-- Basic keymaps
vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
vim.keymap.set("n", "<C-s>", ":w<CR>", { desc = "Save file with Ctrl+S" })
vim.keymap.set("n", "<leader>tt", ":belowright split | terminal<CR>", { desc = "Open terminal in split" })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "Terminal → Normal mode" })

-- Auto-equalize all splits whenever the UI is resized
vim.api.nvim_create_autocmd("VimResized", {
	pattern = "*",
	command = "tabdo wincmd =", -- use just "wincmd =" if you don't use tabs
})

-- This is where we'll define our plugins
-- Think of this as your "extensions" list
require("lazy").setup({
	-- Fuzzy file finder - equivalent to VSCode's Ctrl+P
	{
		"junegunn/fzf.vim",
		dependencies = {
			-- This installs the core fzf binary that the vim plugin uses
			{ "junegunn/fzf", build = ":call fzf#install()" },
		},
		-- These are the keyboard shortcuts for the fuzzy finder
		keys = {
			{ "<C-p>", ":Files<CR>", desc = "Find files" },
			{ "<C-f>", ":Rg<CR>", desc = "Search in files" },
			{ "<leader>b", ":Buffers<CR>", desc = "Find open buffers" },
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
		dependencies = { "nvim-tree/nvim-web-devicons" }, -- Pretty file icons
		config = function()
			-- This function runs after the plugin is loaded and sets it up
			require("nvim-tree").setup({
				view = {
					width = 30, -- Sidebar width
				},
				renderer = {
					group_empty = true, -- Group empty folders
				},
				update_focused_file = {
					enable = true,
					update_root = true,
				},
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

			lspconfig.gopls.setup({
				on_attach = on_attach,
				settings = {
					gopls = {
						analyses = { unusedparams = true, shadow = true },
						staticcheck = true,
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
					["<CR>"] = cmp.mapping.confirm({ select = true }),
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
