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

Buffer structure
----------------
Here's an ASCII illustration of the buffer structure of an active session of
`tabulae` with a workbook.

```
                                                            
    .tae file            eval-buf              view-buf     
  +------------+      +------------+        +------------+  
  |%sheet 1    |      |%sheet 1    |        |Col   Col   |  
  |' Col ' Col | ---> |' Col ' Col | --+--> |1     1     |  
  |# 1   #= A2 |      |# 1   # 1   |   |    |2     2     |  
  |# 2   #= A3 |      |# 2   # 2   |   |    |3     3     |  
  |# 3   #= A4 |      |# 3   # 3   |   |    +------------+  
  |%sheet 2    |      |%sheet 2    |   |                    
  |' id  ' fn  |      |' id  ' fn  |   |       view-buf     
  |# 23  ' Ada |      |# 23  ' Ada |   |    +------------+  
  |# 86  ' Ben |      |# 86  ' Ben |   |    |id    fn    |  
  |# 9   ' Cin |      |# 9   ' Cin |   +--> |23    Ada   |  
  +------------+      +------------+   |    |86    Ben   |  
                                       |    |9     Cin   |  
                                       |    +------------+  
                                      etc.                  
                                       :                    
                                                            
```

This will be the general structure of viewing a `.tae` file. Edits are made
(directly or indirectly) to the tabulae file, and the view is updated
accordingly.

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

Cells cannot contain literal TAB characters within them. Tabs are to be
represented as `\t`.

Cells cannot contain literal BACKSLASH characters `\\` (0x5C) within them. Backslashes
are to be represented as `\\\\`

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
> In progress.

A Number data type is a sequence of:

- ASCII numerals `[0-9]`
- An optional single decimal point `.`

A Number is denoted in metadata by the '#' character (0x23).

```tae
# 123             # 3.14            # 0.618           # 123456789.00
```

### Boolean
> In progress.

A Boolean data type is a single character of either a `1` (0x31) or `0` (0x30).

A Boolean is denoted in metadata by the `?` character (0x3F).

```
? 1     ? 0
```

> Other potential representations may be recognised in a later revision, and
> include: `true`, `false`; `True`, `False`; `T`, `F`; `Yes`, `No`; `Y`, `N`;

### Datetime
> In progress.

A Datetime data type is a sequence of characters in the ISO 8601 format.

A Datetime is denoted in metadata by the `D` character (0x44).

```
D 1999-12-25                  D 1999-12-25T12:30:45
D 1999-12-25T12:30:45+00:00   D 1999-12-25T12:30:45Z
```

Equations
---------
Cells in a `.tae` file can contains equations which are evaluated at the
view buffer.

Equations are marks in metadata by the `=` character (0x3D).

```tae
#= avg(2D:4D)
?= not(or(A1,B1))
'= cat(F1:F10)
```

Coordinates and ranges
----------------------
A cell is refered to by its address - its row and its column number -
represented by an alphanumerical sequence:
```tae
[row][column]
A1      B46     Z3      AA1     AB23    ABC123
```

Cells are simply a position in a spreadsheet. Cells are not unique; they do not
have an ID.

> In the future, cells may have the capacity to have an ID.

Ranges are a shorthand for a sequence of cell addresses. When evaluated, they
exapand into a list of cell addresses.

```tae
A1:A4    =>    A1,A2,A3,A4
A1:C1    =>    A1,B1,C1
A1:C2    =>    A1,B1,C1,A2,B2,C2
```

When evaluated, addresses are sorted alphabetically, then numerically - by
column, then by row.

Metadata
-------- 
> In progress.

Metadata is the first part of a cell which encodes information about the cell.
It is always from the first character of a cell upto and excluding the first
whitespace character.

The syntax of a metadata string looks like this:

```tae
{type}[fmt-seq][=]
```

A 'datatype' char, an optional 'format sequence', and an optional `=`.

Examples:

```tae
'<bI			String, left_align, bold, not_italic.
'buhw16;		String, bold, header={width=16}.
#>d2;s3;=		Number, right_align, digits=2, sig_fig=3, equation.
#>d2;s3;=		Number, right_align, digits=2, sig_fig=3, equation.
?|c=			Boolean, centre, colour.
D				Datetime.
```

### List of metadata characters

- `!` 
- `"` 
- `#` - Denotes a Number type.
- `$` 
- `%` - Formats number as percentage.
- `'` 
- `(` 
- `)` 
- `*` 
- `+` 
- `,` 
- `-` 
- `.` 
- `/` 

- `:` 
- `;` 
- `<` - Formats as left align.
- `=` - Denotes an equation.
- `>` - Formats as right align.
- `?` - Denotes a Boolean type.
- `@` 
- `[` 
- `]` 
- `^` 
- `_` 
- `\x60` - Denotes an evaluated cell.
- `{` 
- `|` - Formats as centered.
- `}` 
- `~` 

