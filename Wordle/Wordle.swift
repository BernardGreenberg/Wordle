//
//  Wordle.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/4/23.
//

import Cocoa  // (older) Mac UI system, available in Objective-C/++, too..

/* 0-based indexing on both now, makes 2d array easier */
let NROWS = 6
let NCOLUMNS = 5
let LAST_ROW = 5
let LAST_COLUMN = NCOLUMNS-1
let ALPHABET = "abcdefghijklmnopqrstuvwxyz"
let ALPHABET30 = ALPHABET + "θφγδ"   //θεου φοβος γενει δαιμονας

let CELL_SIZE = 64

class Wordle: NSObject {
    var Cells : [[CellView]] = []  //"two dimensional array" of cells [row][col]
    var Revelator : PopupView
    var BogonReporter : PopupView
    
    /* Databases from files. 2315 answers, but 6409 "possible"s */
    var Answers: Database!
    var Possibles: Database!
    
    /* State Vars for this game */
    var curRow: Int = 0, curCol: Int = 0
    var Answer = "     "
    var selectedCell : CellView? = nil
    var curRowCommitted = false
    var testUp = false
    
    /* Cancel with button click or Enter, as Apple wants, no more char routing */
    private func alert(message: String, messageBody: String) {
        let alert = NSAlert()  // default options for everything are perfect.
        alert.messageText = message
        alert.informativeText = messageBody
        alert.runModal()
    }

    init (view: NSView) {
        
        /* Have to create these before super.init() call, or Swift will force them to be Optional.  */
        let dsz = Double(CELL_SIZE)
        func createPopup(width : Double, x: Double, color: NSColor) -> PopupView {
            let popupH = 0.5 * dsz
            let popupY = view.frame.height - dsz * 4.8 - popupH
            return PopupView(frame: NSRect(origin: NSPoint(x: x, y: popupY),
                                           size: NSSize(width: width, height:popupH)),
                             color: color)
        }

        Revelator = createPopup(width: 100, x: 1.7*dsz, color: NSColor.systemGreen)
        BogonReporter = createPopup(width: 256.0, x: 30, color: NSColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1))

        super.init()
        
        if !readVocabularyFiles() {
            NSApplication.shared.terminate(self)
            return
        }

        /* Create the cells, position and adopt them, and save in array */
        createCells(view)
        
        /* Now adopt the info popups */
        view.addSubview(Revelator)
        view.addSubview(BogonReporter)
      
        /* Play the first game ... */
        
