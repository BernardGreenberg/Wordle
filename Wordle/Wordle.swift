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
let ALPHABET30 = ALPHABET + "θφγδ"   //θεου φοβος γενει δαιμονια
let xCF = 1.0/256.0
let CONTAINS_MATCH_COLOR = NSColor(red:177.0*xCF, green:159.0*xCF, blue:60.0*xCF, alpha: 1)
let POSITION_MATCH_COLOR = NSColor(red:0*xCF, green:128.0*xCF, blue:0.0*xCF, alpha: 1)

let CELL_SIZE = 64

enum rowEval {case BOGUS, GOOD, COMPLETE}

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
    
    /* Cancel with button click or Enter, as Apple wants, no more char routing */
    private func alert(message: String, messageBody: String) {
        let alert = NSAlert()  // default options for everything are perfect.
        alert.messageText = message
        alert.informativeText = messageBody
        alert.runModal()
    }

    init (view: NSView) {
        /* Have to create before super.init() call*/

        Revelator = PopupView(frame: CGRect(origin:CGPoint(x:45, y: 50.0),
                                            size:CGSize(width:100, height:40)),
                              color: NSColor(red:0, green:0.85, blue:0, alpha: 1))
        BogonReporter = PopupView(frame: CGRect(origin:CGPoint(x:20, y:50), 
                                                size:CGSize(width:256, height:40)),
                                  color: .systemPink)

        super.init()
        
        /* Create the cells, position and adopt them, and save in array */
        createCells(view)
        
        if !readVocabularyFiles() {
            NSApplication.shared.terminate(self)
            return
        }

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
            Cells.append(Row)
        }
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

    private func createCellAtRowCol(row: Int, col:Int, view: NSView) -> CellView {
        let x = col*CELL_SIZE
        let y = Int(view.frame.height) - row*CELL_SIZE - CELL_SIZE // -CELL_SIZE is because we're positioning its bottom
        return CellView(frame: NSRect(origin:CGPoint(x: x, y: y), size:CGSize(width: CELL_SIZE, height:CELL_SIZE)))
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
            if cell.letter == "" {
                cell.isHidden = true
            }
        }
    }
    
    
    /* Was used during development, now a menu command in a theatre near you */
    public func testGraphics () {
        Revelator.hide()
        BogonReporter.hide()
        mapAllCells{(row, col, cell) in
            cell.letter = self.letterAt(ALPHABET30, row*NCOLUMNS + col)
            switch (col) {
            case 1:
                cell.background = CONTAINS_MATCH_COLOR
            case 2:
                cell.background = POSITION_MATCH_COLOR
            default:
                cell.background = .black
            }
            if (row == 4) {
                cell.somersaultForJoy(delay: 1)
            } else if (row == 1) {
                cell.pirouetteForJoy(delay: 1)
            }
            cell.isHidden = false
        }
        selectCell(nil)
        jumpRowForJoy(row: 2)
        curRow = 0
        curCol = 0
    }
    
    /* Handle input characters other than "rubout" and "Enter". See AppDelegate.swift */
    
    public func handleCharacter(input: String){          /* not Enter */

        if selectedCell == nil {
            return
        } // Covers all cases (e.g., test, end of row)
        
        // Otherwise, install new letter and move input pointer.
            
        if ALPHABET.contains(input) {
            selectedCell!.letter = input
            curCol += 1
            if (curCol < NCOLUMNS) {
                selectCellRC(curRow, curCol)
            } else { // end of row condition
                selectCell(nil)
            }
        }
    }
    
    public func handleEnter() {
        if curRowCommitted {
            if curRowWord() == Answer {
                newGame()
            }
            return
        }
        if selectedCell == nil && curCol == 0 && Cells[0][0].letter != "" { // allows it after Test, but not after newGame itself.
            newGame()
        } else if curCol == NCOLUMNS {
            processRowCompletion()
        }
        // else, ignore
    }

    public func handleRubout() {  //called by input receiver when Delete pressed
        if curCol == 0 || curRowCommitted {return}
        BogonReporter.isHidden = true
        
        //If not at beginning of line, back up and blank the cell.
        selectCellRC(curRow, curCol-1)
        selectedCell!.letter = ""
    }
    
    private func processRowCompletion() {
        // Extract the word lying in the current row...
        let rowCells = Cells[curRow]
        switch (EvaluateRow(rowCells: rowCells)) // Mark such oranges and greens as exist
        {
        case .COMPLETE:
            return
        case .BOGUS:
            BogonReporter.displayText("Unknown word: " + curRowWord())
            jiggleRowForDisappointment(row: curRow)
        case .GOOD: do {
            if curRow < LAST_ROW {
                selectCellRC(curRow + 1, 0)
            } else {
                curRowCommitted = true
                selectCell(nil)
                reveal()
            }
        }
        }
    }

    private func declareVictory() {
        hideEmptyCells()
        selectCell(nil)
        jumpRowForJoy(row: curRow)
        curRowCommitted = true
    }
    
    private func curRowWord() -> String {
        return Cells[curRow].map(\.letter).joined()
    }

    /* Decide how to color current row based on agreement with Answer */
    private func EvaluateRow(rowCells: [CellView]) -> rowEval {
        if !Possibles.contains(word: curRowWord()) {
            return .BOGUS
        }
        
        var already_told: Set<String> = [] /*trick to prevent multiple assessments of same letter, Nanny! */
        
        /* Color such greens as should be */
        for (cell, ansChar) in zip(rowCells, Answer) {
            if Character(cell.letter) == ansChar {
                already_told.insert(cell.letter)
                cell.background = POSITION_MATCH_COLOR
            }
        }
        
        // See if game won; if so, no need to check for oranges.
        if rowCells.filter({$0.background == POSITION_MATCH_COLOR }).count == NCOLUMNS {
            declareVictory()
            return .COMPLETE
        }
        
        // Color such oranges as needed
        for cell in rowCells {
            if Answer.contains(cell.letter) && !already_told.contains(cell.letter) {
                already_told.insert(cell.letter)
                cell.background = CONTAINS_MATCH_COLOR
            }
        }
        
        /* make correct ones somersault for joy */
        for (j, cell) in zip(0...LAST_ROW, rowCells) {
            if cell.background == POSITION_MATCH_COLOR {
                cell.somersaultForJoy(delay: j)
            } else if cell.background == CONTAINS_MATCH_COLOR {
                cell.pirouetteForJoy(delay: j)
            }
        }
        return .GOOD
    }
    
    public func reveal() {
        hideEmptyCells()
        selectCell(nil)
        BogonReporter.hide()
        Revelator.displayText(Answer)
    }
     
    /* Initialize/reinitialize the game and the grid */
    public func newGame() {
        BogonReporter.hide()
        Revelator.hide()
        Answer = Answers.chooseRandom()
        mapAllCells {(_, _, cell) in
            cell.letter = ""
            cell.background = .black
            cell.isHidden = false
        }
        selectCellRC(0, 0)
    }
    
    private func selectCellRC(_ row: Int, _ col: Int) {
        (curRow, curCol) = (row, col)
        selectCell(Cells[row][col])
        if col == 0 {
            curRowCommitted = false
        }
    }
    
    private func selectCell(_ cell: CellView?) {
        if selectedCell != nil {
            selectedCell!.isSelected = false
            selectedCell = nil
        }
        if (cell != nil) {
            selectedCell = cell!
            cell!.isSelected = true
        }
    }
    
    private func jumpRowForJoy(row: Int) {
        for (cell, i) in zip(Cells[row], 0...LAST_COLUMN) {
            cell.jumpForJoy(delay: i)
        }
    }
    
    private func jiggleRowForDisappointment(row: Int) {
        for cell in Cells[row] {
            cell.jiggleForDisappointment()
        }
    }
}
