//
//  ViewController.m
//  Phenom RBA
//
//  Created by Corey Walo on 4/10/13.
//  Copyright (c) 2013 Audio Armada. All rights reserved.
//

#import "ViewController.h"
#import "CWAudioFileSampler.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>

//plist keys
#define kAllFiles @"allFiles"
#define kFileName @"fileName"
#define kFileType @"fileType"
#define kDisplayName @"displayName"

@interface ViewController()

@property(strong, nonatomic) CWAudioFileSampler *filePlayer;
@property(strong, nonatomic) NSMutableArray *sampleURLs;
@property(strong, nonatomic) NSMutableArray *buttonNames;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //init the filePlayer
    self.filePlayer = [CWAudioFileSampler new];
    
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
    
    [self.filePlayer loadAudioURLS:self.sampleURLs];
    
    //set title and action for buttons
    for(UIView* view in self.view.subviews)
    {
        if([view isKindOfClass:[UIButton class]]) {
            
            UIButton *button = (UIButton*)view;
            
            [button addTarget:self action:@selector(playSample:) forControlEvents:UIControlEventTouchDown];
            
            [[button layer] setCornerRadius:2.0];
            
            [button setTitle:[(NSString*)self.buttonNames[button.tag] uppercaseString] forState:UIControlStateNormal];
            
            [[button titleLabel] setTextColor:[UIColor colorWithRed:0.325 green:0.325 blue:0.325 alpha:1.0]];
            [[button titleLabel] setTextAlignment:NSTextAlignmentCenter];
            [[button titleLabel] setNumberOfLines:0];
            [[button titleLabel] setLineBreakMode:NSLineBreakByWordWrapping];
            [[button titleLabel] setFont:[UIFont fontWithName:@"Avenir Medium" size:(CGFloat)12.0]];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
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
    // Stop sound whenever a shake motion ends
    if (motion != UIEventSubtypeMotionShake) return;
        [self stopCowbell];
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // Stop sound whenever a shake motion ends
    if (motion != UIEventSubtypeMotionShake) return;
        [self stopCowbell];
}

@end
