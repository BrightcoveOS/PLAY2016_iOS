//
//  main.m
//  PlayTwo
//
//  Created by Steve Bushell on 4/26/16.
//  Copyright © 2016 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

NSString * const kAccountID = @"your-account-id";
NSString * const kPolicyKey = @"your-policy-key";
NSString * kPlay2016PlaylistID = @"your-playlist-id";

// FreeWheel support
NSUInteger kFreewheelNetworkID = 0;
NSString * kFreewheelServerURL = @"http://freewheel-server-url";
NSString * kFreeWheelPlayerProfile = @"freewheel-player-profile";
NSString * kFreeWheelSiteSectionId = @"freewheel-site-section-id";
NSString * kFreeWheelVideoAssetId = @"freewheel-video-asset-id";
