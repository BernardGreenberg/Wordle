#  Problems using NSAlert for "a simple alert box"

Saturday, 7 Oct 2023
This took me many hours to figure out.

The biggest problem is that the alert box's event handler, which hears Enter, is the default system handler, which is *behind* the application's, so (at very least), there is a conflict over Enter, which is a key gesture of the application, meaning "submitting this line as a tentative solution." But Enter is also the dismissal/complete gesture for the alert box.  In the usual "not a good word" case, it is Enter which triggered the alert box.

The basic bug that this created is that when the app's handler handled the Enter, the Mac dispatcher continued to pass it on to the aforementioned default system handler, immediately flushing the alert box in the very same interaction!.  The solution, of course, is that that pass-on is wrong:  The problem is that the app's event interceptor should not be declared
      keyDownHandler(event: NSEvent) -> NSEvent
    but
      keyDownHandler(event: NSEvent) -> NSEvent?
    and should return nil instead of the event when further processing is *not* required, which is, of course, for all recognized keystrokes. But, sadly, it is not a compilation error to submit an API of the former signature to NSEvent.addLocalMonitorForEvents.
    
    The second problem is that I want other keystrokes (than Enter) to dismiss the alert box.  And not only that, but Enter still has a problem.  It seems that when the latest Alert code from https://stackoverflow.com/questions/29433487/create-an-nsalert-with-swift runs, the call for "modal behavior" ***does not block***, which one would think to be the definition of "modal", but simply shows the window and handles the dismiss button by removing it and running a supplied handler.
    
    In order for any keys other than Enter directly received by it to affect the Alert box, the app has to receive them while the box is up.  That is not a problem, by virtue of the same "bug" described above -- the app gets the keystrokes before the box does.  It must know, in the case of receiving Enter, that the box is up, and it should be passed down rather than triggering a second box because of Enter received at the end of an input line! So a variable must be kept with a pointer to the NSAlert box instance, which would otherwise not be necessary -- the Enter handler must know whether or not the box is up.

    Secondly, I want Escape to have the same effect when the box is up (it has no meaning to the box, and none other to the app, but the app will trap it). In order for Escape to kill the box, it would be great if it could push the "OK" button, but it can't.  So it has to (1) close the window (2) stop the box's event loop, which is running in some thread somewhere, and (3) clear the point. It does all that with Alert.window.close() and NSApplication.shared.stopModal(), and kills the pointer itself.   "Enter" can now call this code subroutinally when it sees the box up.
    
    Finally, as langinappe, I want Delete(Rubout) not only to do the same, but not only to flush the box, but to do its normal app function of erasing the last character, whose attempted confirmation caused the alert to appear in the first place.  This is easy now, just call the Escape code subroutinally and continue.
    
    The box's button completion handler now does nothing more than clearing that pointer -- closing the window and the event loop are done by the native alert box implementation.
    
A related problem is how to run the alert box to complain about file-opening errors in the init method of the Wordle game app class.  Displaying it works well enough, as does pressing the button. What is supposed to happen after that creates problems. We would like to terminate the app, but NSApplication.shared.terminate() seems to no-op, at least in the context of something called from delegate appDidFinishLaunching. If there is a way to fail an app at that time, I haven't found it.  But since the app has applicationShouldTerminateAfterLastWindowClosed, closing the window of the (main) view supplied does the trick. However, you just can't do that after the "alert" call, because the alert's vaunted modality is fraudulent, and trying this kills the app the instant the alert box comes up, because the call returns instantly.  The answer was to code a supplyable funarg into the alert completion handler.  Although supplying the close method of the main window as a funarg worked well, didn't even need wrapping in {}, NSApplication.shared.terminate(self) works correctly in that context, and is better (wrapped in {() in NS...()} to make it a function.

Sunday, 8 October 2023

Much of the above understanding was completely wrong.   The underlying fault was that of the keyDownHandler falsely passing on events to the default handler, which, once fixed in the manner described in that paragraph above, fixes everything else the way it was originally, and many of the "improvements" made on the way there were not improvements at all, and could be (and now were) discarded.

I thought about the fact that NXSYS, in TLEdit in particular, runs modal dialogs left and right, having a very organized system for expressing them (from Windows-compatible code).  Although the Mac-specific parts of the app are in Objective-C, all Objective-C API's work in Swift.  It is using **NSWindow.runModalForWindow**, which the Swift compiler tells me has been renamed (in Swift, at least) to **runModal(forWindow:window)**.  NSAlert's **runModal** method was the original code.

The latest version of "truth" is this. This "observation", "latest Alert code from https://stackoverflow.com/questions/29433487/create-an-nsalert-with-swift runs, the call for "modal behavior" ***does not block***" is essential.  The recommended implicated API, the "beginSheetModal" method of NSAlert, **is not modal at all**, and implements the very definition of what Microsoft, at least, calls a "non-modal dialog", which is why it requires an asynchronous completion handler. The correct API, **NSAlert.runModal**, operates perfectly, and blocks until either the button is pressed or (luckily) NSApplication.shared.stopModal is called by something invoked in the midst of it, say by a callee of a keyDownHandler... I have routed the key handlers for Enter, Delete, and Escape to do that when the situation is right (i.e., an actual call to my alert function is active).

This all seems to work perfectly now, including (and I can't explain this) NSApplication.shared.terminate() functioning properly in the data-file-missing complaining code.

Thursday, 12 October 2023

The entire idea of using Alert boxes for anything short of reporting a fatal error after which no more interaction is possible is suspect.  It messes up the flow of user gestures.  The alert box has been relieved of all responsibilities except reporting fatal failure to open the input files (which is far less possible now, because they are app-tree-embedded resources, anyway).  The instance variable tracking the open state of the alert box is gone, too, as is any need for intercepted app gestures affecting the alert box for better or worse.

The alert box is also undesirable for expectable interaction feedback because it is positioned centered in the screen, not the app window.

The two former non-fatal uses of the alert box ("unknown word", "correct answer report") have been replaced by two normally-hidden (but created immediately) instances of a custom, very simple View (PopupViewx, subclass of NSView), positioned within the main view, to which they are "childed".  They have nice red and green backgrounds, and are stuffed with text and unhidden when needed.  The "unknown word" case is unhidden by either Delete(Rubout), to erase the losing 5th character, or "New Game" (any of the several gestures that now give this).  The "correct word report" is unhidden by either the explicit "reveal" gestures, or filling up 6 rows with valid but wrong words. It is hidden again by any of the "New game" gestures (or, of course, quitting the App).

There are no more multiple windows accepting gestures. End of all the above problems.  "Escape" is no longer meaningful, and has been removed from the dispatcher,
