//
//  ViewController.m
//  Phenom RBA
//
//  Created by Corey Walo on 4/10/13.
//  Copyright (c) 2013 Audio Armada. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self becomeFirstResponder];
    
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
    
    [self loadAudioURLS:0]; //0 is 1st kit
    
    [self loadAUFilePlayers];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    [self resignFirstResponder];
    [self stopAndClosePlayers];
}

- (void)motionBegan:(UIEventSubtype)motion
          withEvent:(UIEvent *)event {
    
    // Play a sound whenever a shake motion starts
    if (motion != UIEventSubtypeMotionShake) return;
    [self playCowbell:(int)12];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // Play a sound whenever a shake motion ends
    if (motion != UIEventSubtypeMotionShake) return;

    [self stopCowbell:(int)12];
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // Play a sound whenever a shake motion ends
    if (motion != UIEventSubtypeMotionShake) return;
    [self stopCowbell:(int)12];
}

-(BOOL)loadAudioURLS:(int)selectedKit
{
    theCurrentKit = selectedKit;
    switch(selectedKit)
    {
        case 0:
        {
            audioResourceURLS =  [NSArray arrayWithObjects:
                                  [[NSBundle mainBundle] pathForResource:@"Horn" ofType:@"wav"],        //1
                                  [[NSBundle mainBundle] pathForResource:@"TurnDown" ofType:@"wav"],    //2
                                  [[NSBundle mainBundle] pathForResource:@"GetAss" ofType:@"wav"],      //3
                                  [[NSBundle mainBundle] pathForResource:@"MyMan" ofType:@"wav"],       //4
                                  [[NSBundle mainBundle] pathForResource:@"NiceJob" ofType:@"wav"],        //5
                                  [[NSBundle mainBundle] pathForResource:@"Schwing" ofType:@"wav"],    //6
                                  [[NSBundle mainBundle] pathForResource:@"Fart" ofType:@"wav"],      //7
                                  [[NSBundle mainBundle] pathForResource:@"MudOrChocolate" ofType:@"wav"],       //8
                                  [[NSBundle mainBundle] pathForResource:@"SadBone" ofType:@"wav"],        //9
                                  [[NSBundle mainBundle] pathForResource:@"SlowDown" ofType:@"wav"],    //10
                                  [[NSBundle mainBundle] pathForResource:@"Crash" ofType:@"wav"],      //11
                                  [[NSBundle mainBundle] pathForResource:@"WaveRace" ofType:@"wav"],   //12
                                  [[NSBundle mainBundle] pathForResource:@"Cowbell" ofType:@"wav"],
                                  nil];
            break;
        }
    }
    return TRUE;
}

#pragma mark - audio unit setup -

-(void)loadAUFilePlayers
{
    //load file for every AUFilePlayer
	for(int i = 0; i < 13; i++)
    {
        //sampleURL = (__bridge CFURLRef)([NSURL fileURLWithPath:[audioResourceURLS objectAtIndex:i]]);
        CheckError(AudioFileOpenURL((__bridge CFURLRef)([NSURL fileURLWithPath:[audioResourceURLS objectAtIndex:i]]), kAudioFileReadPermission, 0, &players[i].inputFile), "AudioFileOpenURL failed");
        UInt32 propSize = sizeof(players[i].inputFormat);
        CheckError(AudioFileGetProperty(players[i].inputFile, kAudioFilePropertyDataFormat,
                                        &propSize, &players[i].inputFormat),
                   "couldn't get file's data format");
        
        //create the graph for every player
        CreateMyAUGraph(&players[i]);
        graphStarted[i] = NO;
    }
}

-(void)playSample:(id)sender
{
    int button = [sender tag];
    
    //if its playing stop it
    if(graphStarted[button] == YES)
    {
        AUGraphStop(players[button].graph);
    }
    
    //Float64 fileDuration = PrepareFileAU(&players[button]);
    PrepareFileAU(&players[button]);
    
    // start playing
    CheckError(AUGraphStart(players[button].graph),
                   "AUGraphStart failed");
    graphStarted[button] = YES;
        
    
}

-(void)playCowbell:(int)sampleInArray
{
    int position = sampleInArray;
    
    //if its playing stop it and start it again
    /*if(graphStarted[position] == YES)
    {
        
        AUGraphStop(players[position].graph);
        
        PrepareFileAU(&players[position]);
        // start playing
        CheckError(AUGraphStart(players[position].graph),
                   "AUGraphStart failed");
        graphStarted[position] = YES;
        
    }else */
     if(graphStarted[position] == NO) //if it hasn't started, prepare and start it
    {
        //Float64 fileDuration = PrepareFileAU(&players[button]);
        PrepareFileAU(&players[position]);
        
        // start playing
        CheckError(AUGraphStart(players[position].graph),
                   "AUGraphStart failed");
        graphStarted[position] = YES;
        
    }
}

-(void)stopCowbell:(int)sampleInArray
{
    int position = sampleInArray;
    if(graphStarted[position] == YES)
    {
        
        AUGraphStop(players[position].graph);
        graphStarted[position] = NO;
    }
}

