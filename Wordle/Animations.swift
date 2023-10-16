//
//  Animations.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/10/23.
//

import Foundation

protocol AnimatorProtocol {
    func pointTransform(_ theta: Double) -> CGAffineTransform?
    func finish()
    var wholePerformanceDuration : Double {get}
}

class animateForJoy : AnimatorProtocol {
    /* Times are in seconds. Note that there is no mixed-mode arithmetic in Swift :( */
    let interCellDelay = 0.07
    let nPoints = 50.0
    var wholePerformanceDuration : Double {get {0.75}}
    let endTheta = 2.0*Double.pi

    var View : CellView
    var Theta = 0.0
    var deltaT = 0.0
    var deltaTheta = 0.0
    var halfHeight : Double
    var halfWidth : Double
    
    init (_ view: CellView) {
        View = view
        halfHeight = view.frame.height/2.0
        halfWidth = view.frame.width/2.0
        deltaT = wholePerformanceDuration/nPoints
        deltaTheta = endTheta/nPoints
    }
    
    func run(delay: Int) {
        setTimer(Double(delay)*interCellDelay)
    }
    
    func pointTransform(_ theta:Double)  -> CGAffineTransform? {
        return nil
    }
    func finish() {
        View.setTransform(nil)
    }
    
    @objc func timerHandler () {
        if Theta < endTheta {
            View.setTransform(pointTransform(Theta))
            Theta += deltaTheta
            setTimer(deltaT)
        } else {
            finish()
        }
    }
    
    private func setTimer(_ delta: Double) {
        Timer.scheduledTimer(timeInterval: delta,
                             target: self, selector: #selector(timerHandler),
                             userInfo: nil, repeats: false)
    }
}

class JumpForJoy : animateForJoy {
    override func pointTransform (_ theta: Double) -> CGAffineTransform {
        return CGAffineTransform(a: 1, b: 0,
                                 c: 0, d: 1,
                                 tx: 0, ty: halfHeight*pow(sin(theta), 2))
    }
}

class SomersaultForJoy : animateForJoy {
    override func pointTransform (_ theta: Double) -> CGAffineTransform {
        return CGAffineTransform(a: 1, b: 0,
                                 c: 0, d: cos(theta),
                                 tx: 0, ty: halfHeight*(1.0-cos(theta)))
    }
}

class PirouetteForJoy : animateForJoy {
    override func pointTransform (_ theta: Double) -> CGAffineTransform {
        return CGAffineTransform(a: cos(theta), b: 0,
                                 c: 0, d: 1,
                                 tx: halfWidth*(1.0-cos(theta)), ty: 0)
    }
}

class JiggleForDisappointment : animateForJoy {
    override var wholePerformanceDuration : Double {get {0.25}}
    override func pointTransform (_ theta: Double) -> CGAffineTransform {
        return CGAffineTransform(a: 1, b: 0,
                                 c: 0, d: 1,
                                 tx: 10.0*sin(4.0*theta), ty: 0)
    }
    override func finish() {
        View.setTransform(CGAffineTransform.identity) //don't know why nil not good enough
    }
}
