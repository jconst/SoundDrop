//
//  Globals.swift
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/19/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

var lineLocations = Array<CGPoint>()
var lineRotations = Array<CGFloat>()
let soundManager = SoundManager()
let oscSender = OSCSender()

let snapshotInterval = 0.25
let flashMaxJump = CGFloat(0.13) // from 0 to 1 where 1 is a jump across the whole screen