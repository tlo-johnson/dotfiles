return {
  "nvim-java/nvim-java",
  config = function()
    require("java").setup({
      jdk = {
        auto_install = false,
      },
      jdtls = {
        on_attach = function(client, bufnr)
        end
      }
    })
    vim.lsp.enable("jdtls")
  end,
}
