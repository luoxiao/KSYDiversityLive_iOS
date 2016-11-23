//
//  ViewController.m
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/21.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import "ViewController.h"
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

@interface ViewController ()<KSYSTFilterDelegate>{
    KSYGPUStreamerKit    *_kit;
    GPUImageTextureInput *_inputTexture;
    KSYSTFilter          *_stFilter;
    GPUImageView         *_preview;
}
@end
    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //initial ksystreamerKit
    _kit = [[KSYGPUStreamerKit alloc] initWithDefaultCfg];
    [self setCapture];
}
- (void)setCapture{
    _kit.capPreset = AVCaptureSessionPreset1280x720;
    _kit.previewDimension = CGSizeMake(1280, 720);
    _kit.vCapDev.frameRate = 15;
    _kit.cameraPosition = AVCaptureDevicePositionFront;
    _kit.gpuOutputPixelFormat = kCVPixelFormatType_32BGRA;
    KSYGPUPicOutput *picOut = [[KSYGPUPicOutput alloc] initWithOutFmt:kCVPixelFormatType_32BGRA];
    [_kit.vCapDev addTarget:picOut];
    _stFilter = [[KSYSTFilter alloc] initWithEAContext:[GPUImageContext sharedImageProcessingContext].context];
    _stFilter.delegate = self;
    _inputTexture = [[GPUImageTextureInput alloc] init];
    _preview = [[GPUImageView alloc] init];
    _preview.frame = self.view.frame;
    [self.view insertSubview:_preview atIndex:0];
    [_inputTexture addTarget:_preview];
    __weak typeof(self) weakSelf = self;
    picOut.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_stFilter processPixelBuffer:pixelbuffer time:timeInfo];
    };
    _kit.vCapDev.videoProcessingCallback = ^(CMSampleBufferRef sampleBuffer){
        __strong typeof(self) strongSelf = weakSelf;
        NSLog(@"_kit.frameRate %d", strongSelf->_kit.vCapDev.frameRate);
    };
}
//KSYSTDelegate
- (void)videoOutputWithTexture:(unsigned int)textOutput
                          size:(CGSize)size
                          time:(CMTime)timeInfo
{
    _inputTexture = [[GPUImageTextureInput alloc] initWithTexture:textOutput
                                                                 size:size];
    [_inputTexture addTarget:_preview];
    [_inputTexture processTextureWithFrameTime:timeInfo];
    glDeleteTextures(1, &textOutput);
}

- (void)setStream{
    
}
//遇到的问题：开启预览后很卡
- (IBAction)onCapture:(id)sender {
    if (!_kit.vCapDev.isRunning) {
        _kit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_kit.vCapDev startCameraCapture];
    }
}

- (IBAction)onStream:(id)sender {
}
- (void)addObserver{
    
}
@end
