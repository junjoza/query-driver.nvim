# query-driver.nvim

Neovim plugin that automatically generates the `--query-driver` flag for clangd
based on your project's `compile_commands.json`. Designed for cross-compilation.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [When to Use This Plugin](#when-to-use-this-plugin)
- [How It Works](#how-it-works)
- [Customization](#customization)
- [Limitations](#limitations)

## Requirements

- Neovim >= 0.11.0
- clangd (with `--query-driver` support)
- Projects using `compile_commands.json`

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "junjoza/query-driver.nvim",
}
```

## Usage

Add to your clangd LSP configuration:

```lua
-- lsp/clangd.lua

local query_driver = require'query-driver'

return {
  cmd = { 'clangd', query_driver.get_query_driver_flag() },
  root_markers = { '.clangd', 'compile_commands.json' },
  filetypes = { 'c', 'cpp' },
}
```

## When to Use This Plugin

✅ Ideal for:

- Cross-compilation toolchains not in `$PATH`.

- Projects with toolchains in temporary/volatile locations

- Environments where compiler paths change between projects

- When clangd can't find your cross-compiler automatically

❌ Not recommended when:

- Toolchains are in standard system paths (`/usr/bin`, `/usr/local/bin`)

- Compilers are already in your `$PATH`.

- Using well-organized toolchains whican can be wildcard as:

```bash
# From
/opt/toolchains/<toolname-version>/usr/bin/<toolchain-name>/<toolchain-name>-*

# To
/opt/toolchains/*/usr/bin/*/aarch-poky-linux/aarch-poky-linux-*
```

- Working with single-architecture native projects

## How It Works

1. Searches for `compile_commands.json` in:

    - Current directory (`./compile_commands.json`)

    - Paths specified in `.clangd` file

    - Custom paths you provide

2. Extracts compiler path from build commands

3. Returns `--query-driver=PATH/prefix-*` flag if needed

## Customization

Pass custom search paths:

```lua
query_driver.get_query_driver_flag({
  './build/compile_commands.json',
  function() return vim.fn.getcwd() .. '/custom_path/commands.json' end
})
```

## Limitations

- Only checks first command in `compile_commands.json`.

- Requires absolute paths in compile commands.

- Designed for cross-compilation scenarios.

