# numerate
Command-line utility to process numbers in text files in various ways

Written in Swift for macOS.

Usage: `filename [-r] [-a] [-p] [-c] [-i N] [-d N] [-t N] [-e N] [-o outfilename] [-x regex]`

Options:

-r: arabic to Roman numerals

-a: roman to Arabic numerals

-c: convert text (if possible) to a number

-i: increment by following integer number (N)

-p: increment each line by 1

-d: decrement by following integer number (N)

-t: target only Nth instance in each line

-e: end transforms after Nth instance in file

-o: send output to following filename

-x: use the following regular expression

> must include capture group

> backslashes must be escaped eg `\\`

> straight quotation marks must be escaped eg `\"`

> eg `"<title>Chapter (\\d{1,3})</title>"`