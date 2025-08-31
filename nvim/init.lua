-- PLACE THIS FILE IN YOUR CONFIG FOLDER: ~/.config/nvim/init.lua
--
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
pcall(vim.loader.enable) -- Lua module caching (NVIM ≥0.9)
vim.g.loaded_netrw = 1 -- fully disable netrw for nvim-tree
vim.g.loaded_netrwPlugin = 1

-- On FocusGained: check for external file changes, refresh Git signs, and reload the file‑tree if open
local focus_grp = vim.api.nvim_create_augroup("FocusActions", { clear = true })
vim.api.nvim_create_autocmd("FocusGained", {
	group = focus_grp,
	callback = function()
		vim.cmd.checktime({ mods = { silent = true, emsg_silent = true } }) -- reload any changed buffers from disk
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
vim.opt.updatetime = 100 -- Make CursorHold and friends fire more responsively
vim.opt.hidden = true -- "Hide" (keep in memory) modified buffers instead of blocking
vim.opt.autowrite = true -- Write current buffer if modified commands like :edit, :make, :checktime
vim.opt.autowriteall = true -- Write all modified buffers before :next, :rewind, :last, external shell commands, etc.
vim.opt.lazyredraw = false -- Lazy redraw to reduce on-save stutters
vim.opt.backup = false -- No backup files (file.txt~)
vim.opt.writebackup = true -- Temporary backup during write
vim.opt.swapfile = false -- No swap files (.file.txt.swp)
vim.opt.undofile = false -- No persistent undo file
vim.opt.undolevels = 500 -- Limit undo history in memory
vim.opt.foldenable = false -- Diasble code folding
vim.opt.foldmethod = "manual" -- Disable Neovim fold calculation
vim.opt.shada = "" -- Disable shared data

-- Basic keymaps
vim.keymap.set("n", "<C-s>", ":w<CR>", { desc = "Save file with Ctrl+S" })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "Terminal → Normal mode" })
vim.keymap.set("v", "<Tab>", ">gv", { noremap = true, silent = true, desc = "Indent and reselect" })
vim.keymap.set("v", "<S-Tab>", "<gv", { noremap = true, silent = true, desc = "Unindent and reselect" })
vim.keymap.set("n", "<leader>dm", ":delmarks!<Bar>delmarks A-Z0-9<CR>", { desc = "Delete all marks" })
vim.keymap.set("n", "gv", function()
	vim.cmd("vsplit")
	vim.lsp.buf.definition()
end)
vim.keymap.set("n", "gt", function()
	vim.cmd("tab split")
	vim.lsp.buf.definition()
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

-- Track timers to avoid duplicates
vim.g.buffer_timers = vim.g.buffer_timers or {}
vim.api.nvim_create_autocmd("BufHidden", {
	callback = function(args)
		local buf = args.buf

		-- Cancel existing timer for this buffer if one exists
		if vim.g.buffer_timers[buf] then
			vim.fn.timer_stop(vim.g.buffer_timers[buf])
		end

		-- Start new 10-minute timer
		vim.g.buffer_timers[buf] = vim.fn.timer_start(10 * 60 * 1000, function()
			if
				vim.api.nvim_buf_is_valid(buf)
				and vim.fn.buflisted(buf)
				and not vim.bo[buf].modified
				and #vim.fn.win_findbuf(buf) == 0
			then
				pcall(vim.api.nvim_buf_delete, buf, { force = false })
			end
			-- Clear the timer reference
			vim.g.buffer_timers[buf] = nil
		end)
	end,
})

-- Clean up timers when buffer is deleted
vim.api.nvim_create_autocmd("BufDelete", {
	callback = function(args)
		if vim.g.buffer_timers[args.buf] then
			vim.fn.timer_stop(vim.g.buffer_timers[args.buf])
			vim.g.buffer_timers[args.buf] = nil
		end
	end,
})

-- Manually free / clean up memory
vim.api.nvim_create_user_command("MemClean", function()
	-- Close all hidden buffers
	local buffers = vim.api.nvim_list_bufs()
	local closed = 0
	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_loaded(buf) and not vim.bo[buf].modified then
			local wins = vim.fn.win_findbuf(buf)
			if #wins == 0 then
				if pcall(vim.api.nvim_buf_delete, buf, { force = false }) then
					closed = closed + 1
				end
			end
		end
	end

	-- Force garbage collection
	collectgarbage("collect")

	print(string.format("Memory cleaned (%d buffers closed)", closed))
end, {})

-- Project detection function with subdirectory scanning
local function detect_project_features()
	local cwd = vim.fn.getcwd()
	local features = {}

	-- Cache to avoid repeated searches
	local _cache = {}

	-- Helper function to check if file exists
	local function file_exists(path)
		if _cache[path] ~= nil then
			return _cache[path]
		end
		local result = vim.fn.filereadable(path) == 1
		_cache[path] = result
		return result
	end

	-- Helper function to check if directory exists
	local function dir_exists(path)
		if _cache[path .. "_dir"] ~= nil then
			return _cache[path .. "_dir"]
		end
		local result = vim.fn.isdirectory(path) == 1
		_cache[path .. "_dir"] = result
		return result
	end

	-- Advanced file finder with depth limit
	-- Uses vim.fs.find() which is efficient and supports depth limits
	local function find_files(patterns, opts)
		opts = opts or {}
		opts.limit = opts.limit or 10 -- Stop after finding 10 matches
		opts.type = opts.type or "file"
		opts.path = opts.path or cwd
		opts.upward = false -- Search downward into subdirectories

		-- Search up to 3 levels deep by default (configurable)
		local max_depth = opts.max_depth or 3

		-- For vim.fs.find, we need to set the depth using the 'limit' for depth
		-- We'll use vim.fs.dir to iterate with depth control instead
		local found = {}

		local function search_recursive(dir, current_depth)
			if current_depth > max_depth then
				return
			end

			-- Use vim.fn.globpath for pattern matching
			for _, pattern in ipairs(patterns) do
				local matches = vim.fn.globpath(dir, pattern, false, true)
				for _, match in ipairs(matches) do
					table.insert(found, match)
					if #found >= opts.limit then
						return found
					end
				end

				-- Also search immediate subdirectories
				if current_depth < max_depth then
					local subdirs = vim.fn.globpath(dir, "*", false, true)
					for _, subdir in ipairs(subdirs) do
						if vim.fn.isdirectory(subdir) == 1 then
							-- Skip common non-project directories
							local dirname = vim.fn.fnamemodify(subdir, ":t")
							if
								not vim.tbl_contains({
									"node_modules",
									".git",
									"vendor",
									"target",
									"dist",
									"build",
									".venv",
									"venv",
									"__pycache__",
									".idea",
									".vscode",
									"coverage",
									".pytest_cache",
								}, dirname)
							then
								search_recursive(subdir, current_depth + 1)
								if #found >= opts.limit then
									return found
								end
							end
						end
					end
				end
			end
		end

		search_recursive(cwd, 1)
		return found
	end

	-- Lua detection - enhanced with subdirectory search
	local nvim_config_path = vim.fn.stdpath("config")
	local current_file = vim.fn.expand("%:p")
	features.has_lua = file_exists(cwd .. "/.luarc.json")
		or file_exists(cwd .. "/init.lua")
		or string.find(cwd, nvim_config_path, 1, true)
		or string.find(current_file, nvim_config_path, 1, true)
		or dir_exists(cwd .. "/lua")
		or #find_files({ "*.lua", ".luarc.json" }, { limit = 1, max_depth = 3 }) > 0

	-- JavaScript/TypeScript detection - enhanced
	features.has_js_ts = file_exists(cwd .. "/package.json")
		or file_exists(cwd .. "/tsconfig.json")
		or file_exists(cwd .. "/jsconfig.json")
		or file_exists(cwd .. "/package-lock.json")
		or file_exists(cwd .. "/yarn.lock")
		or file_exists(cwd .. "/pnpm-lock.yaml")
		or dir_exists(cwd .. "/node_modules")
		or #find_files({
				"*.js",
				"*.jsx",
				"*.ts",
				"*.tsx",
				"*.mjs",
				"*.cjs",
				"package.json",
				"tsconfig.json",
				"jsconfig.json",
			}, { limit = 1, max_depth = 3 })
			> 0

	-- ESLint detection - more thorough
	local function has_eslint_config()
		-- First check root directory
		local root_configs = {
			".eslintrc.js",
			".eslintrc.cjs",
			".eslintrc.mjs",
			".eslintrc.json",
			".eslintrc.yaml",
			".eslintrc.yml",
			"eslint.config.js",
			"eslint.config.mjs",
			"eslint.config.cjs",
			".eslintrc",
		}

		for _, config in ipairs(root_configs) do
			if file_exists(cwd .. "/" .. config) then
				return true
			end
		end

		-- Check subdirectories
		local found_configs = find_files(root_configs, { limit = 1, max_depth = 2 })
		return #found_configs > 0
	end

	features.has_eslint = features.has_js_ts and has_eslint_config()

	-- Go detection - enhanced
	features.has_go = file_exists(cwd .. "/go.mod")
		or file_exists(cwd .. "/go.sum")
		or #find_files({ "*.go", "go.mod", "go.sum" }, { limit = 1, max_depth = 3 }) > 0

	-- Python detection - enhanced
	features.has_python = file_exists(cwd .. "/requirements.txt")
		or file_exists(cwd .. "/pyproject.toml")
		or file_exists(cwd .. "/setup.py")
		or file_exists(cwd .. "/setup.cfg")
		or file_exists(cwd .. "/Pipfile")
		or file_exists(cwd .. "/poetry.lock")
		or file_exists(cwd .. "/environment.yml")
		or file_exists(cwd .. "/environment.yaml")
		or file_exists(cwd .. "/conda.yaml")
		or file_exists(cwd .. "/tox.ini")
		or file_exists(cwd .. "/.python-version")
		or dir_exists(cwd .. "/.venv")
		or dir_exists(cwd .. "/venv")
		or #find_files({
				"*.py",
				"requirements.txt",
				"pyproject.toml",
				"setup.py",
				"Pipfile",
				"poetry.lock",
			}, { limit = 1, max_depth = 3 })
			> 0

	-- PHP detection - SIGNIFICANTLY ENHANCED
	features.has_php = file_exists(cwd .. "/composer.json")
		or file_exists(cwd .. "/composer.lock")
		or file_exists(cwd .. "/index.php")
		or file_exists(cwd .. "/phpunit.xml")
		or file_exists(cwd .. "/phpunit.xml.dist")
		or file_exists(cwd .. "/phpstan.neon")
		or file_exists(cwd .. "/phpstan.neon.dist")
		or file_exists(cwd .. "/psalm.xml")
		or file_exists(cwd .. "/.php-cs-fixer.php")
		or file_exists(cwd .. "/.php-cs-fixer.dist.php")
		or file_exists(cwd .. "/artisan") -- Laravel
		or file_exists(cwd .. "/wp-config.php") -- WordPress
		or dir_exists(cwd .. "/vendor") -- Composer vendor directory
		or #find_files({
				"*.php",
				"composer.json",
				"composer.lock",
				"index.php",
				"phpunit.xml",
				"artisan",
			}, { limit = 1, max_depth = 3 })
			> 0

	-- SQL detection - enhanced
	features.has_sql = dir_exists(cwd .. "/sql")
		or dir_exists(cwd .. "/migrations")
		or dir_exists(cwd .. "/database")
		or file_exists(cwd .. "/schema.sql")
		or #find_files({
				"*.sql",
				"schema.sql",
				"migrations/*.sql",
			}, { limit = 1, max_depth = 3 })
			> 0

	-- Terraform detection - enhanced
	features.has_terraform = file_exists(cwd .. "/.terraform.lock.hcl")
		or dir_exists(cwd .. "/.terraform")
		or file_exists(cwd .. "/main.tf")
		or file_exists(cwd .. "/variables.tf")
		or file_exists(cwd .. "/outputs.tf")
		or #find_files({
				"*.tf",
				"*.tfvars",
				".terraform.lock.hcl",
			}, { limit = 1, max_depth = 3 })
			> 0

	-- Rust detection (bonus)
	features.has_rust = file_exists(cwd .. "/Cargo.toml")
		or file_exists(cwd .. "/Cargo.lock")
		or #find_files({ "*.rs", "Cargo.toml" }, { limit = 1, max_depth = 3 }) > 0

	-- Java detection (bonus)
	features.has_java = file_exists(cwd .. "/pom.xml")
		or file_exists(cwd .. "/build.gradle")
		or file_exists(cwd .. "/build.gradle.kts")
		or file_exists(cwd .. "/settings.gradle")
		or file_exists(cwd .. "/gradlew")
		or #find_files({
			"*.java",
			"pom.xml",
			"build.gradle",
		}, { limit = 1, max_depth = 3 }) > 0

	return features
