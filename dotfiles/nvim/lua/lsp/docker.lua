---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    filetypes = {
      filename = {
        ["docker-compose.yml"] = "yaml.docker-compose",
        ["*.docker-compose.yaml"] = "yaml.docker-compose",
        ["*.docker-compose.yml"] = "yaml.docker-compose",
      },
    },
  },
}
