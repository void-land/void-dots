return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v2.x",
  config = function()
    require("neo-tree").setup({
      window = {
        width = 30,
      },
    })
  end,
}