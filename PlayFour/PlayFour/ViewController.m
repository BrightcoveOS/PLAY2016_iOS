//
//  ViewController.m
//  PlayFour
//
//  Created by Steve Bushell on 4/26/16.
//  Copyright © 2016 Brightcove. All rights reserved.
//

@import BrightcovePlayerSDK;
@import BrightcovePlayerUI;

#import "ViewController.h"

const CGFloat kAspectRatio = 1.78;

extern NSString *kAccountID;
extern NSString *kPolicyKey;
extern NSString *kPlay2016PlaylistID;

@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic) BCOVPlaybackService *service;
@property (nonatomic) id<BCOVPlaybackController> playbackController;

// -- PLAY 2016 begin --
@property (nonatomic) NSArray *playlist;
@property (nonatomic) NSArray *playlistImages;


// Array of UIImageViews for post images
@property (nonatomic) NSMutableArray *posterImageViewArray;
@property (nonatomic) NSMutableArray *posterButtonArray;

// -- PLAY 2016 end --

// PlayerUI's Player View
@property (nonatomic) BCOVPUIPlayerView *playerView;
@property (nonatomic) BCOVPUIControlLayout *customLayout;

@property (nonatomic) UIImageView *loadingImageView;
@property (nonatomic) BOOL newSessionLoaded;
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
        self.playbackController.autoPlay = NO;
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
    // Create and configure Control View.
    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:options controlsView:controlView];
    self.playerView.playbackController = self.playbackController;
    self.playerView.delegate = self;
    self.playerView.frame = self.view.bounds;
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    
    self.playerView.controlsView.layout = nil;
    
    self.customLayout = [self customLayout];
    
    // Add BCOVPUIPlayerView to video view.
    self.playerView.translatesAutoresizingMaskIntoConstraints = YES;
    [self.view addSubview:self.playerView];
    
    // Hide player offscreen until we need it.
    self.playerView.frame = CGRectMake(-200, 20, 200, 200);
    
    //  Load our "loading..." image.
    self.loadingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"please-stand-by.png"]];
    // -- PLAY 2016 end --
    
    // -- PLAY 2016 begin --
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(singleTapHandler:)];
    tapper.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapper];
    
    // -- PLAY 2016 end --
    
    NSLog(@"Request Content from the Video Cloud");
    [self.service findPlaylistWithPlaylistID:kPlay2016PlaylistID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {
        
        if (playlist)
        {
            NSMutableArray *mutablePlaylist = [NSMutableArray array];
            for (BCOVVideo *video in playlist)
            {
                [mutablePlaylist addObject:video];
            }
            
            self.playlist = mutablePlaylist;
            
            // Load and create UIButtons out of poster frames.
            [self loadPosterImagesForPlaylist:playlist
                                   completion:^(NSArray *newPosterImages) {
                                       
                                       int imageIndex = 0;
                                       self.posterButtonArray = [NSMutableArray array];
                                       
                                       for (UIImage *posterImage in newPosterImages)
                                       {
                                           CGFloat statusBarHeight = UIApplication.sharedApplication.statusBarFrame.size.height;
                                           CGFloat width = self.view.frame.size.width;
                                           CGFloat height = self.view.frame.size.height;
                                           CGFloat dim = (width < height ? width : height);
                                           CGFloat buttonWidth = dim * 0.33;
                                           CGFloat buttonHeight = buttonWidth / kAspectRatio;
                                           
                                           CGRect buttonFrame = CGRectMake(- buttonWidth, statusBarHeight + buttonHeight * imageIndex,
                                                                           buttonWidth, buttonHeight);
                                           UIButton *posterButton = [[UIButton alloc] initWithFrame:buttonFrame];
                                           
                                           posterButton.tag = imageIndex;
                                           
                                           [posterButton setTitle:@"" forState:UIControlStateNormal];
                                           [posterButton setImage:posterImage forState:UIControlStateNormal];
                                           
                                           [self.posterButtonArray addObject:posterButton];
                                           
                                           // Do actual UI work on main thread.
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               
                                               [posterButton addTarget:self
                                                                action:@selector(handlePosterButton:)
                                                      forControlEvents:UIControlEventTouchUpInside];
                                               [self.view addSubview:posterButton];
                                               
                                           });
                                           
                                           imageIndex ++;
                                       }
                                   }];
        }
        else
        {
            NSLog(@"\n\n----- Don't forget to enter your own account values in main.m -----\n\n");
            NSLog(@"ViewController Debug - Error retrieving video playlist: `%@`", error);
        }
        
    }];
}

