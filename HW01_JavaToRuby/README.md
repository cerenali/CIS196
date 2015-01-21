# HW 01: Java to Ruby Translation

For this homework, I translated the SpellChecker project (from the Java portion of CIS 120) from Java to Ruby. I refactored some of the methods, but the overall functionality was preserved: scanning an input file token by token (and distinguishing between word and non-word tokens), reading in a dictionary from a text file, spell-checking based on swapped-letter typos, and spell-checking based on a text file of common misspellings.

Although we didn't have to create the user interface for the CIS 120 project (it was given to us), I created it in Ruby so the program could be run from the command line.

## Challenges Encountered

I had a lot of difficulty at first with parsing the input file. In Java, we created a subclass of Scanner called TokenScanner, but I initially didn't see a corresponding Ruby class, so I wrote a method meant to stand in for the TokenScanner that created an array of words (excluding all punctuation/non-word characters) from an input file. This worked, but meant I was only writing the spell-checked words (not the punctuation) to the output file.

After some searching, I discovered Ruby's StringScanner, and used that to write a functional (and correct) TokenScanner.

It was also challenging in general to get out of the "Java frame of mind" (very for-loop-oriented) and adapt to the Ruby way of doing things. However, once I got used to them, methods such as arr.each and arr.each_with_index made the code a lot cleaner and more compact.

## Usage

`ruby spell_checker.rb <in> <out> <dictionary> <corrector>`

where `corrector` is either `SWAP` or the path to a corrections file.

### Example Usage

To use SwapCorrector with the included sample files:

`ruby spell_checker.rb Gettysburg.txt Gettysburg-out.txt dictionary.txt SWAP`

To use FileCorrector with the included sample files:

`ruby spell_checker.rb theFox.txt theFox-out.txt dictionary.txt theFoxMisspellings.txt`
