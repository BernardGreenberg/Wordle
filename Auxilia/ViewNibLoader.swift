//
//  ViewNibLoader.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/11/23.
//
/*
 How to load a VIEW from a nib.  The view will likely have controls with @IBfoo's in the
 containing class.  This searches the list of created top-level elements for one
 matching the class name.
 
 We don't use it any more in the Wordle App (once did).  Creating the text control and
 drawing the box by hand is considerably easier and more straightforward.
 */

import Cocoa
/* https://stackoverflow.com/questions/40256755/how-to-load-nsview-from-xib-with-swift-3 */

protocol NibLoadable {
    static var nibName: String? { get }
    static func createFromNib(in bundle: Bundle) -> Self?
}

extension NibLoadable where Self: NSView {

    static var nibName: String? {
        return String(describing: Self.self)
    }

    static func createFromNib(in bundle: Bundle = Bundle.main) -> Self? {
        guard let nibName = nibName else { return nil }
        var topLevelArray: NSArray? = nil
        bundle.loadNibNamed(NSNib.Name(nibName), owner: self, topLevelObjects: &topLevelArray)
        guard let results = topLevelArray else { return nil }
        let views = Array<Any>(results).filter { $0 is Self }
        return views.last as? Self
    }
}
