# neov-ime.nvim

![Demo](./demo.mp4)
Neovim side implementation for Neovide's IME support.

> [!WARNING]
> This plugin only works with Neovide with IME support enabled.
> As of now, IME support is not available in stable releases of Neovide.
> You need to build Neovide from source on [this PR](https://github.com/fredizzimo/neovide/pull/2).

## Installation

Use your favorite plugin manager to install the plugin. For example, with `jetpack.vim`:

```vim
call jetpack#add('sevenc-nanashi/neov-ime.nvim')
```

## Highlighting

- `NeovImePreedit`（-> `Pmenu`）：The background for preedit text.
- `NeovImePreeditCursor`（-> `PmenuSel`）：The color for following 2 highlights:
- `NeovImePreeditCursorOnText`（-> `NeovImePreeditCursor`）： The part of preedit text under the cursor.
- `NeovImePreeditCursorTail`（-> `NeovImePreeditCursor`）：The cursor at the end of preedit text.

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
