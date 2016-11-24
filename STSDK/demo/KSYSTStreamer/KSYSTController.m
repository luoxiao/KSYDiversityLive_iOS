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
#import <libksygpulive/KSYGPUStreamerKit.h>
#import "KSYSTFilter.h"
#import <GPUImage/GPUImage.h>

#define CHECK_LICENSE_WITH_PATH 1

@interface KSYSTController ()<KSYSTFilterDelegate>{
    KSYGPUStreamerKit    *_kit;
    GPUImageTextureInput *_inputTexture;
    KSYSTFilter          *_stFilter;
    GPUImageView         *_preview;
    NSURL                *_hostURL;
    KSYGPUPicOutput      *_ksyRGBOutput;
    KSYGPUPicOutput      *_ksyGpuToStr;
}
@end
    
@implementation KSYSTController

- (void)viewDidLoad {
    [super viewDidLoad];
    //initial ksystreamerKit
    _kit = [[KSYGPUStreamerKit alloc] initWithDefaultCfg];
    //set capture
    [self setCapture];
    //set streame
    [self setStream];
    //set video path
    [self setVideoChain];
    //set video chain
    [self setAudioChain];
}
- (void)setCapture{
    _kit.capPreset = AVCaptureSessionPreset1280x720;
    _kit.previewDimension = CGSizeMake(1280, 720);
    _kit.vCapDev.frameRate = 15;
    _kit.cameraPosition = AVCaptureDevicePositionFront;
}
//KSYSTDelegate
- (void)videoOutputWithTexture:(unsigned int)textOutput
                          size:(CGSize)size
                          time:(CMTime)timeInfo
{
    _inputTexture = [[GPUImageTextureInput alloc] initWithTexture:textOutput
                                                                 size:size];
    [_inputTexture addTarget:_ksyGpuToStr];
    [_inputTexture addTarget:_preview];
    [_inputTexture processTextureWithFrameTime:timeInfo];
    glDeleteTextures(1, &textOutput);
}

- (void)setStream{
    // stream default settings
    _kit.streamerBase.videoCodec = KSYVideoCodec_AUTO;
    _kit.streamerBase.videoInitBitrate =  800;
    _kit.streamerBase.videoMaxBitrate  = 1000;
    _kit.streamerBase.videoMinBitrate  =    0;
    _kit.streamerBase.audiokBPS        =   48;
    _kit.streamerBase.shouldEnableKSYStatModule = YES;
    _kit.streamerBase.videoFPS = 30;
    _kit.streamerBase.logBlock = ^(NSString* str){
    };
    //set stream url from uuid
    NSString *rtmpStr = @"rtmp://test.uplive.ks-cdn.com/live";
    NSString *devCode = [[[[[UIDevice currentDevice] identifierForVendor] UUIDString] lowercaseString] substringToIndex:3];
    _hostURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", rtmpStr, devCode]];
    NSLog(@"hostURL is %@", _hostURL);
}
- (void)setVideoChain{
    _ksyRGBOutput = [[KSYGPUPicOutput alloc] initWithOutFmt:kCVPixelFormatType_32BGRA];
    _ksyGpuToStr  = [[KSYGPUPicOutput alloc] initWithOutFmt:kCVPixelFormatType_32BGRA];
    
    [_kit.vCapDev addTarget:_ksyRGBOutput];
    _stFilter = [[KSYSTFilter alloc] initWithEAContext:[GPUImageContext sharedImageProcessingContext].context];
    _stFilter.delegate = self;
    __weak typeof(self) weakSelf = self;
    _ksyRGBOutput.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_stFilter processPixelBuffer:pixelbuffer time:timeInfo];
    };
    
    
    _inputTexture = [[GPUImageTextureInput alloc] init];
    _preview      = [[GPUImageView alloc] init];
    _preview.frame = self.view.frame;
    [self.view insertSubview:_preview atIndex:0];
    [_inputTexture addTarget:_preview];
    [_inputTexture addTarget:_ksyGpuToStr];
    
    
    _ksyGpuToStr.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_kit.streamerBase processVideoPixelBuffer:pixelbuffer timeInfo:timeInfo];
    };

}
- (void)setAudioChain{
    __weak typeof(self) weakSelf = self;
    _kit.aCapDev.audioProcessingCallback = ^(CMSampleBufferRef sampleBuffer){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_kit.streamerBase processAudioSampleBuffer:sampleBuffer];
        NSLog(@"streame state is %lu", (unsigned long)strongSelf->_kit.streamerBase.streamState);
    };
}
//遇到的问题：开启预览后很卡
- (IBAction)onCapture:(id)sender {
    if (!_kit.vCapDev.isRunning) {
        _kit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_kit.vCapDev startCameraCapture];
        [_kit.aCapDev startCapture];
    }
    else{
        [_kit.vCapDev stopCameraCapture];
        [_kit.aCapDev stopCapture];
    }
}

- (IBAction)onStream:(id)sender {
    if (_kit.streamerBase.streamState == KSYStreamStateIdle || _kit.streamerBase.streamState == KSYStreamStateError) {
        [_kit.streamerBase startStream:_hostURL];
    }
    else{
        [_kit.streamerBase stopStream];
    }
}
- (void)addObserver{
    
}
@end
