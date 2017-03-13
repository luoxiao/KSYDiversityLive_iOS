//
//  KSYSTVC.m
//  SenseArLiveBroadcastingSample
//
//  Created by 孙健 on 2017/1/18.
//  Copyright © 2017年 SenseTime. All rights reserved.
//

#import "KSYSTVC.h"
#import <libksygpulive/libksygpulive.h>
#import <libksygpulive/KSYGPUStreamerKit.h>
#import "KSYSTFilter.h"

static int i = 1;
static int count = 74;

@interface KSYSTVC ()
@property (nonatomic, strong) KSYGPUStreamerKit *kit;
@property (nonatomic, strong) KSYSTFilter * ksySTFitler;
@property NSURL *hostURL;
@property NSString *strRTMPURL;
@end

@implementation KSYSTVC
- (IBAction)openSticker:(id)sender {
    UISwitch* stick = (UISwitch*)sender;
    _ksySTFitler.enableSticker = stick.on;
}
- (IBAction)openBeauty:(id)sender {
    UISwitch* stick = (UISwitch*)sender;
    _ksySTFitler.enableBeauty = stick.on;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _kit = [[KSYGPUStreamerKit alloc] init];

    [self setCapture];
    [self setStream];
    [self setFilter];
    [_kit startPreview:self.view];
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

- (void)setFilter{
    _ksySTFitler = [[KSYSTFilter alloc]initWithAppid:@"7f76ce6bd292444b9368a7ba436c39fd" appKey:@"fa8e3603044c41ff8dbbd5531624ab0d"];
    
    __weak typeof(self) wVC = self;
    void (^completeCallback)(SenseArMaterial *) = ^(SenseArMaterial * m){
        NSLog(@"download SenseArMaterial finish");
    };
    void (^failCallback)(SenseArMaterial *, int, NSString *)= ^(SenseArMaterial * m , int error, NSString * errorMessage){
        NSLog(@"download SenseArMaterial failed,error:%d,errorMessage:%@",error,errorMessage);
    };
    void (^processCallback)(SenseArMaterial *material , float fProgress , int64_t iSize) = ^(SenseArMaterial *material , float fProgress , int64_t iSize){
        NSLog(@"downloading SenseArMaterial,fProgress:%f,iSize:%lld",fProgress,iSize);
    };
    _ksySTFitler.fetchListFinishCallback=^(NSUInteger count){
        [wVC.ksySTFitler changeSticker:0 onSuccess:completeCallback onFailure:failCallback onProgress:processCallback];
    };
    [_kit setupFilter:_ksySTFitler];

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
    void (^completeCallback)(SenseArMaterial *) = ^(SenseArMaterial * m){
        NSLog(@"download SenseArMaterial finish");
        [_ksySTFitler startShowingMaterial];
    };
    void (^failCallback)(SenseArMaterial *, int, NSString *)= ^(SenseArMaterial * m , int error, NSString * errorMessage){
        NSLog(@"download SenseArMaterial failed,error:%d,errorMessage:%@",error,errorMessage);
    };
    void (^processCallback)(SenseArMaterial *material , float fProgress , int64_t iSize) = ^(SenseArMaterial *material , float fProgress , int64_t iSize){
        NSLog(@"downloading SenseArMaterial,fProgress:%f,iSize:%lld",fProgress,iSize);
    };
    [_ksySTFitler changeSticker:i onSuccess:completeCallback onFailure:failCallback onProgress:processCallback];
    i = i + 1;
    i = i%count;
}



@end
