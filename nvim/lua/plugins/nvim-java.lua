return {
  "nvim-java/nvim-java",
  config = function()
    require("java").setup({
      jdtls = {
        on_attach = function(client, bufnr)
        end
      }
    })
    vim.lsp.enable("jdtls")
  end,
}
