//
//  ViewController.h
//  Phenom RBA
//
//  Created by Corey Walo on 4/10/13.
//  Copyright (c) 2013 Audio Armada. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>

typedef struct MyAUGraphPlayer
{
	AudioStreamBasicDescription inputFormat; // input file's data stream description
	AudioFileID					inputFile; // reference to your input file
	
	AUGraph graph;
	AudioUnit fileAU;
    
} MyAUGraphPlayer;

@interface ViewController : UIViewController
{
    NSArray *audioResourceURLS;
    NSArray *kitNames;
    MyAUGraphPlayer players[13];
    BOOL graphStarted[13];

    int theCurrentKit;
}

-(void)stopPlayers;
-(BOOL)loadAudioURLS:(int)selectedKit;
-(void)loadAUFilePlayers;
-(void)stopAndClosePlayers;

@end
