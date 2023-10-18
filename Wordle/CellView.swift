//
//  CellView.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/3/23.
//

import Cocoa

private let SELECTED_FRAME_COLOR = CGColor(red: 1.00, green: 1.00, blue: 0.00, alpha: 1)
private let NORMAL_FRAME_COLOR = CGColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1)
private let xCF = 1.0/255.0
private let CONTAINS_MATCH_COLOR = NSColor(red:177.0*xCF, green:159.0*xCF, blue:60.0*xCF, alpha: 1)
private let POSITION_MATCH_COLOR = NSColor(red:0*xCF, green:128.0*xCF, blue:0.0*xCF, alpha: 1)

private let BOX_INDENT = 3
private let CONTROL_INDENT = 5.0
private let FONT_SIZE = 40.0 // not worth recreating font from dimensions every time a cell is created.

enum CellState {
    case empty
    case selected
    case populated
    case contains_match
    case contains_and_place_match
}

private var stateColor : [CellState : NSColor] = [
    .empty : .black,
    .selected : .black,
    .populated : .black,
    .contains_match : CONTAINS_MATCH_COLOR,
    .contains_and_place_match : POSITION_MATCH_COLOR
]

final class CellView: NSView  {
    var Text: NSTextField!
    var State : CellState = .empty
    var Letter : String = ""

    static var Font = NSFontManager.shared.font(withFamily: "Arial", traits: .boldFontMask, weight: 0, size: FONT_SIZE)

    var letter: String { get {Letter} set(x) {self.setLetter(letter: x)}}
    var state : CellState {get {State} set (new_state) {self.setState(new_state:new_state)}}

    private func drawBox() {
        /* https://stackoverflow.com/questions/38079917/drawing-in-cocoa-swift */
        guard let context = NSGraphicsContext.current?.cgContext else{
            return
        }
        context.beginPath()
        context.setLineWidth(2.0)
        let (W, H, BI) = (Int(self.frame.width), Int(self.frame.height), BOX_INDENT)
        context.move(to:    CGPoint(x: BI,   y: BI))
        context.addLine(to: CGPoint(x: BI,   y: H-BI))
        context.addLine(to: CGPoint(x: W-BI, y: H-BI))
        context.addLine(to: CGPoint(x: W-BI, y: BI))
        context.addLine(to: CGPoint(x: BI,   y: BI))

        context.setStrokeColor(State == .selected ? SELECTED_FRAME_COLOR : NORMAL_FRAME_COLOR)
        context.strokePath()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawBox()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        Text = makeCustomTextControl()
        addSubview(Text)
    }

    private func makeCustomTextControl() -> NSTextField {
        var innerRect = self.frame
        innerRect.origin = CGPoint(x: CONTROL_INDENT, y: CONTROL_INDENT)
        innerRect.size.width -= 2*CONTROL_INDENT
        innerRect.size.height -= 2*CONTROL_INDENT
        let control = NSTextField(frame: innerRect)
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
        State = new_state
        Text.backgroundColor = stateColor[State]!
        if State == .empty || State == .selected {
            setLetter(letter:"")
        }
        setNeedsDisplay(frame)
    }

    /* API */
    
    /* used for animations */
    public func setTransform (_ xform : CGAffineTransform?) {
        /* Cocoa knows it needs to redisplay if we change these vars */
        guard xform != nil else {
            wantsLayer = false
            return
        }
        wantsLayer = true
        layer?.setAffineTransform(xform!)
    }
    
    public func jumpForJoy(delay: Int) {
        JumpForJoy(self).run(delay: delay)
    }
    
    public func somersaultForJoy(delay: Int) {
        SomersaultForJoy(self).run(delay: delay)
    }
    
    public func pirouetteForJoy(delay: Int) {
        PirouetteForJoy(self).run(delay: delay)
    }
    
    public func jiggleForDisappointment() {
        JiggleForDisappointment(self).run(delay: 0)
    }
}



