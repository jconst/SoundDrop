//
//  Helpers.swift
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/19/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

import Foundation
import UIKit

func distanceBetween(p1: CGPoint, p2: CGPoint) -> CGFloat {
    return CGFloat(hypotf(Float(p1.x) - Float(p2.x), Float(p1.y) - Float(p2.y)))
}

func lerp(p1: CGPoint, p2: CGPoint, fraction: CGFloat) -> CGPoint {
    let x = p1.x + ((p2.x - p1.x) * fraction)
    let y = p1.y + ((p2.y - p1.y) * fraction)
    return CGPoint(x: x, y: y)
}
