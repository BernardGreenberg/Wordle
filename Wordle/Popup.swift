//
//  Popup.swift, born answerRevelator.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/12/23.
//

import Cocoa

private let FONT_SIZE = 20.0
private let CORNER_RADIUS = 15.0
private let Font = NSFontManager.shared.font(withFamily: "Arial", traits: .boldFontMask, weight: 0, size: FONT_SIZE)

private func makeCustomTextControl(frame: NSRect) -> NSTextField {
    let control = NSTextField(frame: frame)
    control.textColor = .black
    control.drawsBackground = false
    control.isSelectable = false
    control.font = Font
    control.alignment = .center
    control.isEditable = false

    return control
}

class PopupView: NSView {
    private var Text : NSTextField!
    public var isVisible : Bool {get {!self.isHidden}}
  
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    

    init(frame frameRect: NSRect, color: NSColor) {
        super.init(frame: frameRect)
        Text = makeCustomTextControl(frame:bounds)  //bounds, not frame!!
        self.wantsLayer = true
        self.layer?.backgroundColor = color.cgColor
        self.clipsToBounds = true
        self.layer?.cornerRadius = CORNER_RADIUS
        addSubview(Text)
        hide()
    }
    
    public func displayText(_ text: String) {
        Text.stringValue = text
        isHidden = false
    }
    
    public func hide() {
        isHidden = true
    }
}
