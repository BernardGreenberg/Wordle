//
//  Popup.swift, born answerRevelator.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/12/23.
//

import Cocoa

private let Font = NSFontManager.shared.font(withFamily: "Arial", traits: .boldFontMask, weight: 0, size: 20.0)

private func makeCustomTextControl(frame: NSRect, bgColor: NSColor) -> NSTextField {
    let control = NSTextField(frame: frame)
    control.textColor = .black
    control.backgroundColor = bgColor
    control.drawsBackground = true
    control.isSelectable = false
    control.font = Font
    control.alignment = .center
    control.isEditable = false
    
    /* from web sources, SwiftUI suggestions, and luck.  */
    control.wantsLayer = true
    control.clipsToBounds = true
    control.layer?.cornerRadius = 15.0

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
        Text = makeCustomTextControl(frame:frameRect, bgColor:color)
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