void CreateMyAUGraph(MyAUGraphPlayer *player)
{
    // create a new AUGraph
	CheckError(NewAUGraph(&player->graph),
			   "NewAUGraph failed");
	
	// genereate description that will match out output device (speakers)
	AudioComponentDescription outputcd = {0};
	outputcd.componentType = kAudioUnitType_Output;
	outputcd.componentSubType = kAudioUnitSubType_RemoteIO;
	outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	// adds a node with above description to the graph
	AUNode outputNode;
	CheckError(AUGraphAddNode(player->graph, &outputcd, &outputNode),
			   "AUGraphAddNode[kAudioUnitSubType_DefaultOutput] failed");
	
	// generate description that will match a generator AU of type: audio file player
	AudioComponentDescription fileplayercd = {0};
	fileplayercd.componentType = kAudioUnitType_Generator;
	fileplayercd.componentSubType = kAudioUnitSubType_AudioFilePlayer;
	fileplayercd.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	// adds a node with above description to the graph
	AUNode fileNode;
	CheckError(AUGraphAddNode(player->graph, &fileplayercd, &fileNode),
			   "AUGraphAddNode[kAudioUnitSubType_AudioFilePlayer] failed");
	
	// opening the graph opens all contained audio units but does not allocate any resources yet
	CheckError(AUGraphOpen(player->graph),
			   "AUGraphOpen failed");
	
	// get the reference to the AudioUnit object for the file player graph node
	CheckError(AUGraphNodeInfo(player->graph, fileNode, NULL, &player->fileAU),
			   "AUGraphNodeInfo failed");
	
	// connect the output source of the file player AU to the input source of the output node
	CheckError(AUGraphConnectNodeInput(player->graph, fileNode, 0, outputNode, 0),
			   "AUGraphConnectNodeInput");
	
	// now initialize the graph (causes resources to be allocated)
	CheckError(AUGraphInitialize(player->graph),
			   "AUGraphInitialize failed");
}

double PrepareFileAU(MyAUGraphPlayer *player)
{
	// tell the file player unit to load the file we want to play
	CheckError(AudioUnitSetProperty(player->fileAU, kAudioUnitProperty_ScheduledFileIDs,
									kAudioUnitScope_Global, 0, &player->inputFile, sizeof(player->inputFile)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileIDs] failed");
	
	UInt64 nPackets;
	UInt32 propsize = sizeof(nPackets);
	CheckError(AudioFileGetProperty(player->inputFile, kAudioFilePropertyAudioDataPacketCount,
									&propsize, &nPackets),
			   "AudioFileGetProperty[kAudioFilePropertyAudioDataPacketCount] failed");
	
	// tell the file player AU to play the entire file
	ScheduledAudioFileRegion rgn;
	memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
	rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
	rgn.mTimeStamp.mSampleTime = 0;
	rgn.mCompletionProc = NULL;
	rgn.mCompletionProcUserData = NULL;
	rgn.mAudioFile = player->inputFile;
	rgn.mLoopCount = 0;
	rgn.mStartFrame = 0;
	rgn.mFramesToPlay = nPackets * player->inputFormat.mFramesPerPacket;
	
	CheckError(AudioUnitSetProperty(player->fileAU, kAudioUnitProperty_ScheduledFileRegion,
									kAudioUnitScope_Global, 0,&rgn, sizeof(rgn)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileRegion] failed");
	
	// prime the file player AU with default values
	UInt32 defaultVal = 0;
	CheckError(AudioUnitSetProperty(player->fileAU, kAudioUnitProperty_ScheduledFilePrime,
									kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFilePrime] failed");
	
	// tell the file player AU when to start playing (-1 sample time means next render cycle)
	AudioTimeStamp startTime;
	memset (&startTime, 0, sizeof(startTime));
	startTime.mFlags = kAudioTimeStampSampleTimeValid;
	startTime.mSampleTime = -1;
	CheckError(AudioUnitSetProperty(player->fileAU, kAudioUnitProperty_ScheduleStartTimeStamp,
									kAudioUnitScope_Global, 0, &startTime, sizeof(startTime)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduleStartTimeStamp]");
	
	// file duration
	return (nPackets * player->inputFormat.mFramesPerPacket) / player->inputFormat.mSampleRate;
    
}

-(void)stopAndClosePlayers
{
    for(int i = 0; i < 13; i++)
    {
        AUGraphStop (players[i].graph);
        AUGraphUninitialize (players[i].graph);
        AUGraphClose(players[i].graph);
        AudioFileClose(players[i].inputFile);
    }
    
    audioResourceURLS = nil;
}

-(void)stopPlayers
{
    for(int i = 0; i < 13; i++)
    {
        AUGraphStop (players[i].graph);
    }
}

//adamson's error handler: wrap core audio functions with it
static void CheckError(OSStatus error, const char *operation)
{
	if (error == noErr) return;
	
	char str[20];
	// see if it appears to be a 4-char-code
	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else
		// no, format it as an integer
		sprintf(str, "%d", (int)error);
	
	fprintf(stderr, "Error: %s (%s)\n", operation, str);
	
	exit(1);
}
@end
