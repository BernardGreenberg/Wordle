//
//  AppDelegate.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/3/23.
//

import Cocoa
import Carbon.HIToolbox

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var theWordle : Wordle!
    @IBOutlet var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //Initialize the application
        theWordle = Wordle(view: window.contentView!)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler:keyDownHandler)

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
    
    @IBAction func newGame(event: Any) {
        theWordle.newGame()
    }
    
    @IBAction func reveal(event: Any) {
        theWordle.revealAnswer()
    }
    
    @IBAction func testGraphics(event: Any) {
        theWordle.testGraphics()
    }
     
    func keyDownHandler(event: NSEvent) -> NSEvent? {
        /* Any ctrl/opt/cmd modified characters pass through to default responder.
           That includes generic (e.g., cmd-Q) and menu-defined (cmd-N, "new game") gestures. */

        let cmdflags = NSEvent.modifierFlags.union(.command).union(.option).union(.control)
        if (!event.modifierFlags.intersection(cmdflags).isEmpty) {
            return event
        }

        if event.keyCode == kVK_Delete {
            theWordle.handleRubout()
        }
        else if event.keyCode == kVK_Return {
            theWordle.handleEnter()
        }
        else if event.charactersIgnoringModifiers != "" {
            // regular characters, not \r or Delete
            theWordle.handleCharacter(input: event.charactersIgnoringModifiers!)
        }

        return nil // DO NOT PASS ON!
    }
    
}

