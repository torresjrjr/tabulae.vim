Model of tabulae.vim
====================
An explanation of how tabulae.vim will work.

Basic model
-----------
tabulae.vim works with an internally defined, tab-delimited file format with the
extension `.tae`. Cells have metadata about data types, formatting, outline
type, etc. Normal `.tsv` and `.csv` files can be converted to `.tae` files, and
metadata will be inplicitliy or explicitely created. Here's an excerpt from
example.tae:

> Note: If you're viewing this in Vim, `:set tabstop=24` to view clearly.

```tae
'h Item	'h Price	'h Count	'h Cost	
' CAVENDISH BANANAS	# 0.39	# 5	#= prod(2B:2C)	
' FROZEN PEAS	# 3.49	# 1	#= prod(3B:3C)	
' BARRYS BAKED BEANS	# 1.99	# 1	#= prod(4B:4C)	
'> Total:		#= sum(2C:4C)	#= sum(2D:4D)	
```

tabulae.vim will take a `.tae` file and create a preview buffer, where all the
cells are evaluated.

```tae.view
Item	Price	Count	Cost	
CAVENDISH BANANAS	0.39	5	1.95	
FROZEN PEAS	3.49	1	3.49	
BARRYS BAKED BEANS	1.99	1	1.99	
                 Total:		7	7.43	
```

This preview buffer will be navigable with `hjlk` and hovered cells will be
highlighted. Edits to the `.tae` file will update the preview buffer.

Editing the spreadsheet may happen in one or any of multiple ways:

1.  User hovers to a cell, and presses a command sequence (a single key) that
    switches them to the buffer of their `.tae` file, either in a new window or
    the same window. User edits the `.tae` file directly, and the plugin will
    automatically update the preview buffer. Once the data is entered, the
    preview buffer will be resumed (if it was gone).

2.  User hovers to a cell, and presses a command sequence (a single key) that
    switches them to a new, small window (`:botright 1new`), or a prompt. They
    are required to enter/edit either the contents of the whole cell (including
    metadata), or just the data (in which that case, the data type is inferred).

For now, The preview will be tab-delimited, but in the future, tabulae.vim may
have the ability to draw preview spreadsheets with variable whitespace, so as to
be able to have rows and coloums of varying widths and heights. I think that a
combination of _hidden_ \<TAB\> characters (by way of Vim highlighting) and spaces
(0x20) would be effective.

The `.tae` file format
----------------------
`.tae` files are similar to `.tsv` files in that they contain rows and columns
of cells. All cells, including cells last in a row, are marked by a subsequent
\<TAB\> character (0x09).

Cells contain an initial metadata string, a whitespace separator, and data, in
that order. For example, this cell has metadata `'`, a single space ` `, and
data `Some data`, followed by a \<TAB\> character:

```
' Some data<TAB>
```

Data cannot contain \<TAB\> characters. These are marked with `\t`.

Data cannot contain preceding or anticeding naked whitespace. Such whitespace
must be escaped with a backslash, like `\ `, or with `\s`. Only the very first
and very last whitespace character needs to be escaped - the remaining
whitespace within those two  will be considered data. For example:

```tae
'    \  Data with 2 preceding and 2 anteceding spaces \     <TAB>
'    \s Data with 2 preceding and 2 anteceding spaces \s    <TAB>
```

