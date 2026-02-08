# neov-ime.nvim

https://github.com/user-attachments/assets/e9fa8a06-6b5f-4edc-9c6b-b68ac7a66c63

Neovim side implementation for Neovide's IME support.

> [!WARNING]
> This plugin only works with Neovide with IME support enabled.
> As of now, IME support is not available in stable releases of Neovide.
> You need [Nightly Neovide](https://github.com/neovide/neovide/releases/tag/nightly) latter than commit `91f8b8d` (2026/02/05).

## Installation

Use your favorite plugin manager to install the plugin. For example, with `jetpack.vim`:

```vim
call jetpack#add('sevenc-nanashi/neov-ime.nvim')
```

## Highlighting

- `NeovImePreedit` (-> `Pmenu`): The background for preedit text.
- `NeovImePreeditCursor` (-> `PmenuSel`): The color for following 2 highlights:
- `NeovImePreeditCursorOnText` (-> `NeovImePreeditCursor`): The part of preedit text under the cursor.
- `NeovImePreeditCursorTail` (-> `NeovImePreeditCursor`): The cursor at the end of preedit text.

## Configuration

### Version Check

The plugin checks if your Neovim version meets the minimum requirement (0.12.0-dev-1724 or later) and displays a warning if it's too old.
You can suppress this warning by setting the global variable `g:neovime_no_version_warning` to a truthy value before loading the plugin:

```vim
let g:neovime_no_version_warning = 1
```

Or in Lua:

```lua
vim.g.neovime_no_version_warning = true
```

### Manual Setup

You can prevent the plugin from installing IME handlers automatically by setting the global variable `g:neovime_manual_setup` to a truthy value before loading the plugin.
In that case, you need to call the setup function manually:

```lua
require('neov-ime').setup()
```

Or more verbosely:

```lua
local neovime = require('neov-ime')
neovide.preedit_handler = neovime.preedit_handler
neovide.commit_handler = neovime.commit_handler
```

## Troubleshooting

If you're getting this message:

```
[neov-ime] `g:neovide` was set, but Neovide API is still not available. Aborting IME handler installation. Check :h neovime-troubleshooting for details.
```

It means that the plugin couldn't access Neovide's API even though `g:neovide` was set.
I believe this will not happen in normal situations, but if it does, you can try increasing the timeout duration by setting the global variable `g:neovime_install_timeout` (in seconds) before loading the plugin.
The default value is `10` seconds.
Or, you can disable the automatic installation of IME handlers by setting `g:neovime_manual_setup` to a truthy value, and call the setup function manually when you're sure that Neovide's API is available.

## Acknowledgements

This plugin is based on [kanium3/neovide-ime.nvim](https://github.com/kanium3/neovide-ime.nvim), and the IME support in Neovide is made by [@kanium3](https://github.com/kanium3) and Neovide contributors.

This is the license for the original work:

```
MIT License

Copyright (c) 2025 kanium3

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or se
ll copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILIT
Y, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## License

This plugin is licensed under the MIT License. See the `LICENSE` file for details.
