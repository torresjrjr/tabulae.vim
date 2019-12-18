Model of tabulae.vim
====================
An explanation of how tabulae.vim will work. This is currently ongoing and in
progress, so thoughts and opinions are welcome.

Overview
--------
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

tabulae.vim will take a `.tae` file and create a view buffer, where all the
cells are evaluated and formatted.

```tae.view
Item	Price	Count	Cost	
CAVENDISH BANANAS	0.39	5	1.95	
FROZEN PEAS	3.49	1	3.49	
BARRYS BAKED BEANS	1.99	1	1.99	
                 Total:		7	7.43	
```

This view buffer will be navigable with `hjlk` and hovered cells will be
highlighted. Edits are to be made to the `.tae` file, and tabulae.vim will
update the view buffer.

Evaluated `.tae` files should be convertable to other formats fairly easily,
such as `.tsv` and `.csv` files.

Editing the spreadsheet may happen in one or any of multiple ways:

1.  User hovers to a cell, and presses a command sequence (a single key) that
    switches them to the buffer of their `.tae` file, either in a new window or
    the same window. User edits the `.tae` file directly, and the plugin will
    automatically update the view buffer. Once the data is entered, the view buffer
    will be resumed (if it was gone).

2.  User hovers to a cell, and presses a command sequence (a single key) that
    switches them to a new, small window (`:botright 1new`), or a prompt. They
    are required to enter/edit either the contents of the whole cell (including
    metadata), or just the data (in which that case, the data type is inferred).

For now, The view will be tab-delimited, but in the future, tabulae.vim may have
the ability to draw view spreadsheets with variable whitespace, so as to be able
to have rows and coloums of varying widths and heights. I think that a
combination of _hidden_ \<TAB\> characters (by way of Vim highlighting) and
spaces (0x20) would be effective.

The `.tae` file format
----------------------
`.tae` files are similar to `.tsv` files. `.tae` files consist of rows delimited
by a NEWLINE, which consist of cells delimited by a TAB.

```
' Cell A1^I   ' Cell B1^I   ' Cell C1^I   
' Cell A2^I   ' Cell B2^I   ' Cell C2^I   
' Cell A3^I   ' Cell B3^I   ' Cell C3^I   
```

All cells, including cells last in a row, are marked by a subsequent
TAB character `^I` (0x09).

Cells contain an initial metadata string, a whitespace separator, and data, in
that order. For example, this cell has metadata `'`, a single space ` `, and
string data `Some data`, followed by a TAB character:

```
' Some data^I   
```

Data types
----------
`.tae` files observe certain data types, which allows for diverse data
manipulation.

Data is always a unicode text sequence of bytes. Datatypes are only
interpretations of what the data represents.

The basic data types are:
- String (Unicode sequence).
- Number
  - Integer (ASCII numerals)
  - Float (ASCII numerals, period)
- Boolean
- Datetime (ISO 8601).

### String 
A string data type is a unicode sequence of characters.
A string is denoted in metadata by the `'` character (0x27).

```tae
' A string of characters.^I
```

Strings cannot contain TAB characters. These are escaped with `\t`.

> The following was updated on 2019 Dec 18.

Strings cannot contain preceding or anticeding naked whitespace. Such whitespace
must be contained within an escaped pipe sequence `\|`. The pipe sequence itself
will be ignored, including within the string. However, there must be whitespace
between the metadata and the first pipe sequence.

```tae
'      A string with 0 preceding and 1 anteceding spaces \|^I	VALID
'\|    A string with 4 preceding and 2 anteceding spaces  \|     ^I	INVALID
'   \| A string with 1 preceding and 0 anteceding spaces     ^I	VALID
```

### Number
> In progress
A Number data type is a sequence of:
- ASCII numerals [0-9]
- A decimal point [.]
- Digit grouping characters [,\_] (thousand separators).
A Number is denoted in metadata by the '#' character (0x23).

```tae
#   #   #   #   #   #   #   #   #   #   #   #   #   #   #   #   
# 123^I             # 3.14^I            # 0.864^I           
# 1,000,000.00^I    # 1_234_567^I
```

### Boolean
> In progress
A Boolean data type is a single character of either a `1` (0x31) or `0` (0x30).
A Boolean is denoted in metadata by the `?` character (0x3F).

```
? 0^I  ? 1^I
```

### Datetime
> In progress
A Datetime data type is a sequence of characters in the ISO 8601 format of a
datatime.
A Datetime is denoted in metadata by the `D` character (0x44).

```
D 1999-12-25^I                  D 1999-12-25T12:30:45^I
D 1999-12-25T12:30:45+00:00^I   D 1999-12-25T12:30:45Z^I
```

Equations
---------
Cells in a `.tae` file can contains equations which are evaluated at the
view buffer.

Equations are marks in metadata by the `=` character (0x3D).
```tae
#= Sum(2D:4D)
?= Or(A1:E1)
'= Cat(F1:F10)
```
{##}

