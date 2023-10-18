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
    .selected : .black,
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
            //https://stackoverflow.com/questions/49085717/drawing-a-circle-in-swift-macos
            let context = NSGraphicsContext.current!.cgContext
            context.setFillColor(NSColor.systemTeal.cgColor)
            let innerFrame = NSRect(origin:NSPoint.zero, size:frame.size)
            context.fillEllipse(in: innerFrame)
        }
    }
    public func start () {
        indicatorOn = true
        theTimer = Timer.scheduledTimer(timeInterval: DOT_PHASE_TIME,
                                        target: self, selector: #selector(timerHandler),
                                        userInfo: nil, repeats: true)
        setNeedsDisplay(frame)
    }
    public func stop () {
        if theTimer != nil {
            theTimer!.invalidate()
            theTimer = nil
        }
        indicatorOn = false
        setNeedsDisplay(frame)
    }

    @objc private func timerHandler() {
        indicatorOn = !indicatorOn
        setNeedsDisplay(frame)
    }
}

final class CellView: NSView  {
    var Text: NSTextField!
    var State : CellState = .empty
    var Letter : String = ""
    weak var Dot : IndicatorDotView?

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
    
    private func installDot() {
        let diameter = DOT_DIAMETER_FRACTION*frame.width
        let wall_offset = DOT_WALL_OFFSET*frame.width
        let box = NSRect(origin: NSPoint(x: frame.width-wall_offset-diameter,
                                          y: 0+wall_offset),
                          size: NSSize(width:diameter, height:diameter))
        let dot = IndicatorDotView(frame: box)
        addSubview(dot) //don't set weak var until childed
        Dot = dot
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
        if State == .indicating {
            Dot!.stop()
        }
        State = new_state
        Text.backgroundColor = stateColor[State]!
        if State == .empty || State == .selected {
            setLetter(letter:"")
        }
        if State == .indicating {
            startIndicating()
        }
        setNeedsDisplay(frame)
    }
    
    private func startIndicating() {
        if Dot == nil {
            installDot()
        } else {
            Dot!.stop() // shouldn't really happen.
        }
        Dot!.start()
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