// -- PLAY 2016 begin --
- (void)handlePosterButton:(UIButton *)posterButton
{
    // Handle click on a poster button
    CGRect viewFrame = self.view.frame;
    
    CGRect posterButtonRect = posterButton.frame;
    CGPoint posterCenter = posterButton.center;
    int posterButtonIndex = (int)posterButton.tag;

    // Grab video from main playlist based on poster button index.
    BCOVVideo *video = self.playlist[posterButtonIndex];
    
    self.newSessionLoaded = NO;
    
    // Play the new video.
    [self.playbackController pause];
    [self.playbackController setVideos:@[ video ]];
    [self.playbackController play];

    // Perform some crazy keyframe animation on the video view to bring it to center screen.
    
    // Borrow image from button to use as initial image.
    self.loadingImageView.image = posterButton.imageView.image;
    
    [self.playerView addSubview:self.loadingImageView];
    self.loadingImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.loadingImageView.frame = self.playerView.bounds;
    
    [self singleTapHandler:nil];
    
    self.playerView.controlsView.layout = nil;
    [self.playerView.controlsView setNeedsLayout];
    self.playerView.frame = posterButtonRect;
    
    self.loadingImageView.alpha = 1.0;
    
    {
        // Animate moving the player to the center.
        CGPoint endPoint = self.view.center;
        endPoint.y *= 0.66;
        
        CGPoint beginTranslation = CGPointMake(posterCenter.x - endPoint.x,
                                               posterCenter.y - endPoint.y);
        
        CGFloat startScale = posterButtonRect.size.width / viewFrame.size.width;
        CGFloat endScale = 1;
        
        CGRect newPlayerViewBounds = CGRectMake(0, 0, viewFrame.size.width, viewFrame.size.width / kAspectRatio);
        self.playerView.bounds = newPlayerViewBounds;
        self.playerView.center = endPoint;
        
        [CATransaction begin];
        
        {
            [CATransaction setCompletionBlock:^{
                
                // When animation completes, install our controls layout again.
                self.playerView.controlsView.layout = self.customLayout;
                [self.playerView.controlsView setNeedsLayout];
                [self.playerView layoutIfNeeded];
                
            }];
            
            NSMutableArray *keyframeValues = [NSMutableArray array];
            
            CGFloat steps = 500.0;
            for (int t = 0; t <= steps; t ++)
            {
                CGFloat tScale = t / steps;
                CGFloat tInverseScale = (1.0 - tScale);
                CGFloat tMidScale = 2.0 * sqrt(tScale * tInverseScale);
                CGFloat rotation = tMidScale * (-(sin(tScale * 3 * M_PI))/7 * 360 * M_PI / 180.0f);
                CGFloat viewScale = tInverseScale * startScale + tScale * endScale;
                
                CGAffineTransform affineTransform = CGAffineTransformIdentity;
                affineTransform = CGAffineTransformTranslate(affineTransform, tInverseScale * beginTranslation.x, tInverseScale * beginTranslation.y);
                affineTransform = CGAffineTransformRotate(affineTransform, rotation);
                affineTransform = CGAffineTransformScale(affineTransform, viewScale, viewScale);
                affineTransform = CGAffineTransformTranslate(affineTransform, tMidScale * sin(tMidScale * 2 * M_PI) * viewFrame.size.width / 2,
                                                             tMidScale * cos(tMidScale * 2 * M_PI) * viewFrame.size.width / 2);
                
                CATransform3D transform3D = CATransform3DMakeAffineTransform(affineTransform);
                
                NSValue *value = [NSValue valueWithCATransform3D:transform3D];
                
                [keyframeValues addObject:value];
            }
            
            CAKeyframeAnimation * animation = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
            
            animation.values = keyframeValues;
            
            animation.autoreverses = NO ;
            animation.repeatCount = 0 ;
            animation.duration = 4.0f ;
            animation.removedOnCompletion = YES;
            [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            
            [self.playerView.layer addAnimation:animation forKey:@"transform" ] ;
        }
        
        [CATransaction commit];
    }
}
// -- PLAY 2016 end --

// -- PLAY 2016 begin --
- (void)singleTapHandler:(UITapGestureRecognizer*)sender
{
    static BOOL posterButtonVisible[6];
    int posterIndex = 0;
    
    for (UIButton *posterButton in self.posterButtonArray)
    {
        CGRect originalFrame = posterButton.frame;
        CGFloat offset;
        int posterButtonIndex = (int)posterButton.tag;
        
        if (posterButtonVisible[posterButtonIndex])
        {
            posterButtonVisible[posterButtonIndex] = NO;
            offset = - originalFrame.size.width;
        }
        else
        {
            posterButtonVisible[posterButtonIndex] = YES;
            offset = originalFrame.size.width;
        }
        
        [UIView animateWithDuration:0.1f
                              delay:posterIndex / 30.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             CGRect buttonRect = posterButton.frame;
                             buttonRect.origin.x += offset;
                             posterButton.frame = buttonRect;
                             
                         }
                         completion:^(BOOL finished) {
                             
                         }];
        
        posterIndex ++;
    }
}
// -- PLAY 2016 end --

