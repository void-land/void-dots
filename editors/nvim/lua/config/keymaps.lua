-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

keymap.set("n", "<C-l>", "V$", opts)

keymap.set("n", "<C-p>", ":Telescope find_files<CR>", opts)

keymap.set("n", "<C-CR>", "o<Esc>", opts)

keymap.set("n", "<C-S-CR>", "i", opts)
keymap.set("i", "<C-S-CR>", "<Esc>", opts)
