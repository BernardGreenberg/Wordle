//
//  Popup.swift, born answerRevelator.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/12/23.
//

import Cocoa

private let Font = NSFontManager.shared.font(withFamily: "Arial", traits: .boldFontMask, weight: 0, size: 20.0)

private func makeCustomTextControl(frame: NSRect) -> NSTextField {
    let control = NSTextField(frame: frame) // adjusting the frame to position string better doesn't seem to work.
    control.textColor = .black
    control.drawsBackground = true
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
        Text = makeCustomTextControl(frame:frameRect)
        Text.backgroundColor = color
        addSubview(Text)
        isHidden = true
    }
    
    public func displayText(_ text: String) {
        Text.stringValue = text
        isHidden = false
    }
    
    public func hide() {
        isHidden = true
    }
}
