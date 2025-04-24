---@type LazySpec
return {
  {
    "lucidph3nx/nvim-sops",
    event = { 'BufEnter' },
  },
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        n = {
          ["<Leader>be"] = {
            "<Cmd>SopsEncrypt<CR>",
            desc = "Encrypt sops file"
          },
          ["<Leader>bd"] = {
            "<Cmd>SopsDecrypt<CR>",
            desc = "Decrypt sops file"
          },
        },
      }
    }
  },
}
