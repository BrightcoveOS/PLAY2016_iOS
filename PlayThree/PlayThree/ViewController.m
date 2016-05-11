//
//  ViewController.m
//  PlayThree
//
//  Created by Steve Bushell on 4/26/16.
//  Copyright © 2016 Brightcove. All rights reserved.
//

@import BrightcovePlayerSDK;
@import BrightcovePlayerUI;

#import "ViewController.h"


extern NSString *kAccountID;
extern NSString *kPolicyKey;
extern NSString *kPlay2016PlaylistID;

@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic) BCOVPlaybackService *service;
@property (nonatomic) id<BCOVPlaybackController> playbackController;
@property (nonatomic) IBOutlet UIView *videoView;

// -- PLAY 2016 begin --
// Which layout are we displaying?
@property (nonatomic) int layoutIndex;
@property (nonatomic) BCOVPUILayoutView *hideableLayoutView;
// -- PLAY 2016 end --

// PlayerUI's Player View
@property (nonatomic) BCOVPUIPlayerView *playerView;

@end


@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        NSLog(@"Setting up Playback Controller");
        BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
        self.playbackController = [manager createPlaybackController];
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
    
    
    NSLog(@"Configure the Player View");
    
    // Create and set options.
    BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
    options.presentingViewController = self;
    
    // -- PLAY 2016 begin --
    // Make the controls linger on screen a lot longer.
    options.hideControlsInterval = 60.0f;
    // But hide and show quickly.
    options.hideControlsAnimationDuration = 0.1f;
    
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
- (IBAction)setNextLayout:(id)sender
{
    // Cycle through the various layouts.
    self.layoutIndex ++;
    
    NSLog(@"Setting layout number %d", self.layoutIndex);
    
    BCOVPUIControlLayout *newControlLayout;
    
    switch (self.layoutIndex)
    {
        case 0:
        {
            // Controls for basic VOD
            newControlLayout = [BCOVPUIControlLayout basicVODControlLayout];
            break;
        }
            
        case 3:
        {
            // Controls for live stream with DVR controls
            newControlLayout = [BCOVPUIControlLayout basicLiveDVRControlLayout];
            break;
        }
            
        case 2:
        {
            // Controls for live stream
            newControlLayout = [BCOVPUIControlLayout basicLiveControlLayout];
            break;
        }
            
        case 1:
        {
            // Simple custom layout
            newControlLayout = [self simpleCustomLayout];
            break;
        }
            
        case 4:
        {
            // Complex custom layout
            newControlLayout = [self complexCustomLayout];
            break;
        }
            
        default:
        {
            // Set nil to remove all controls.
            newControlLayout = nil;
            
            // Reset index
            self.layoutIndex = -1;
            break;
        }
    }
    
    self.playerView.controlsView.layout = newControlLayout;
    
    switch (self.layoutIndex)
    {
        case 4:
        {
            // Change font on Current Time and Duration labels.
            UIFont* font = [UIFont fontWithName:@"klingon font" size:22];
            
            self.playerView.controlsView.currentTimeLabel.font = font;
            self.playerView.controlsView.currentTimeLabel.textColor = [UIColor orangeColor];
            self.playerView.controlsView.durationLabel.font = font;
            self.playerView.controlsView.durationLabel.textColor = [UIColor orangeColor];
            
            BCOVPUIButton *b = self.playerView.controlsView.screenModeButton;

            // Change color of full-screen button.
            [b setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
            [b setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];
            
            // Change color of jump back button.
            b = self.playerView.controlsView.jumpBackButton;
            [b setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
            [b setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];
            
            // Change color of play/pause button.
            b = self.playerView.controlsView.playbackButton;
            [b setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
            [b setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];
            
            // Change color of separator label.
            self.playerView.controlsView.timeSeparatorLabel.textColor = [UIColor greenColor];

            // Customize the slider.
            BCOVPUISlider *slider = self.playerView.controlsView.progressSlider;
            
            [slider setBufferProgressTintColor:[UIColor greenColor]];
            [slider setMinimumTrackTintColor:[UIColor orangeColor]];
            [slider setMaximumTrackTintColor:[UIColor purpleColor]];
            [slider setThumbTintColor:[UIColor colorWithRed:0.9 green:0.3 blue:0.3 alpha:0.5]];
            [slider setNeedsDisplay];
            
            break;
        }
            
        default:
        {
            break;
        }
    }
}
// -- PLAY 2016 end --

// -- PLAY 2016 begin --
- (BCOVPUIControlLayout *)simpleCustomLayout
{
    BCOVPUIControlLayout *layout;
    
    // Create a new control for each tag.
    // Controls are packaged inside a layout view.
    BCOVPUILayoutView *playbackLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonPlayback width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *currentTimeLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelCurrentTime width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *durationLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelDuration width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *progressLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagSliderProgress width:kBCOVPUILayoutUseDefaultValue elasticity:1.0];
    BCOVPUILayoutView *spacerLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:8 elasticity:1.0];
    
    // Configure the standard layout lines.
    NSArray *standardLayoutLine1 = @[ spacerLayoutView,
                                      playbackLayoutView,
                                      currentTimeLayoutView,
                                      progressLayoutView,
                                      durationLayoutView,
                                      spacerLayoutView ];
    
    NSArray *standardLayoutLines = @[ standardLayoutLine1 ];
    
    // Configure the compact layout lines.
    NSArray *compactLayoutLine1 = @[ progressLayoutView ];
    NSArray *compactLayoutLine2 = @[ spacerLayoutView,
                                     currentTimeLayoutView,
                                     spacerLayoutView,
                                     playbackLayoutView,
                                     spacerLayoutView,
                                     durationLayoutView,
                                     spacerLayoutView ];
    
    NSArray *compactLayoutLines = @[ compactLayoutLine1, compactLayoutLine2 ];
    
    layout = [[BCOVPUIControlLayout alloc] initWithStandardControls:standardLayoutLines
                                                    compactControls:compactLayoutLines];
    
    // Put the threshold between the width and height to make sure we change layouts on rotation.
    layout.compactLayoutMaximumWidth = (self.view.frame.size.width + self.view.frame.size.height) / 2.0f;
    
    // Remember the layout view that we want to hide.
    self.hideableLayoutView = playbackLayoutView;
    
    return layout;
}
// -- PLAY 2016 end --

// -- PLAY 2016 begin --
- (BCOVPUIControlLayout *)complexCustomLayout
{
    BCOVPUIControlLayout *layout;
    
    // Create a new control for each tag.
    // Controls are packaged inside a layout view.
    BCOVPUILayoutView *playbackLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonPlayback width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *jumpBackButtonLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonJumpBack width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *currentTimeLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelCurrentTime width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *timeSeparatorLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelTimeSeparator width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *durationLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelDuration width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *progressLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagSliderProgress width:kBCOVPUILayoutUseDefaultValue elasticity:1.0];
    BCOVPUILayoutView *closedCaptionLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonClosedCaption width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    closedCaptionLayoutView.removed = YES; // Hide until it's explicitly needed.
    BCOVPUILayoutView *screenModeLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonScreenMode width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *externalRouteLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewExternalRoute width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    externalRouteLayoutView.removed = YES; // Hide until it's explicitly needed.
    BCOVPUILayoutView *spacerLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:8 elasticity:1.0];
    BCOVPUILayoutView *standardLogoLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:480 elasticity:0.25];
    BCOVPUILayoutView *compactLogoLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:36 elasticity:0.1];
    BCOVPUILayoutView *buttonLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:80 elasticity:0.2];
    BCOVPUILayoutView *labelLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:80 elasticity:0.2];
    
    
    // Put UIImages inside our logo layout views.
    {
        // Create logo image inside an image view for display in control bar.
        UIImageView *standardLogoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bcov_logo_horizontal_white.png"]];
        standardLogoImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        standardLogoImageView.contentMode = UIViewContentModeScaleAspectFill;
        standardLogoImageView.frame = standardLogoLayoutView.frame;
        
        // Add image view to our empty layout view.
        [standardLogoLayoutView addSubview:standardLogoImageView];
    }
    
    {
        // Create logo image inside an image view for display in control bar.
        UIImageView *compactLogoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bcov.png"]];
        compactLogoImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        compactLogoImageView.contentMode = UIViewContentModeScaleAspectFit;
        compactLogoImageView.frame = compactLogoLayoutView.frame;
        
        // Add image view to our empty layout view.
        [compactLogoLayoutView addSubview:compactLogoImageView];
    }
    
    {
        // Add UIButton to layout.
        UIButton *button = [[UIButton alloc] initWithFrame:buttonLayoutView.frame];
        
        [button setTitle:@"Tap Me" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        [buttonLayoutView addSubview:button];
    }
    
    {
        // Add UILabel to layout.
        UILabel *label = [[UILabel alloc] initWithFrame:buttonLayoutView.frame];
        
        label.text = @"Label";
        label.textColor = [UIColor greenColor];
        label.textAlignment = NSTextAlignmentRight;
        [labelLayoutView addSubview:label];
    }
    
    // Configure the standard layout lines.
    NSArray *standardLayoutLine1 = @[ playbackLayoutView,
                                      spacerLayoutView,
                                      spacerLayoutView,
                                      currentTimeLayoutView,
                                      progressLayoutView,
                                      durationLayoutView ];
    
    NSArray *standardLayoutLine2 = @[ buttonLayoutView,
                                      spacerLayoutView,
                                      standardLogoLayoutView,
                                      spacerLayoutView,
                                      labelLayoutView ];
    
    NSArray *standardLayoutLine3 = @[ jumpBackButtonLayoutView,
                                      spacerLayoutView,
                                      screenModeLayoutView ];
    
    NSArray *standardLayoutLines = @[ standardLayoutLine1,
                                      standardLayoutLine2,
                                      standardLayoutLine3 ];
    
    // Configure the compact layout lines.
    NSArray *compactLayoutLine1 = @[ playbackLayoutView,
                                     jumpBackButtonLayoutView,
                                     currentTimeLayoutView,
                                     timeSeparatorLayoutView,
                                     durationLayoutView,
                                     progressLayoutView,
                                     closedCaptionLayoutView,
                                     screenModeLayoutView,
                                     externalRouteLayoutView,
                                     compactLogoLayoutView];
    
    NSArray *compactLayoutLines = @[ compactLayoutLine1 ];
    
    layout = [[BCOVPUIControlLayout alloc] initWithStandardControls:standardLayoutLines
                                                    compactControls:compactLayoutLines];
    
    // Put the threshold between the width and height to make sure we change layouts on rotation.
    layout.compactLayoutMaximumWidth = (self.view.frame.size.width + self.view.frame.size.height) / 2.0f;
    
    // Remember the layout view that we want to hide.
    self.hideableLayoutView = playbackLayoutView;
    
    return layout;
}
// -- PLAY 2016 end --

// -- PLAY 2016 begin --
- (void)handleButtonTap:(UIButton *)button
{
    // When the "Tap Me" button is tapped, show a red label that fades quickly.
    UILabel *label = [[UILabel alloc] initWithFrame:self.playerView.frame];
    label.text = @"Tapped!";
    label.textColor = [UIColor redColor];
    label.font = [UIFont boldSystemFontOfSize:128];
    [label sizeToFit];
    [self.playerView addSubview:label];
    label.center = self.playerView.center;
    
    [UIView animateWithDuration:1.0f animations:^{
        
        label.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        [label removeFromSuperview];
        
    }];
}
// -- PLAY 2016 end --

// -- PLAY 2016 begin --
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // When the device is shaked, toggle the removal of the saved layout view.
    NSLog(@"motionBegan - hiding/showing layout view");
    
    BOOL removed = self.hideableLayoutView.isRemoved;
    
    self.hideableLayoutView.removed = !removed;
    
    [self.playerView.controlsView setNeedsLayout];
}
// -- PLAY 2016 end --

@end
