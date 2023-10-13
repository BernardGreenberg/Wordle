//
//  Popup.swift, born answerRevelator.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/12/23.
//

import Cocoa

private let Font = NSFontManager.shared.font(withFamily: "Arial", traits: .boldFontMask, weight: 0, size: 20.0)

private func makeCustomTextControl(frame: NSRect) -> NSTextField {
    let frammis = CGRect(origin:CGPoint(x: frame.origin.x, y: frame.origin.y - 10.0), size:frame.size)
    let control = NSTextField(frame: frammis)
    control.textColor = .black
    control.drawsBackground = true
    control.isSelectable = false
    control.font = Font
    control.alignment = .center
    control.isEditable = false
    return control
}

class PopupView: NSView {
    var Text : NSTextField? = nil
    var Color: NSColor = .white
  
    public func setText(text: String) {
        Text!.stringValue = text
    }
 
    required init?(coder decoder: NSCoder) {
        Color = .white
        super.init(coder: decoder)
    }

    init(frame frameRect: NSRect, color: NSColor) {
        Color = color
        super.init(frame: frameRect)
        Text = makeCustomTextControl(frame:frameRect)
        Text?.backgroundColor = Color
        addSubview(Text!)
        isHidden = true
    }
    
    func displayText(_ text: String) {
        setText(text: text)
        isHidden = false
    }
    
    func hide() {
        isHidden = true
    }
}
