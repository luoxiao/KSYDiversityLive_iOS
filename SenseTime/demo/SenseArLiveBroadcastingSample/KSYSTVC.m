//
//  KSYSTVC.m
//  SenseArLiveBroadcastingSample
//
//  Created by 孙健 on 2017/1/18.
//  Copyright © 2017年 SenseTime. All rights reserved.
//

#import "KSYSTVC.h"
#import "KSYSTKit.h"


@interface KSYSTVC ()
@property (nonatomic, strong) KSYSTKit *kit;
@property NSURL *hostURL;
@property NSString *strRTMPURL;
@end

@implementation KSYSTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    //ksy initialized
    _kit = [[KSYSTKit alloc] init];
    // 创建美颜和贴纸的结果纹理
    [self setCapture];
    [self setStream];
    if (_kit) {
        [_kit startPreview:self.view];
    }
}
#pragma - mark -
#pragma - mark KSYStreamer capture & stream config
- (void)setCapture{
    _kit.capPreset = AVCaptureSessionPreset1280x720;
    _kit.capturePixelFormat   = kCVPixelFormatType_32BGRA;
}
- (void)setStream{
    _strRTMPURL = @"rtmp://test.uplive.ks-cdn.com/live/123";
}
- (IBAction)onBtnSreaming:(id)sender {
    if (_kit.streamerBase.streamState == KSYStreamStateIdle ||
        _kit.streamerBase.streamState == KSYStreamStateError) {
        _hostURL = [NSURL URLWithString:_strRTMPURL];
        [_kit.streamerBase startStream:_hostURL];
    }
    else {
        [_kit.streamerBase stopStream];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeSticer:(id)sender {
    [_kit stickerChanger];
}

@end