end

-- Export the function so it can be used in both LSP and linting configs
_G.detect_project_features = detect_project_features

-- Optional: Add a command to show detected features with more detail
vim.api.nvim_create_user_command("ProjectInfo", function()
	local features = detect_project_features()
	local cwd = vim.fn.getcwd()

	print("🔍 Project Detection Results for: " .. cwd)
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	-- Create a sorted list of features for consistent display
	local feature_list = {
		{ "Lua", features.has_lua },
		{ "JavaScript/TypeScript", features.has_js_ts },
		{ "ESLint", features.has_eslint },
		{ "Go", features.has_go },
		{ "Python", features.has_python },
		{ "PHP", features.has_php },
		{ "SQL", features.has_sql },
		{ "Terraform", features.has_terraform },
		{ "Rust", features.has_rust },
		{ "Java", features.has_java },
	}

	for _, feature in ipairs(feature_list) do
		local name, detected = feature[1], feature[2]
		local icon = detected and "✅" or "❌"
		local status = detected and "Detected" or "Not found"
		print(string.format("  %-25s %s %s", name, icon, status))
	end

	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	-- Show which files triggered the detection
	if features.has_php then
		print("\n📁 PHP Detection Triggers:")
		local triggers = {}
		if vim.fn.filereadable(cwd .. "/composer.json") == 1 then
			table.insert(triggers, "  • composer.json (root)")
		end
		if vim.fn.filereadable(cwd .. "/composer.lock") == 1 then
			table.insert(triggers, "  • composer.lock (root)")
		end
		if vim.fn.filereadable(cwd .. "/index.php") == 1 then
			table.insert(triggers, "  • index.php (root)")
		end
		if vim.fn.isdirectory(cwd .. "/vendor") == 1 then
			table.insert(triggers, "  • vendor/ directory (root)")
		end

		-- Check for PHP files in subdirectories
		local php_files = vim.fn.globpath(cwd, "**/*.php", false, true)
		if #php_files > 0 then
			table.insert(triggers, string.format("  • %d PHP files found", #php_files))
			-- Show first 3 PHP files
			for i = 1, math.min(3, #php_files) do
				local relative_path = string.gsub(php_files[i], "^" .. cwd .. "/", "")
				table.insert(triggers, "    - " .. relative_path)
			end
			if #php_files > 3 then
				table.insert(triggers, string.format("    ... and %d more", #php_files - 3))
			end
		end

		if #triggers > 0 then
			for _, trigger in ipairs(triggers) do
				print(trigger)
			end
		end
	end

	-- Show active LSP clients
	print("\n🔧 Active LSP Servers:")
	local clients = vim.lsp.get_clients()
	if #clients == 0 then
		print("  None running")
	else
		for _, client in ipairs(clients) do
			print("  🟢 " .. client.name)
		end
	end
end, { desc = "Show detailed project detection information" })

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
					vim.keymap.set("n", "<C-t>", function()
						save_prev()
						api.node.open.tab()
					end, buf_opts("Open file in new tab"))
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

	-- Linting with selective loading based on project detection
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			-- Use the global detect_project_features function
			local project = _G.detect_project_features()

			-- Configure Typescript / Javascript linter
			if project.has_eslint then
				local eslint_d = require("lint.linters.eslint_d")
				-- Removed --no-warn-ignored as it's not supported by eslint_d
			end

			-- Configure PHP linter (PHPStan) with better configuration
			if project.has_php then
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
							-- PHPStan raw format: file.php:line:message
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
			end

			-- Configure Python linter
			if project.has_python then
				local mason_ruff = vim.fn.stdpath("data") .. "/mason/bin/ruff"
				if vim.fn.executable(mason_ruff) == 1 then
					lint.linters.ruff = lint.linters.ruff or {}
					lint.linters.ruff.cmd = mason_ruff
				end
			end

			-- Configure Go linter
			if project.has_go then
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
			end

			-- Set up linters by filetype based on detected project types
			local linters_by_ft = {}

			if project.has_eslint then
				linters_by_ft.javascript = { "eslint_d" }
				linters_by_ft.typescript = { "eslint_d" }
				linters_by_ft.javascriptreact = { "eslint_d" }
				linters_by_ft.typescriptreact = { "eslint_d" }
			end

			if project.has_go then
				linters_by_ft.go = { "golangcilint" }
			end

			if project.has_php then
				-- Use both PHP syntax checker and PHPStan
				linters_by_ft.php = { "php", "phpstan" }
			end

			if project.has_python then
				linters_by_ft.python = { "ruff" }
			end

			if project.has_terraform then
				linters_by_ft.terraform = { "tflint" }
				linters_by_ft.tf = { "tflint" }
			end

			-- Apply the configuration
			lint.linters_by_ft = linters_by_ft

			-- Setup autocommand to lint on save and insert leave
			vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "TextChanged" }, {
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
			local ok, err = pcall(function()
				local lspconfig = require("lspconfig")

				-- Shared on_attach function
				local function on_attach(_, bufnr)
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
						-- New API (Neovim 0.11+)
						vim.keymap.set("n", "[d", function()
							vim.diagnostic.jump({ count = -1 })
						end, bufopts)
						vim.keymap.set("n", "]d", function()
							vim.diagnostic.jump({ count = 1 })
						end, bufopts)
					end
					vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, bufopts)
				end

				local short_flags = { debounce_text_changes = 50 }
				local capabilities = require("cmp_nvim_lsp").default_capabilities()

				-- Use the global detect_project_features function
				local project = _G.detect_project_features()

				-- Track which LSPs we're starting
				local starting_lsps = {}

				-- Lua LSP
				if project.has_lua then
					table.insert(starting_lsps, "lua_ls")
					lspconfig.lua_ls.setup({
						on_attach = on_attach,
						flags = short_flags,
						capabilities = capabilities,
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
					})
				end

				-- TypeScript LSP
				if project.has_js_ts then
					table.insert(starting_lsps, "ts_ls")
					lspconfig.ts_ls.setup({
						on_attach = on_attach,
						flags = short_flags,
						capabilities = capabilities,
						settings = {
							typescript = {
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
						init_options = {
							maxTsServerMemory = 2048,
						},
					})
				end

				-- ESLint LSP
				if project.has_eslint then
					table.insert(starting_lsps, "eslint")
					lspconfig.eslint.setup({
						on_attach = on_attach,
						flags = short_flags,
						capabilities = capabilities,
						settings = {
							eslint = {
								enable = true,
								packageManager = "npm",
								autoFixOnSave = true,
								codeActionsOnSave = {
									mode = "all",
									rules = false,
								},
							},
						},
					})
				end

				-- Go LSP
				if project.has_go then
					table.insert(starting_lsps, "gopls")
					lspconfig.gopls.setup({
						on_attach = on_attach,
						flags = short_flags,
						capabilities = capabilities,
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
					})
				end

				-- Python LSP
				if project.has_python then
					table.insert(starting_lsps, "pyright")
					lspconfig.pyright.setup({
						on_attach = on_attach,
						flags = short_flags,
						capabilities = capabilities,
						before_init = function(_, config)
							config.settings = config.settings or {}
							config.settings.python = config.settings.python or {}
							-- Use the find_project_python function from your config
							config.settings.python.pythonPath = find_project_python()
						end,
						settings = {
							python = {
								analysis = {
									typeCheckingMode = "basic",
									autoSearchPaths = true,
									useLibraryCodeForTypes = true,
									diagnosticMode = "workspace",
									autoImportCompletions = true,
								},
							},
						},
					})
				end

				-- PHP LSP
				if project.has_php then
					lspconfig.phpactor.setup({
						on_attach = on_attach,
						flags = short_flags,
						capabilities = capabilities,
					})
				end

				-- SQL LSP
				if project.has_sql then
					table.insert(starting_lsps, "sqls")
					lspconfig.sqls.setup({
						on_attach = on_attach,
						flags = short_flags,
						capabilities = capabilities,
						settings = {
							sqls = {
								connections = {
									-- Add your database connections here if needed
								},
							},
						},
					})
				end

				-- Terraform LSP
				if project.has_terraform then
					table.insert(starting_lsps, "terraformls")
					lspconfig.terraformls.setup({
						on_attach = on_attach,
						flags = short_flags,
						capabilities = capabilities,
						filetypes = { "terraform", "tf", "hcl" },
						cmd = { "terraform-ls", "serve" },
					})
				end
			end)

			if not ok then
				print("❌ LSP Configuration Error: " .. tostring(err))
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
			-- GENERIC LSP DIAGNOSTIC COMMAND - Checking LSP issues in ANY language
			-- ============================================
			vim.api.nvim_create_user_command("LspDiagnostics", function()
				local bufnr = vim.api.nvim_get_current_buf()
				local clients = vim.lsp.get_clients({ bufnr = bufnr })

				print("=== LSP Diagnostics for Current Buffer ===\n")
				print("File: " .. vim.fn.expand("%:p"))
				print("Filetype: " .. vim.bo.filetype)
				print("")

				if #clients == 0 then
					print("❌ No LSP clients attached")
					print("\nPossible solutions:")
					print("  1. Check if LSP is installed: :Mason")
					print("  2. Check if project is detected: :LspStatus")
					print("  3. Try manual start: :LspStart")
					print("  4. Check logs: :LspLog")
					return
				end

				for _, client in ipairs(clients) do
					print("LSP: " .. client.name)
					print("  ID: " .. client.id)
					print("  Root: " .. (client.config.root_dir or "none"))

					-- Check capabilities
					if client.server_capabilities then
						local caps = client.server_capabilities
						print("  Capabilities:")

						-- Check common capabilities with proper nil handling
						local capability_checks = {
							{ "Go to Definition", caps and caps.definitionProvider },
							{ "Find References", caps and caps.referencesProvider },
							{ "Hover", caps and caps.hoverProvider },
							{ "Completion", caps and caps.completionProvider },
							{ "Rename", caps and caps.renameProvider },
							{ "Code Actions", caps and caps.codeActionProvider },
							{ "Formatting", caps and caps.documentFormattingProvider },
							{ "Diagnostics", caps and (caps.diagnosticProvider or true) },
						}

						for _, check in ipairs(capability_checks) do
							local name, capability = check[1], check[2]
							print(string.format("    %-20s %s", name .. ":", capability and "✅" or "❌"))
						end
					end
					print("")
				end

				-- Check for common project files that might be missing
				local project_checks = {
					php = {
						files = { "vendor/autoload.php", "composer.json" },
						install = "composer install",
					},
					javascript = {
						files = { "node_modules", "package.json" },
						install = "npm install",
					},
					typescript = {
						files = { "node_modules", "package.json", "tsconfig.json" },
						install = "npm install",
					},
					python = {
						files = { "requirements.txt", "pyproject.toml", "setup.py" },
						install = "pip install -r requirements.txt",
					},
					go = {
						files = { "go.mod", "go.sum" },
						install = "go mod download",
					},
				}

				local ft = vim.bo.filetype
				if project_checks[ft] then
					print("Project checks for " .. ft .. ":")
					local check = project_checks[ft]
					local missing = false

					for _, file in ipairs(check.files) do
						local path = vim.fn.getcwd() .. "/" .. file
						if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
							print("  ✅ " .. file)
						else
							print("  ⚠️  " .. file .. " (missing)")
							missing = true
						end
					end

					if missing and check.install then
						print("\n  Suggestion: Run '" .. check.install .. "'")
					end
				end
			end, { desc = "Show detailed LSP diagnostics for current buffer" })

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
