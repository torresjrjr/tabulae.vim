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

### 2019 December 18
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

### 2019 December 31 - New Years Eve
Roo! Completely new model. There are now more functions handling buffers, cells
and more. New first draft eval buffer processing functions now work!

![eval buffer - before processing](https://i.imgur.com/fIT5Z5j.png)  
_eval buffer - before processing_

![eval buffer - after processing](https://i.imgur.com/1nSBcjB.png)  
_eval buffer - after processing_

`.tae` files are now read into an intermediate _eval_ buffer, where cells with
metadata containing the equation/formula attribute are evaluated (recursively if
dependant on other un-evaluated cells).

Then, further proccesing is given to a _view_ buffer, which will correspond to
an individual spreadsheet (meaning multiple _view_ buffers are possible).
Functions will iterate over all cells, formatting them by there metadata. The
result is a simple, tab-delimited spreadsheet, formatted and with all evaluated
values.

These view buffers will have a special interface, with the cursor spanning a
cell, and motion and editing based on a spreadsheet design. `hjkl` will navigate
the view buffer spreadsheet by cells, and `i`, `c`, `d`, etc will edit cells.

In the future, I hope to create a popup-like _edit_ buffer, which will handle
single cells and their content. Such a buffer would handle editing easier, as
opposed to the only other method of editing the `.tae` file by hand. Content
once `ZZ`'ed could be preproccessed; for example, a multi-line string could have
it's newline chars converted to `\n` escape sequences in compliance to the
`.tae` format specification.

Otherwise, the default way to edit the spreadsheet will be to open up the `.tae`
file with the cursor at the corresponding cell. Of course, users would be forced
to also think about conforming to the format, and not messing the whole file up.

Much is left for imagination. I hope to continue this to it's minimum viable
end. Happy new year 🐦 🎉 !

### 2020 January 03
Flap! Cell references in cell data now work!

For now, specifically only Absolute Addresses (`A1`, `C23`, etc) are parsed, and
recursively evaluated. For example:

```tae
#= A1 + A2 + 5        The cell
#= 10 + A2 + 5        1st address is evaluated
#= 10 + 20 + 5        2nd address is evaluated
#  25                 Cell is evaluated
```

In the future, Relative Addresses (`{0,-2}`, `{19,23}`, etc) will be parsed and
converted to Absolute Addresses. For example: `{0,-2} => B3`.

In the future, Address Ranges (`A1:C1`, `B1:B100`, etc) will be parsed and
converted to a string of comma-separated Absolute Addresses. For example:
`A1:C1 => A1,B1,C1`.

Great progress.

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
