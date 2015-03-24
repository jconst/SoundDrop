//
//  Helpers.swift
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/19/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

import Foundation
import UIKit

let PI = 3.14159265


func lengthOfLine(line: Line) -> CGFloat
{
    let xDist = line.end.x - line.start.x
    let yDist = line.end.y - line.start.y
    let square: Double = Double(xDist * xDist) + Double(yDist * yDist)
    return CGFloat(sqrt(square))
}

func centerOfLine(line: Line) -> CGPoint
{
    let xDist = line.end.x - line.start.x
    let yDist = line.end.y - line.start.y
    let centerX = line.start.x + (xDist/2.0)
    let centerY = line.start.y + (yDist/2.0)
    
    return CGPointMake(centerX, centerY)
}

func angleOfLine(line: Line) -> CGFloat
{
    return -CGFloat(atan2(line.end.y - line.start.y,
                         line.end.x - line.start.x));
}