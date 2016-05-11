//
//  ViewController.m
//  PlayTwo
//
//  Created by Steve Bushell on 4/26/16.
//  Copyright © 2016 Brightcove. All rights reserved.
//

@import BrightcovePlayerSDK;

// -- PLAY 2016 begin --
@import BrightcoveFW;
@import BrightcovePlayerUI;
// -- PLAY 2016 end --

#import "ViewController.h"

// -- PLAY 2016 begin --
#import "AdManager/FWSDK.h"

extern NSUInteger kFreewheelNetworkID;
extern NSString * kFreewheelServerURL;
extern NSString * kFreeWheelPlayerProfile;
extern NSString * kFreeWheelSiteSectionId;
extern NSString * kFreeWheelVideoAssetId;
// -- PLAY 2016 end --

extern NSString *kAccountID;
extern NSString *kPolicyKey;
extern NSString *kPlay2016PlaylistID;

// -- PLAY 2016 begin --
@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>
// -- PLAY 2016 end --

@property (nonatomic) BCOVPlaybackService *service;
@property (nonatomic) id<BCOVPlaybackController> playbackController;
@property (nonatomic) IBOutlet UIView *videoView;

// -- PLAY 2016 begin --
// PlayerUI's Player View
@property (nonatomic) BCOVPUIPlayerView *playerView;

// Freewheel support
@property (nonatomic, strong) id<FWAdManager> adManager;
// -- PLAY 2016 end --

@end


@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        NSLog(@"Setting up Playback Controller");
        BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
        // -- PLAY 2016 begin --
        self.playbackController = [manager createFWPlaybackControllerWithAdContextPolicy:[self adContextPolicy] viewStrategy:nil];
        // -- PLAY 2016 end --
        self.playbackController.analytics.account = kAccountID;
        self.playbackController.delegate = self;
        self.playbackController.autoAdvance = YES;
        self.playbackController.autoPlay = YES;
        self.service = [[BCOVPlaybackService alloc] initWithAccountId:kAccountID policyKey:kPolicyKey];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // -- PLAY 2016 begin --
    NSLog(@"Initialize FreeWheel Ad Manager");
    _adManager = newAdManager();
    [_adManager setNetworkId:kFreewheelNetworkID];
    [_adManager setServerUrl:kFreewheelServerURL];
    // -- PLAY 2016 end --
    
    
    // -- PLAY 2016 begin --
    NSLog(@"Configure the Player View");
    
    // Playback controller's view no longer added directly to video view.
    // self.playbackController.view.frame = self.videoView.bounds;
    // self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    // [self.videoView addSubview:self.playbackController.view];
    
    // Create and set options.
    BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
    options.presentingViewController = self;
    options.learnMoreButtonBrowserStyle = BCOVPUILearnMoreButtonUseInAppBrowser;
    
    // Create and configure Control View.
    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:options controlsView:controlView];
    self.playerView.playbackController = self.playbackController;
    self.playerView.delegate = self;
    self.playerView.frame = self.videoView.bounds;
    self.playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    // Add BCOVPUIPlayerView to video view.
    [self.videoView addSubview:self.playerView];
    // -- PLAY 2016 end --
    
    NSLog(@"Request Content from the Video Cloud");
    [self.service findPlaylistWithPlaylistID:kPlay2016PlaylistID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {
        
        if (playlist)
        {
            NSLog(@"Setting playlist");
            [self.playbackController setVideos:playlist];
        }
        else
        {
            NSLog(@"\n\n----- Don't forget to enter your own account values in main.m -----\n\n");
            NSLog(@"ViewController Debug - Error retrieving video playlist: `%@`", error);
        }
        
    }];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller didCompletePlaylist:(id<NSFastEnumeration>)playlist
{
    // When the playlist completes, play it again.
    [self.playbackController setVideos:playlist];
}

// -- PLAY 2016 begin --
- (BCOVFWSessionProviderAdContextPolicy)adContextPolicy
{
    ViewController * __weak weakSelf = self;
    
    return [^ id<FWContext>(BCOVVideo *video, BCOVSource *source, NSTimeInterval videoDuration) {
        
        ViewController *strongSelf = weakSelf;
        
        // This block will get called before every session is delivered. The source,
        // video, and videoDuration are provided in case you need to use them to
        // customize the these settings.
        // The values below are specific to this sample app, and should be changed
        // appropriately. For information on what values need to be provided,
        // please refer to your FreeWheel documentation or contact your Freewheel
        // account executive. Basic information is provided below.
        id<FWContext> adContext = [strongSelf.adManager newContext];
        
        NSLog(@"Setting up ad context");
        
        // These are player/app specific values.
        [adContext setPlayerProfile:kFreeWheelPlayerProfile
         defaultTemporalSlotProfile:nil
      defaultVideoPlayerSlotProfile:nil
      defaultSiteSectionSlotProfile:nil];
        
        [adContext setSiteSectionId:kFreeWheelSiteSectionId
                             idType:FW_ID_TYPE_CUSTOM
                     pageViewRandom:0
                          networkId:0
                         fallbackId:0];
        
        // This is an asset specific value.
        [adContext setVideoAssetId:kFreeWheelVideoAssetId
                            idType:FW_ID_TYPE_CUSTOM
                          duration:videoDuration
                      durationType:FW_VIDEO_ASSET_DURATION_TYPE_EXACT
                          location:nil
                      autoPlayType:true
                   videoPlayRandom:0
                         networkId:0
                        fallbackId:0];
        
        // This is the view where the ads will be rendered.
        [adContext setVideoDisplayBase:strongSelf.playerView.contentOverlayView];
        
        // These are required to use Freewheel's OOTB ad controls.
        [adContext setParameter:FW_PARAMETER_USE_CONTROL_PANEL withValue:@"NO" forLevel:FW_PARAMETER_LEVEL_GLOBAL];
        [adContext setParameter:FW_PARAMETER_CLICK_DETECTION withValue:@"NO" forLevel:FW_PARAMETER_LEVEL_GLOBAL];
        
        [adContext addTemporalSlot:@"preroll"
                            adUnit:FW_ADUNIT_PREROLL
                      timePosition:0.00
                       slotProfile:nil
                  cuePointSequence:1
                       minDuration:0
                       maxDuration:100
          acceptPrimaryContentType:nil
                 acceptContentType:nil];
        
        [adContext addTemporalSlot:@"midroll1"
                            adUnit:FW_ADUNIT_MIDROLL
                      timePosition:videoDuration * 0.333f
                       slotProfile:nil
                  cuePointSequence:1
                       minDuration:0
                       maxDuration:100
          acceptPrimaryContentType:nil
                 acceptContentType:nil];
        
        [adContext addTemporalSlot:@"midroll2"
                            adUnit:FW_ADUNIT_MIDROLL
                      timePosition:videoDuration * 0.666f
                       slotProfile:nil
                  cuePointSequence:2
                       minDuration:0
                       maxDuration:100
          acceptPrimaryContentType:nil
                 acceptContentType:nil];
        
        [adContext addTemporalSlot:@"postroll"
                            adUnit:FW_ADUNIT_POSTROLL
                      timePosition:0.00
                       slotProfile:nil
                  cuePointSequence:2
                       minDuration:0
                       maxDuration:100
          acceptPrimaryContentType:nil
                 acceptContentType:nil];
        
        return adContext;
        
    } copy];
}
// -- PLAY 2016 end --

@end
