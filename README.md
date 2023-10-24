# Wordle
The popular Wordle game in Swift (AppKit/Cocoa).

The word lists come from mysterious sources.  The set of possible answers is smaller (2300) than the set of possible guesses (6300).
Build (XCode) targeted to macOS 14.0.  It acts much like the NY Times one, although with enhanced cell acrobatics. 

It doesn't keep records or analyze the quality of your responses as the NYT one does. It doesn't have the QWERTY on-screen keyboard, which is mainly for phones, on which this does not run.

I have not uploaded a built version.   The only advantage of mine over the NYT one is that it doesn't limit you to one game a day, so you can build skill in this domain.

====

Usage:

Just type lower-case letters at it -- they get upper-cased as displayed. **Delete** erases the last one entered.  You can only enter known English words, which are not evaluated until you hit **Return**, at which point you will either move on to the next entry line if it's a known word, or get a complaint if not; **Delete** works as usual at that time.

Once a line is "committed", so to speak, by being approved when **Return** is typed, you cannot go back and alter it.
If you guess the secret answer word, all 5 cells in the row will show green and jump for joy (you get 6 tries).  The game is then "Complete", which means you can't change anything or enter new letters anywhere.

You can, however, officially concede (admit defeat) by hitting the **Reveal** button or menu command (or Cmd-Opt-V) at any time, which will reveal the answer and mark the game "Complete"; you may not resume a given game once the answer is revealed. At any time you can also hit **New Game** (Cmd-N or the button), which starts again;  when in the "Complete" state, **Return** does that, too.

Cmd-D ("Demo", also in the "View" menu) fills the array with the alphabet and a 4-letter Greek cryptogram (5⨉6=26+4) and demonstrates all the acrobatics. **New Game** can be used when bored with it.

Cmd-Q (or the red "close" dot or the menu command) can be used to quit.

Version 1.1, 18 October 2023

Unlike the NYT model, a teal "anxiety dot" begins flashing in the lower-right corner of the fifth letter of a word just entered, but not yet committed.  This is because there is no yellow "input selection" box in that state, and it looks "inactive".  Of course, you can **Delete** that or earlier characters, too. If, at attempted committal, the word is found to be "not a word", the dot remains.
