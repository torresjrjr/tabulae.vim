tabulae.vim
===========
📖 A Vim spreadsheet calculator plugin.

Written by [torresjrjr](https://t.me/torresjrjr).

![tabulae.vim first rudimentary view buffer.](https://i.imgur.com/xKUxkio.png)

This is an ongoing project over Christmas 2019. tabulae.vim aims to be a Vim plugin
which opens spreadsheet-like, tab-delimited `.tae` files and allows spreadsheet
previews with live calculations. Essentially, this plugin will turn Vim into an
Excel-like TUI program.

Outline
-------
See [MODEL.md](MODEL.md) for more comprehensive detail.

tabulae.vim will work with internally defined `.tae` files, which are
tab-delimited files with special syntax, and are worked as spreadsheets.

Progress
--------
- 2019 Dec 18:
  Milestone ⛰️ ! A rudimentary "view" buffer now works, with the `_EvalView()`
  function. The `_EvalCell()` function is capable of basic data handling.
  ```vim
  " ./examples/spreadsheet.tae
  :source plugin/tabulae.vim | call _InitView() | call _EvalView() 
  ```
  Todo:
  - Discover concealing characters for metadata markers in the viewbuffer.
  - Make `_EvalCell()` capable of evaluating equations/formulae.
  - Make a true `_SetCell()` function (unlikely needed, since side effects of
    setting multiple cells is desirable).
  - Improve in data type distinction, and standardise metadata sequences (likely
    will be similar to ANSI escape sequences).
  - Decide how to define a cell with leading whitespace.
  - Decide on local/buffer settings, like 'listchars', 'buftype', etc.
  - Consider efficiency improvements regarding `_itercellpos()` and minimising
    evaluations (consider the viewport, or a history of dependant cells or
    evaluated cells).
  - Make plugin work around `.tae` filetype buffers.
  - Consider how 'workbooks' would work (a spreadsheet on each tab, with methods
    to link data and navigate between one other, like `gf`). How would buffer
    and tab management work? How would a workbook file structure work?
  - Consider conditional or inherited formatting based on the metadata of a
    cell's column's header cell. This could save space by only writting metadata
    once per each column.

Contribute
----------
If you like the idea and want to contribute to this project, contact me at
[t.me/torresjrjr](https://t.me/torresjrjr).

Author's notes
-------------
I was inspired to make this plugin, because I was intrigued by _sc-im_, a
spreadsheet calculator with vim-like controls. However, I couldn't install and
try it out since I run _MSYS2_ on Windows, so I though I would make one myself.

### Reasons for tabulae.vim
- It's portable. Installs anywhere with Vim.
- Would use Vim-like controls natively.
- It's potentially useful for many cases.
- It's a nice challenge.
