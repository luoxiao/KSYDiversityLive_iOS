//
//  ViewController.m
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/21.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import "KSYSTController.h"
#import <asl.h>
#import <string.h>
#import <CommonCrypto/CommonDigest.h>
#import "st_mobile_common.h"
#import "st_mobile_sticker.h"
#import "st_mobile_beautify.h"
#import "STStickerLoader.h"
#import <GPUImage/GPUImage.h>
#import <libksygpulive/KSYGPUBeautifyPlusFilter.h>

#define CHECK_LICENSE_WITH_PATH 1

@interface KSYSTController (){
    NSURL *_hostURL;
}
@end
    
@implementation KSYSTController

- (void)viewDidLoad {
    [super viewDidLoad];
    //initial ksystreamerKit
    _kit = [[KSYSTStreamerKit alloc] initWithDefaultCfg];
    //set capture
    [self setCapture];
    //set streame
    [self setStream];
    NSLog(@"version is %@",[_kit getKSYVersion]);
    if (_kit) {
        _kit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_kit startPreview:self.view];
    }
}
- (void)setCapture{
    _kit.capPreset = AVCaptureSessionPreset1280x720;
    _kit.previewDimension = CGSizeMake(1280, 720);
    _kit.streamDimension  = CGSizeMake(1280, 720);
    _kit.videoFPS         = 15;
    _kit.cameraPosition   = AVCaptureDevicePositionFront;
}

- (void)setStream{
    // stream default settings
    // stream default settings
    _kit.streamerBase.videoCodec = KSYVideoCodec_AUTO;
    _kit.streamerBase.videoInitBitrate =  800;
    _kit.streamerBase.videoMaxBitrate  = 1000;
    _kit.streamerBase.videoMinBitrate  =    0;
    _kit.streamerBase.audiokBPS        =   48;
    _kit.streamerBase.shouldEnableKSYStatModule = YES;
    _kit.streamerBase.videoFPS = 15;
    //set stream url from uuid
    _hostURL = [NSURL URLWithString:@"rtmp://test.uplive.ks-cdn.com/live/123"];
}
- (void) onCapture{
    if (!_kit.vCapDev.isRunning){
        _kit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_kit startPreview:self.view];
    }
    else {
        [_kit stopPreview];
    }
}
- (void) onStream{
    if (_kit.streamerBase.streamState == KSYStreamStateIdle ||
        _kit.streamerBase.streamState == KSYStreamStateError) {
        [_kit.streamerBase startStream:_hostURL];
    }
    else {
        [_kit.streamerBase stopStream];
    }
}
- (IBAction)sticker:(id)sender {
    [_kit.ksyStFilter stChangeSicker];
}
- (void)addObserver{
    
}
@end
