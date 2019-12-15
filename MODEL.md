# Model of tabulae.vim
An explanation of how `tabulae.vim` will work.

## Basic model
A user may open a `.tsv` file. User should export to a `.tae` file.
With this file, User should enter a command to bring up a view of the file.

A `worksheet.tae` file is a whitespace-delimited, Unix philosophy-friendly
stream of text, with each line representing a cell. e.g:

```tae
1 A < Item
1 B < Price
1 C < Count
1 D < Cost

2 A < cAVENDISH BANANAS
2 B = 0.39
2 C = 5
2 D = prod(2B:2C)

3 A < FROZEN PEAS
3 B = 3.49
3 C = 1
3 D = prod(3B:3C)

4 A < BARRYS BAKED BEANS
4 B = 1.99
4 C = 1
4 D = prod(4B:4C)

5 A < BARRYS BAKED BEANS
5 B = 1.99
5 C = 1
5 D = sum(2D:4D)
```


1. The `worksheet.tae` file is processed into a `.worksheet.tae.view` file. This
   view file will be the same file, but with all its values evaluated.
2. The `.worksheet.tae.view` file is used to create a Vim buffer which works
   like a spreadsheet.