        newGame()
    }
    
    /* Create cells, install them in the "Cells" array, and adopt them into the view provided */
    private func createCells(_ view: NSView) {
        for row in 0...LAST_ROW {
            var Row : [CellView] = []
            for col in 0...LAST_COLUMN {
                let cell = createCellAtRowCol(row:row, col:col, view: view)
                Row.append(cell)
                view.addSubview(cell)
            }
            Row.last?.endowWithIndicator()
            Cells.append(Row)
        }
    }

    private func createCellAtRowCol(row: Int, col:Int, view: NSView) -> CellView {
        let x = col*CELL_SIZE
        let y = Int(view.frame.height) - row*CELL_SIZE - CELL_SIZE // -CELL_SIZE is because we're positioning its bottom
        return CellView(frame: NSRect(origin:NSPoint(x: x, y: y), size:NSSize(width: CELL_SIZE, height:CELL_SIZE)))
    }
    
    private func readVocabularyFiles() ->Bool {
        /* Get vocabulary data from resource files */
        do {
            Answers = try Database(resourceName: "Answers.txt")       //words that can be used as answers
            Possibles = try Database(resourceName: "Possibles.csv")   //words that can be used as guesses (many more)
        }
        catch MyError.runtimeError(let errorMessage) {
            self.alert(message: "Database Open error", messageBody: errorMessage)
            return false
        } catch { /* need this or throwers above will not compile, as error processing not "comprehensive" ... */
            self.alert(message: "Database open random error", messageBody: error.localizedDescription)
            return false
        }
        Possibles.merge(Answers) //there are about 50 words in Answers not in Possibles, mainly modernisms
        return true
    }
    
    /* string[3] as in Python, C, Java, etc. doesn't work in Swift. This bullshit is necessary. */
    private func letterAt(_ s: String, _ pos0rel: Int) -> String {
        let r = s.index(s.startIndex, offsetBy: pos0rel)..<s.index(s.startIndex, offsetBy: pos0rel+1)
        return String(s[r])
    }
    
    private func mapAllCells( funarg: @escaping (_ row: Int, _ col:Int, _ cell:CellView)->Void) {
        for row in 0...LAST_ROW {
            for col in 0...LAST_COLUMN {
                funarg(row, col, Cells[row][col])  //remembering Joe Weizenbaum
            }
        }
    }
    
    private func hideEmptyCells() {
        mapAllCells{(_, _, cell) in
            if cell.state == .empty {
                cell.isHidden = true
            }
        }
    }
    
    
    /* Was used during development, now a menu command in a theatre near you */
    public func testGraphics () {
        Revelator.hide()
        BogonReporter.hide()
        closeSelectedCell()
        mapAllCells{(row, col, cell) in
            cell.letter = self.letterAt(ALPHABET30, row*NCOLUMNS + col)
            switch (col) {
            case 1:
                cell.state = .contains_match
            case 2:
                cell.state = .contains_and_place_match
            default:
                cell.state = .populated
            }
            if (row == 4) {
                SomersaultForJoy(cell).run(delay: 1)
            } else if (row == 1) {
                PirouetteForJoy(cell).run(delay: 1)
            }
            cell.isHidden = false
        }
        jumpRowForJoy(row: 2)
        jiggleRowForDisappointment(row: 5)
        testUp = true
    }
    
    /* Handle input characters other than "rubout" and "Enter". See AppDelegate.swift */
    
    public func handleCharacter(input: String){          /* not Enter */

        if selectedCell == nil || testUp {
            return
        }
        
        // Otherwise, install new letter and move input pointer.
            
        if ALPHABET.contains(input) {
            selectedCell!.letter = input
            selectedCell!.state = .populated
            selectedCell = nil
            curCol += 1
            if (curCol < NCOLUMNS) {
                selectCell(curRow, curCol)
            } else {
                Cells[curRow][LAST_COLUMN].state = .indicating
            }
            //else, leave no cell selected.
        }
    }
    
    public func handleEnter() {
        /* This is a pretty complex overloaded gesture, Enter/Return ...  */
        if testUp || Revelator.isVisible {
            newGame()
        }
        else if curRowCommitted {
            if curRowWord() == Answer || curRow == LAST_ROW {
                newGame()
            }
        }
        else if curCol == NCOLUMNS {
            processRowCompletion()
        }
        // else, ignore
    }

    public func handleRubout() {  //called by input receiver when Delete pressed
        if curCol == 0 || curRowCommitted || Revelator.isVisible || testUp {return}
        BogonReporter.hide()
        selectCell(curRow, curCol-1)
    }
    
    private func processRowCompletion() {   //first-time Enter in last column
        let guess = curRowWord()
        if !Possibles.contains(word: guess) {               //Not a known word.
            BogonReporter.displayText("Unknown word: " + guess)
            jiggleRowForDisappointment(row: curRow)
            return
        }

        curRowCommitted = true  //"Commitment" means reaching this point -- prevents Enter from being hit twice
        Cells[curRow][LAST_COLUMN].state = .populated //turn off .indicating. No cells colored yet in this row.
        colorColorableCells()   //Do the colorings and animations.

        /* Evaluate and act on new game state. */
        if guess == Answer {                                // Victory!
            hideEmptyCells()
            jumpRowForJoy(row: curRow)
        } else  if curRow == LAST_ROW {                     // 6th-row defeat, reveal the answer
            revealAnswer()
        } else {                                            // Otherwise, enable the next guess
            selectCell(curRow + 1, 0)
        }
    }

    private func curRowWord() -> String {
        return Cells[curRow].map(\.letter).joined()
    }

    /* Color and animate current row based on agreement with Answer */
    private func colorColorableCells() {
        var already_told: Set<String> = [] /*trick to prevent multiple assessments of same letter, Nanny! */
        // Must do this in 2 passes, or oranges will appear with green later on for the same letter.
        for ((cell, ansChar), j) in zip(zip(Cells[curRow], Answer), 0...LAST_ROW) {  // no zip for > 2 args
            if Character(cell.letter) == ansChar {
                already_told.insert(cell.letter)
                cell.state = .contains_and_place_match
                PirouetteForJoy(cell).run(delay: j)
            }
        }
        for (cell, j) in zip (Cells[curRow], 0...LAST_ROW) {
            if Answer.contains(cell.letter) && !already_told.contains(cell.letter) {
                already_told.insert(cell.letter)
                cell.state = .contains_match
            }
            if cell.state != .contains_and_place_match {
                SomersaultForJoy(cell).run(delay: j)  //NYT-compatible behavior for inactive letters
            }
        }
    }
    
    public func revealAnswer() {
        closeSelectedCell()
        hideEmptyCells()
        BogonReporter.hide()
        Revelator.displayText(Answer)
    }
     
    /* Initialize/reinitialize the game and the grid */
    public func newGame() {
        BogonReporter.hide()
        Revelator.hide()
        Answer = Answers.chooseRandom()
        mapAllCells {(_, _, cell) in
            cell.state = .empty
            cell.isHidden = false
        }
        selectCell(0, 0)
    }
    
    private func selectCell(_ row: Int, _ col: Int) {
        (curRow, curCol) = (row, col)
        testUp = false
        curRowCommitted = false
        closeSelectedCell()
        let cell = Cells[row][col]
        selectedCell = cell
        cell.state = .selected
    }
    
    private func closeSelectedCell() {
        if selectedCell != nil {
            selectedCell!.state = .empty
            selectedCell = nil
        }
    }
    
    private func jumpRowForJoy(row: Int) {
        for (cell, i) in zip(Cells[row], 0...LAST_COLUMN) {
            JumpForJoy(cell).run(delay: i)
        }
    }
    
    private func jiggleRowForDisappointment(row: Int) {
        for cell in Cells[row] {
            JiggleForDisappointment(cell).run(delay: 0)
        }
    }
}
