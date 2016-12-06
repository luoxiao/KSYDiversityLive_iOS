//
//  ViewController.m
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/21.
//  Copyright © 2016年 孙健. All rights reserved.
//


//
//  ViewController.m
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/21.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import "KSYSTController.h"
#import "KSYSTStreamerKit.h"


@interface KSYSTController (){
    KSYSTStreamerKit     *_stKit;
    NSURL                *_hostURL;
}
@end

@implementation KSYSTController
- (void)viewDidLoad {
    [super viewDidLoad];
    //initial ksystreamerKit
    _stKit = [[KSYSTStreamerKit alloc] initWithDefaultCfg];
    //set capture
    [self setCapture];
    //set streame
    [self setStream];
}
- (void)setCapture{
    _stKit.capPreset = AVCaptureSessionPreset640x480;
    _stKit.previewDimension = CGSizeMake(1280, 720);
    _stKit.streamDimension = CGSizeMake(640, 360);
    _stKit.videoFPS       = 15;
    _stKit.cameraPosition = AVCaptureDevicePositionFront;
}

- (void)setStream{
    // stream default settings
    _stKit.streamerBase.videoCodec = KSYVideoCodec_AUTO;
    _stKit.streamerBase.videoInitBitrate =  800;
    _stKit.streamerBase.videoMaxBitrate  = 1000;
    _stKit.streamerBase.videoMinBitrate  =    0;
    _stKit.streamerBase.audiokBPS        =   48;
    _stKit.streamerBase.shouldEnableKSYStatModule = YES;
    _stKit.streamerBase.videoFPS = 15;
    _stKit.streamerBase.logBlock = ^(NSString* str){
    };
    //set stream url from uuid
    _hostURL = [NSURL URLWithString:@"rtmp://test.uplive.ks-cdn.com/live/ksyun"];
}
//遇到的问题：开启预览后很卡
- (IBAction)onCapture:(UIButton *)sender {
    if (!_stKit.vCapDev.isRunning) {
        _stKit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_stKit startPreview:self.view];
        [sender setEnabled:NO];
    }
    else{
        [_stKit stopPreview];
    }
}

- (IBAction)onStream:(id)sender {
    if (_stKit.streamerBase.streamState == KSYStreamStateIdle || _stKit.streamerBase.streamState == KSYStreamStateError) {
        [_stKit.streamerBase startStream:_hostURL];
    }
    else{
        [_stKit.streamerBase stopStream];
    }
}
- (IBAction)sticker:(id)sender {
    [_stKit.ksyStFilter stChangeSicker];
}
- (void)addObserver{
    
}
@end
