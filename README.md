# Wordle
The popular Wordle game in Swift (Appkit/Cocoa)

Wordlists come from mysterious sources.  The set of possible answers is smaller (2300) than the set of possible guesses (6300),
Targeted to macOS 14.0.  Acts much like the NY Times one, although with enhanced cell acrobatics. 

It doesn't keep records or analyze the quality of your responses as the NYT one does.

I have not uploaded a built version.   The only advantage of mine over the NYT one is that it doesn't limit you to one game a day.

====

Usage:

Just type lower-case letters at it -- they get upper-cased as displayed. **Delete** erases the last entered.  You can only enter known English words, which are not evaluated until you hit **Return**, at which point you will either move on to the next entry line if it's a known word, or complaint if not; **Delete** works as usual at that time.

Once a line is "committed", so to speak, by being approved when **Return** is typed, you cannot go back.
If you guess the secret answer word, all 5 cells in the row will show green and jump for joy.  The game is then "Complete", which means you can't change anything or enter new letters.

You can, however, officially concede (admit defeat) by hitting the **Reveal** button or menu command (or Cmd-Opt-V), which will reveal the answer and mark the game "Complete"; you may not resume a given game once the answer is revealed.
At any time you can hit **New Game** (Cmd-N or the button), which starts again;  when in the "Complete" state, however, **Return** does that, too.

"Cmd-Opt-T" (also in the "View" menu) fills the array with the alphabet and a 4-letter Greek cryptogram (30=26+4) and demonstrates all the acrobatics. **New Game** can be used when bored with it.

Cmd-Q (or the red "close" dot or the menu command) can be used to quit.
