//
//  KSYSTStreamerKit.m
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/24.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import "KSYSTStreamerKit.h"

@interface KSYSTStreamerKit()<KSYSTFilterDelegate>{
}
@end

@implementation KSYSTStreamerKit
- (void)dealloc{
    _ksyStFilter = nil;
    _rgbOutput  = nil;
    [_textInput  removeAllTargets];
}
- (instancetype) initWithDefaultCfg {
    _ksyStFilter = [[KSYSTFilter alloc] initWithEAContext:[GPUImageContext sharedImageProcessingContext].context];
    _ksyStFilter.delegate = self;
    _rgbOutput = [[KSYGPUPicOutput alloc] init];
    _textInput = [[GPUImageTextureInput alloc] init];
    return [super initWithDefaultCfg];
}
- (instancetype)init {
    return [self initWithDefaultCfg];
}
// 组装视频通道
- (void) setupVideoPath {
     __weak typeof(self) weakSelf = self;
    self.vCapDev.videoProcessingCallback = ^(CMSampleBufferRef buf){
        [weakSelf.capToGpu processSampleBuffer:buf];
        if ( weakSelf.videoProcessingCallback ){
            weakSelf.videoProcessingCallback(buf);
        }
    };
    [self.capToGpu addTarget:_rgbOutput];
    //textToBuffer --> stFilter
    _rgbOutput.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        [weakSelf.ksyStFilter processPixelBuffer:pixelbuffer time:timeInfo];
    };
    
    self.gpuToStr.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo){
        if (![weakSelf.streamerBase isStreaming]) {
            return ;
        }
        [weakSelf.streamerBase processVideoPixelBuffer:pixelBuffer timeInfo:timeInfo];
        NSLog(@"%@",NSStringFromCGSize([weakSelf captureDimension]));
    };
}
//set filter
- (void)setupFilter:(GPUImageOutput<GPUImageInput> *)filter{
    if (self.cropfilter) {
        [self.cropfilter addTarget:self.preview];
        [self.cropfilter addTarget:self.gpuToStr];
    }
}
//ksyStFilter delegate
- (void)videoOutputWithTexture:(unsigned int)textOutput size:(CGSize)size time:(CMTime)timeInfo{
    _textInput = [[GPUImageTextureInput alloc] initWithTexture:textOutput size:size];
    [_textInput addTarget:self.cropfilter];
    [_textInput addTarget:self.cropfilter];
    [_textInput processTextureWithFrameTime:timeInfo];
    glDeleteTextures(1, &textOutput);
}

@end