- (void)playbackController:(id<BCOVPlaybackController>)controller didCompletePlaylist:(id<NSFastEnumeration>)playlist
{
    // When the playlist completes, play it again.
    [self.playbackController setVideos:playlist];
    [self.playbackController play];
}

// -- PLAY 2016 begin --
- (BCOVPUIControlLayout *)customLayout
{
    NSLog(@"Setting custom layout");
    
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
    
    NSMutableArray *posterImageViewLayoutArray = [NSMutableArray array];
    self.posterImageViewArray = [NSMutableArray array];
    
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
    
    // Configure the standard layout lines.
    NSArray *standardLayoutLine1 = posterImageViewLayoutArray;
    
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
    
    return layout;
}
// -- PLAY 2016 end --


// -- PLAY 2016 begin --
- (void)loadPosterImagesForPlaylist:(BCOVPlaylist *)playlist
                         completion:(void (^)(NSArray *newPlaylistImages))completion
{
    // Load poster images asynchronously
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSMutableArray *playlistImages = [NSMutableArray array];
        
        for (BCOVVideo *video in playlist)
        {
            NSURL *posterURL = [NSURL URLWithString:video.properties[@"poster"]];
            
            if (posterURL != nil)
            {
                NSData *posterImageData = [NSData dataWithContentsOfURL:posterURL];
                UIImage *posterImage = [UIImage imageWithData:posterImageData];
                
                if (posterImage != nil)
                {
                    [playlistImages addObject:posterImage];
                }
            }
        }
        
        self.playlistImages = playlistImages;
        
        completion(playlistImages);
    });
}
// -- PLAY 2016 end --

