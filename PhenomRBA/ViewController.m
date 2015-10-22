//
//  ViewController.m
//  Phenom RBA
//
//  Created by Corey Walo on 4/10/13.
//  Copyright (c) 2013 Audio Armada. All rights reserved.
//

#import "ViewController.h"
#import "AAAudioFileSampler.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>

//plist keys
#define kAllFiles @"allFiles"
#define kFileName @"fileName"
#define kFileType @"fileType"
#define kDisplayName @"displayName"

@interface ViewController()

@property(strong, nonatomic) AAAudioFileSampler *filePlayer;
@property(strong, nonatomic) NSMutableArray *sampleURLs;
@property(strong, nonatomic) NSMutableArray *buttonNames;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //set play sample action for drumButtons
    for(UIView* view in self.view.subviews)
    {
        if([view isKindOfClass:[UIButton class]]) {
            [(UIButton*)view addTarget:self action:@selector(playSample:) forControlEvents:UIControlEventTouchDown];
            
            [[(UIButton*)view layer] setCornerRadius:4.0];
            
            [[((UIButton*)view) titleLabel] setTextColor:[UIColor colorWithRed:0.325 green:0.325 blue:0.325 alpha:1.0]];
            [[((UIButton*)view) titleLabel] setTextAlignment:NSTextAlignmentCenter];
            [[((UIButton*)view) titleLabel] setFont:[UIFont fontWithName:@"Avenir Medium" size:(CGFloat)15.0]];
        }
    }
    
    //init the filePlayer
    self.filePlayer = [AAAudioFileSampler new];
    
    //gather file paths and button names
    NSDictionary *fileSampleDictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FileSamples" ofType:@"plist"]];
    
    self.sampleURLs = nil;
    self.buttonNames = nil;
    for(NSDictionary *dict in [fileSampleDictionary objectForKey:kAllFiles])
    {
        if(!self.sampleURLs)
            self.sampleURLs = [NSMutableArray new];
        
        [self.sampleURLs addObject:[[NSBundle mainBundle] pathForResource:dict[kFileName] ofType:dict[kFileType]]];
        
        if(!self.buttonNames)
            self.buttonNames = [NSMutableArray new];
        
        [self.buttonNames addObject:dict[kDisplayName]];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    
    [self.filePlayer loadAudioURLS:self.sampleURLs];
    [self.filePlayer loadAUFilePlayers];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    [self resignFirstResponder];
    [self.filePlayer stopAndClosePlayers];
}

#pragma mark - playback

-(void)playSample:(UIButton*)sender
{
    [self.filePlayer playSample:sender.tag];
}

-(void)playCowbell
{
    //cowbell is last sample
    [self.filePlayer playSample:self.sampleURLs.count - 1];
}

-(void)stopCowbell
{
    //cowbell is last sample
    [self.filePlayer stopSample:self.sampleURLs.count - 1];
}

#pragma mark - shake handling

- (void)motionBegan:(UIEventSubtype)motion
          withEvent:(UIEvent *)event {
    
    // Play a sound whenever a shake motion starts
    if (motion != UIEventSubtypeMotionShake) return;
        [self playCowbell];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // Play a sound whenever a shake motion ends
    if (motion != UIEventSubtypeMotionShake) return;
        [self stopCowbell];
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // Play a sound whenever a shake motion ends
    if (motion != UIEventSubtypeMotionShake) return;
        [self stopCowbell];
}

@end
