//
//  SamplePlayer.swift
//  SoundDrop
//
//  Created by Joseph Constantakis on 4/15/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

import UIKit
import AVFoundation

class SamplePlayer: NSObject {
    
    let players = Array<AVAudioPlayer>()
    let channels = 10
    var curChannel = 0
    
    required override init() {
        let kickSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("kick2", ofType: "wav")!)
        for i in 0..<channels {
            let audioPlayer = AVAudioPlayer(contentsOfURL: kickSound, error: nil)
            audioPlayer.prepareToPlay()
            players.append(audioPlayer)
        }
    }
    
    func playKick() {
        players[curChannel].play()
        curChannel = (curChannel + 1) % channels
    }
}
