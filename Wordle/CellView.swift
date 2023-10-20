//
//  CellView.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/3/23.
//

import Cocoa

private let SELECTED_OUTLINE_COLOR = NSColor(red: 1.00, green: 1.00, blue: 0.00, alpha: 1)
private let NORMAL_OUTLINE_COLOR = NSColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1)
private let FRAME_LINE_WIDTH = 2.0

private let xCF = 1.0/255.0
private let CONTAINS_MATCH_COLOR = NSColor(red:177.0*xCF, green:159.0*xCF, blue:60.0*xCF, alpha: 1)
private let POSITION_MATCH_COLOR = NSColor(red:0*xCF, green:128.0*xCF, blue:0.0*xCF, alpha: 1)

private let BOX_INSET = 3.0
private let CONTROL_INSET = 7.0
private let FONT_SIZE = 40.0 // not worth recreating font from dimensions every time a cell is created.

private let DOT_DIAMETER_FRACTION = 0.2
private let DOT_WALL_OFFSET = 0.1
private let DOT_PHASE_TIME = 0.5 //sec

enum CellState {
    case empty
    case selected
    case populated
    case indicating
    case contains_match
    case contains_and_place_match
}

private var stateColor : [CellState : NSColor] = [
    .empty : .black,
    .selected : .black,    /// ,selected implies no content, just like .empty
    .populated : .black,
    .indicating : .black,  // as in lever frame M "indication magnet", AS it were
    .contains_match : CONTAINS_MATCH_COLOR,
    .contains_and_place_match : POSITION_MATCH_COLOR
]

//Meaning of flashing: you must type "Enter" to try to commit this word.
//Need a whole NSView class -- "just draw the dot", as the box is drawn,
//doesn't work because the text field subview is drawn over it.
//A childed NSView competes "in the same league", as it were....
final class IndicatorDotView : NSView {
    var indicatorOn = false
    var theTimer : Timer?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if indicatorOn {
            NSColor.systemTeal.setFill()
            NSBezierPath(ovalIn: bounds).fill()
        }
    }
    public func start () {
        stop() // just in case
        indicatorOn = true
        theTimer = Timer.scheduledTimer(timeInterval: DOT_PHASE_TIME,
                                        target: self, selector: #selector(timerHandler),
                                        userInfo: nil, repeats: true)
        setNeedsDisplay(bounds)
    }
    public func stop () {
        if theTimer != nil {
            theTimer!.invalidate()
            theTimer = nil
        }
        indicatorOn = false
        setNeedsDisplay(bounds)
    }

    @objc private func timerHandler() {
        indicatorOn = !indicatorOn
        setNeedsDisplay(bounds)
    }
}

final class CellView: NSView  {
    var Text: NSTextField!
    var State : CellState = .empty
    var Letter : String = ""
    weak var Dot : IndicatorDotView?
    var outlineBox : NSRect!
    var outlineColor : NSColor = NORMAL_OUTLINE_COLOR

    static var Font = NSFontManager.shared.font(withFamily: "Arial", traits: .boldFontMask, weight: 0, size: FONT_SIZE)

    var letter: String { get {Letter} set(x) {self.setLetter(letter: x)}}
    var state : CellState {get {State} set (new_state) {self.setState(new_state:new_state)}}

    private func drawOutlineBox() {
        let path = NSBezierPath(rect: outlineBox)  //life can be so easy!
        path.lineWidth = FRAME_LINE_WIDTH
        outlineColor.set()
        path.stroke()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawOutlineBox()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        outlineBox = NSInsetRect(bounds, BOX_INSET, BOX_INSET)
        Text = makeCustomTextControl(frame:NSInsetRect(bounds, CONTROL_INSET, CONTROL_INSET))
        addSubview(Text)
    }
    
    private func makeCustomTextControl(frame: NSRect) -> NSTextField {
        let control = NSTextField(frame: frame)
        control.textColor = .white
        control.drawsBackground = true
        control.isSelectable = false
        control.font = Self.Font
        control.alignment = .center
        return control
    }
 
    private func setLetter(letter: String) {
        Letter = letter
        Text.stringValue = Letter.uppercased()
    }
    
    private func setState(new_state: CellState) {
        if State == .indicating {
            Dot!.stop()
        }
        State = new_state
        Text.backgroundColor = stateColor[State]!
        if State == .empty || State == .selected {
            setLetter(letter:"")
        }
        if State == .indicating {
            Dot!.start()
        }
        outlineColor = (State == .selected) ? SELECTED_OUTLINE_COLOR : NORMAL_OUTLINE_COLOR
        setNeedsDisplay(bounds)
    }
    

    /* API */
    
    public func endowWithIndicator() {
        let wallOffset = DOT_WALL_OFFSET*frame.width
        let diameter = DOT_DIAMETER_FRACTION*frame.width
        let box = NSMakeRect(frame.width - wallOffset - diameter, wallOffset, diameter, diameter)
        let dot = IndicatorDotView(frame: box)
        addSubview(dot) //don't set weak var until childed
        Dot = dot
    }
    
    /* used for animations */
    public func setTransform (_ transform : CGAffineTransform?) {
        /* Cocoa knows it needs to redisplay if we change these vars */
        guard transform != nil else {
            wantsLayer = false
            return
        }
        wantsLayer = true
        layer?.setAffineTransform(transform!)
    }
}
