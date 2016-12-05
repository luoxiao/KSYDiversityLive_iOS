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
#import <libksygpulive/KSYGPUBeautifyPlusFilter.h>
#import "KSYSTStreamerKit.h"


#define CHECK_LICENSE_WITH_PATH 1

@interface KSYSTController ()<KSYSTFilterDelegate>{
//    KSYGPUStreamerKit    *_kit;
    GPUImageTextureInput *_inputTexture;
    KSYSTFilter          *_stFilter;
    GPUImageView         *_preview;
    NSURL                *_hostURL;
    KSYGPUCamera         *_vCapDev;
    KSYAUAudioCapture    *_aCapDev;
    KSYGPUPicOutput      *_ksyRGBOutput;
    KSYGPUPicOutput      *_ksyGpuToStr;
    KSYStreamerBase      *_streameBase;
    KSYAudioMixer        *_stAudioMix;
    KSYSTStreamerKit     *_stKit;
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
    //set video path
//    [self setVideoChain];
    //set video chain
//    [self setAudioChain];
}
- (void)setCapture{
    _stKit.capPreset = AVCaptureSessionPreset640x480;
    _stKit.previewDimension = CGSizeMake(640, 360);
    _stKit.streamDimension = CGSizeMake(640, 360);
    _stKit.videoFPS       = 15;
    _stKit.cameraPosition = AVCaptureDevicePositionFront;
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
    NSString *rtmpStr = @"rtmp://test.uplive.ks-cdn.com/live/ksyun";
    _hostURL = [NSURL URLWithString:rtmpStr];
}
- (void)setVideoChain{
    //preview
    _preview      = [[GPUImageView alloc] init];
    _preview.frame = self.view.frame;
    [self.view insertSubview:_preview atIndex:0];
    //texture ---> buffer
    _ksyRGBOutput = [[KSYGPUPicOutput alloc] initWithOutFmt:kCVPixelFormatType_32BGRA];
    _ksyGpuToStr  = [[KSYGPUPicOutput alloc] initWithOutFmt:kCVPixelFormatType_32BGRA];
    
    //beautify filter
    //    _buautiFilter = [[KSYGPUBeautifyPlusFilter alloc] init];
    //    [_vCapDev addTarget:_buautiFilter];
    [_vCapDev addTarget:_ksyRGBOutput];
    
    //sticker filter
    _stFilter = [[KSYSTFilter alloc] initWithEAContext:[GPUImageContext sharedImageProcessingContext].context];
    _stFilter.delegate = self;
    
    //call back
    __weak typeof(self) weakSelf = self;
    _ksyRGBOutput.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_stFilter processPixelBuffer:pixelbuffer time:timeInfo];
    };
    
    _ksyGpuToStr.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_stKit.streamerBase processVideoPixelBuffer:pixelbuffer timeInfo:timeInfo];
        
    };
    
}
- (void)setAudioChain{
    _stAudioMix = [[KSYAudioMixer alloc] init];
    __weak typeof(self) weakSelf = self;
    _aCapDev.audioProcessingCallback = ^(CMSampleBufferRef sampleBuffer){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_stAudioMix processAudioSampleBuffer:sampleBuffer of:0];
        //        [strongSelf->_kit.streamerBase processAudioSampleBuffer:sampleBuffer];
        NSLog(@"streame state is %lu \n encodeVKbps is %f \n encodeAKbps is %f", (unsigned long)strongSelf->_stKit.streamerBase.streamState, strongSelf->_stKit.streamerBase.encodeVKbps,strongSelf->_stKit.streamerBase.encodeAKbps);
    };
    _stAudioMix.audioProcessingCallback = ^(CMSampleBufferRef buf){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_stKit.streamerBase processAudioSampleBuffer:buf];
    };
    // mixer 的主通道为麦克风,时间戳以main通道为准
    _stAudioMix.mainTrack = 0;
    [_stAudioMix setTrack:0 enable:YES];
}
//遇到的问题：开启预览后很卡
- (IBAction)onCapture:(id)sender {
    if (!_stKit.vCapDev.isRunning) {
        _stKit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_stKit startPreview:self.view];
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
