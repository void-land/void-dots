-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Function to extend opts with description
local function with_desc(desc)
  return vim.tbl_extend("force", opts, { desc = desc })
end

-- General keymaps
keymap.set("n", "<C-a>", "ggVG", with_desc("Select all"))
keymap.set("n", "<C-l>", "V$", with_desc("Select to end of line"))
keymap.set("n", "<C-p>", ":Telescope find_files<CR>", with_desc("Find files"))
keymap.set("n", "<C-CR>", "o<Esc>", with_desc("Insert new line below"))
keymap.set("n", "<C-S-CR>", "i", with_desc("Enter insert mode"))
keymap.set("i", "<C-S-CR>", "<Esc>", with_desc("Exit insert mode"))

-- Window Navigation
keymap.set("n", "<A-Left>", "<C-w>h", with_desc("Move to left window"))
keymap.set("n", "<A-Down>", "<C-w>j", with_desc("Move to window below"))
keymap.set("n", "<A-Up>", "<C-w>k", with_desc("Move to window above"))
keymap.set("n", "<A-Right>", "<C-w>l", with_desc("Move to right window"))

-- Undo and Redo
keymap.set({ "n", "i" }, "<C-z>", "u", with_desc("Undo"))
keymap.set("n", "<C-y>", "<C-r>", with_desc("Redo"))

-- Telescope
keymap.set("n", "<C-s-f>", ":Telescope live_grep<CR>", with_desc("Search in files"))

-- Copy and Paste
keymap.set("v", "<C-c>", "y", with_desc("Copy selected items"))
keymap.set("v", "<C-x>", "d", with_desc("Cut selected items"))

-- Move lines up and down
keymap.set("n", "<A-Up>", ":m .-2<CR>==", with_desc("Move line up"))
keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", with_desc("Move selection up"))
keymap.set("n", "<A-Down>", ":m .+1<CR>==", with_desc("Move line down"))
keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", with_desc("Move selection down"))

-- Buffer or edtior navigation
keymap.set("n", "<C-Tab>", ":bn<CR>", with_desc("Next buffer"))
keymap.set("n", "<C-S-Tab>", ":bp<CR>", with_desc("Previous tab"))
