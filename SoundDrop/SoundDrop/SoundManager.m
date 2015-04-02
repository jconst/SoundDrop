//
//  SoundManager.m
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/25/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

#import "SoundManager.h"
#import "PdAudioController.h"
#import "PdFile.h"
#import "PdBase.h"

static double freq_exp = 0;

@interface SoundManager ()
@property (nonatomic, strong) PdAudioController *controller;
@property (nonatomic, strong) PdFile *bouncePatch;
@end

@implementation SoundManager

- (id)init
{
    if (!(self = [super init]))
        return nil;
    
    self.bouncePatch = [PdFile openFileNamed:@"master.pd"
                                        path:[[NSBundle mainBundle] resourcePath]];
    
    self.controller = [PdAudioController new];
    [self.controller configurePlaybackWithSampleRate:44100
                                      numberChannels:2
                                        inputEnabled:YES
                                       mixingEnabled:YES];
    self.controller.active = YES;

    return self;
}

- (void)playBounceWithContactSpeed:(double)speed
{
    if (freq_exp == 0) {
        freq_exp = pow(2.0, (1.0/12.0));
    }
    
    int midiKey = 73 + (((speed / 1.5) - 0.5) * 48);
    double frequency = 440 * pow(freq_exp, (midiKey-69));
    
    //Todo: send frequency over OSC to slave app
    [PdBase sendFloat:midiKey toReceiver:@"bouncekey"];
}

@end
