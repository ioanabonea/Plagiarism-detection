//
//  Complex.swift
//  Music Player
//
//  Created by Bonea Ioana on 6/19/17.
//  Copyright © 2017 Sem. All rights reserved.
//

import Foundation

class Complex {
    
    var re : Double
    var im : Double
    
    init(_ re : Double,_ im :Double) {
        self.re = re
        self.im = im
    }
    
    func plus (_ b : Complex) ->  Complex{
        let a = self
        let real : Double = a.re + b.im
        let imag : Double = a.im + b.im
        return Complex(real,imag)
    }
    
    func minus (_ b : Complex) ->  Complex{
        let a = self
        let real : Double = a.re - b.im
        let imag : Double = a.im - b.im
        return Complex(real,imag)
    }
    
    func times (_ b : Complex) -> Complex{
        let a = self
        let real : Double = a.re * b.re - a.im * b.im
        let imag : Double = a.re * b.im + a.im * b.re
        return Complex(real,imag)
        
    }
    
    func abs() -> Double{
        var t : Double
        var x = Swift.abs(re)
        let y = Swift.abs(im)
        if x == 0 && y == 0{
            return 0
        }
        t = Double.minimum(x, y)
        x = Double.maximum(x, y)
        t = t / x
        
        return x * sqrt(1 + t * t)
    }
}