// -- PLAY 2016 begin --
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // Use keyframe animation to spin the video view around the 3D vector (1, 1, 1).
    
    NSLog(@"motionBegan");
    
    [CATransaction begin];
    
    {
        NSMutableArray *keyframeValues = [NSMutableArray array];
        
        CGFloat steps = 120.0;
        for (int t = 0; t <= steps; t ++)
        {
            CATransform3D transform3D = CATransform3DRotate(CATransform3DIdentity, (t / steps) * M_PI * 2, 1, 1, 1);
            
            NSValue *value = [NSValue valueWithCATransform3D:transform3D];
            
            [keyframeValues addObject:value];
        }
        
        CAKeyframeAnimation * animation = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
        
        animation.values = keyframeValues;
        
        animation.autoreverses = NO;
        animation.duration = 2;
        animation.removedOnCompletion = YES;
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        
        [self.playerView.layer addAnimation:animation forKey:@"transform" ] ;
    }
    
    [CATransaction commit];
}
// -- PLAY 2016 end --

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    // We got a new session.
    self.newSessionLoaded = YES;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    // When progress starts after a new session,
    // remove the "loading" image from the player view.
    if (self.newSessionLoaded)
    {
        if (self.loadingImageView.superview && progress > 0.0)
        {
            [UIView animateWithDuration:0.35f animations:^{
                
                self.loadingImageView.alpha = 0.0;
                
            } completion:^(BOOL finished) {
                
                [self.loadingImageView removeFromSuperview];
                
            }];
        }
    }
}

#pragma mark - Playback Controller Delegate Methods

// These are the available delegate methods and lifecycle events

// protocol BCOVPlaybackSessionBasicConsumer<NSObject>

- (void)didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session {}
- (void)playbackSession:(id<BCOVPlaybackSession>)session didChangeDuration:(NSTimeInterval)duration {}
- (void)playbackSession:(id<BCOVPlaybackSession>)session didChangeExternalPlaybackActive:(BOOL)externalPlaybackActive {}
- (void)playbackSession:(id<BCOVPlaybackSession>)session didPassCuePoints:(NSDictionary *)cuePointInfo {}
- (void)didCompletePlaylist:(id<NSFastEnumeration>)playlist {}
- (void)playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent {}
- (void)playbackSession:(id<BCOVPlaybackSession>)session didChangeSeekableRanges:(NSArray *)seekableRanges {}

// protocol BCOVPlaybackControllerDelegate <BCOVPlaybackControllerBasicDelegate, BCOVPlaybackControllerAdsDelegate>

// protocol BCOVPlaybackControllerBasicDelegate <NSObject>
//- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session {}
- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didChangeDuration:(NSTimeInterval)duration {}
- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didChangeExternalPlaybackActive:(BOOL)externalPlaybackActive {}
- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didPassCuePoints:(NSDictionary *)cuePointInfo {}
//- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress {}
//- (void)playbackController:(id<BCOVPlaybackController>)controller didCompletePlaylist:(id<NSFastEnumeration>)playlist {}
- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent {}
- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didChangeSeekableRanges:(NSArray *)seekableRanges {}


extern NSString * const kBCOVPlaybackSessionLifecycleEventReady;
extern NSString * const kBCOVPlaybackSessionLifecycleEventFail;
extern NSString * const kBCOVPlaybackSessionLifecycleEventPlay;
extern NSString * const kBCOVPlaybackSessionLifecycleEventPause;
extern NSString * const kBCOVPlaybackSessionLifecycleEventFailedToPlayToEndTime;
extern NSString * const kBCOVPlaybackSessionLifecycleEventResumeBegin;
extern NSString * const kBCOVPlaybackSessionLifecycleEventResumeComplete;
extern NSString * const kBCOVPlaybackSessionLifecycleEventResumeFail;
extern NSString * const kBCOVPlaybackSessionLifecycleEventEnd;
extern NSString * const kBCOVPlaybackSessionLifecycleEventPlaybackStalled;
extern NSString * const kBCOVPlaybackSessionLifecycleEventPlaybackRecovered;
extern NSString * const kBCOVPlaybackSessionLifecycleEventPlaybackBufferEmpty;
extern NSString * const kBCOVPlaybackSessionLifecycleEventPlaybackLikelyToKeepUp;
extern NSString * const kBCOVPlaybackSessionLifecycleEventTerminate;
extern NSString * const kBCOVPlaybackSessionLifecycleEventError;

@end
