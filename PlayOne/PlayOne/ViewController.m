//
//  ViewController.m
//  PlayOne
//
//  Created by Steve Bushell on 4/26/16.
//  Copyright © 2016 Brightcove. All rights reserved.
//

@import BrightcovePlayerSDK;

#import "ViewController.h"

// -- PLAY 2016 begin --
extern NSString *kAccountID;
extern NSString *kPolicyKey;
extern NSString *kPlay2016PlaylistID;
// -- PLAY 2016 end --

// -- PLAY 2016 begin --
// Listen to Playback Controller delegate messages
@interface ViewController () <BCOVPlaybackControllerDelegate>
// -- PLAY 2016 end --

// -- PLAY 2016 begin --
@property (nonatomic) BCOVPlaybackService *service;
@property (nonatomic) id<BCOVPlaybackController> playbackController;
@property (nonatomic) IBOutlet UIView *videoView;
// -- PLAY 2016 end --

@end


@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        // -- PLAY 2016 begin --
        NSLog(@"Setting up Playback Controller");
        BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
        self.playbackController = [manager createPlaybackController];
        self.playbackController.analytics.account = kAccountID;
        self.playbackController.delegate = self;
        self.playbackController.autoAdvance = YES;
        self.playbackController.autoPlay = YES;
        self.service = [[BCOVPlaybackService alloc] initWithAccountId:kAccountID policyKey:kPolicyKey];
        // -- PLAY 2016 end --
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // -- PLAY 2016 begin --
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"Configure the player");
    self.playbackController.view.frame = self.videoView.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoView addSubview:self.playbackController.view];
    // -- PLAY 2016 end --
    
    // -- PLAY 2016 begin --
    NSLog(@"Request Content from the Video Cloud");
    [self.service findPlaylistWithPlaylistID:kPlay2016PlaylistID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {
        
        if (playlist)
        {
            [self.playbackController setVideos:playlist];
        }
        else
        {
            NSLog(@"\n\n----- Don't forget to enter your own account values in main.m -----\n\n");
            NSLog(@"ViewController Debug - Error retrieving video playlist: `%@`", error);
        }
        
    }];
    // -- PLAY 2016 end --
}

// -- PLAY 2016 begin --
- (void)playbackController:(id<BCOVPlaybackController>)controller didCompletePlaylist:(id<NSFastEnumeration>)playlist
{
    [self.playbackController setVideos:playlist];
}
// -- PLAY 2016 end --

@end
