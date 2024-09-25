return {
  { import = "lazyvim.plugins.extras.ui.mini-starter" },

  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
  },

  -- Configure LazyVim to load theme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_dark_tritanopia",
    },
  },
}
