# diagmininotify.nvim (post-to-MiniNotify fork)

Fork of [diagflow.nvim](https://github.com/dgagn/diagflow.nvim).

Display LSP notifications via [mini.notify](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-notify.md)
rather than inline in the code.


## Example

1. Opening a file with multiple diagnostics but no issues under the cursor:



2. An error under the cursor:



3. A hint under the cursor:



## Installation

To install **diagmininotify.nvim**, use your preferred Neovim package manager. If you're using `packer.nvim`, add the following line to your plugin list:

```lua
-- Packer
use {'danthedeckie/diagmininotify.nvim'}
```

If you're using `lazy.nvim`, add the following line to your plugin list:

```lua
-- Lazy
{
    'danthedeckie/diagmininotify.nvim',
    -- event = 'LspAttach', This is what I use personnally and it works great
    opts = {

        }
}
```

## Configuration

**Note** if you are using the `opts` with `lazy.nvim`, you don't need to run the setup, it does it for you.

The scope option determines the context of diagnostics display: 'cursor' (default) shows diagnostics only under the cursor, while 'line' shows diagnostics for the entire line where the cursor is positioned.

```lua
require('diagmininotify').setup({
    enable = true,
    format = function(diagnostic)
      return diagnostic.message
    end,
    scope = 'cursor', -- 'cursor', 'line' this changes the scope, so instead of showing errors under the cursor, it shows errors on the entire line.
    update_event = { 'DiagnosticChanged', 'BufReadPost' }, -- the event that updates the diagnostics cache
    toggle_event = { }, -- if InsertEnter, can toggle the diagnostics on inserts
    show_sign = false, -- set to true if you want to render the diagnostic sign before the diagnostic message
    render_event = { 'DiagnosticChanged', 'CursorMoved' },
})
```

Or simply use the default configuration:

```lua
require('diagmininotify').setup()
```

## FAQ


### How can I disable the cursor when I enter insert mode and reenable it when I go in normal mode?

```lua
{
  'dgagn/diagmininotify.nvim',
  opts = {
    toggle_event = { 'InsertEnter' },
  },
}
```

### Something doesn't update when X or Y happens.

You can setup when the diagnostic is cached with this option :

```lua
{
  'dgagn/diagmininotify.nvim',
  opts = {
    update_event = { 'DiagnosticChanged', ... },
  },
}
```

### I want to customize my diagnostic messages

You can set a diagnostic message by supplying the `format` option.

```lua
{
  'dgagn/diagmininotify.nvim',
  opts = {
    format = function(diagnostic)
      return '[LSP] ' .. diagnostic.message
    end
  },
}
```

### How do I disable this for certain filetypes?

```lua
{
  'dgagn/diagmininotify.nvim',
  opts = {
    enable = function()
      return vim.bo.filetype ~= "lazy"
    end,
  },
}
```
