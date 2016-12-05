//
//  KSYSTStreamerKit.m
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/24.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import "KSYSTStreamerKit.h"

@interface KSYSTStreamerKit()<KSYSTFilterDelegate>{
    KSYGPUPicOutput *_texToBuf;
    GPUImageTextureInput *_texInput;
    GPUImagePicture *_textPic;
}
@end

@implementation KSYSTStreamerKit

- (instancetype)initWithDefaultCfg{
    self = [super initWithDefaultCfg];
    if (self) {
        _ksyStFilter = [[KSYSTFilter alloc] initWithEAContext:[GPUImageContext sharedImageProcessingContext].context];
        _ksyStFilter.delegate = self;
        //default init
        _texToBuf = [[KSYGPUPicOutput alloc] init];
        _stFilter = [[GPUImageFilter alloc] init];
        _texMix   = [[KSYGPUPicMixer alloc] init];
        [self setupStVideoPath];
    }
    return self;
}
- (void)dealloc{
    _ksyStFilter = nil;
}
//set filter
- (void)setupStFilter:(GPUImageOutput<GPUImageInput> *)filter{
    _stFilter = filter;
    if (self.vCapDev == nil) {
        return;
    }
    //采集的图像先经过前处理
    [self.vCapDev removeAllTargets];
    GPUImageOutput *src = self.vCapDev;
    if (self.cropfilter) {
        [self.cropfilter removeAllTargets];
        [src addTarget:self.cropfilter];
        src = self.cropfilter;
    }
    if (_stFilter) {
        [_stFilter removeAllTargets];
        [src addTarget:_stFilter];
        src = _stFilter;
    }
    //组装图层
    _texMix.masterLayer = self.cameraLayer;
    [self addStPic:src ToMixerAt:self.cameraLayer];
    [self addStPic:self.logoPic ToMixerAt:self.logoPicLayer];
    [self addStPic:_textPic ToMixerAt:self.logoTxtLayer];
    //混合后的图像输出到texToBuffer
    [_texMix removeAllTargets];
    [_texMix addTarget:_texToBuf];
}
- (void)addStPic:(GPUImageOutput *)pic ToMixerAt:(NSInteger)idx{
    if (pic == nil) {
        return;
    }
    [pic removeAllTargets];
    [_texMix clearPicOfLayer:idx];
    [pic addTarget:_texMix atTextureLocation:idx];
}
- (void)setupStVideoPath{
    [self setPreviewMirrored:self.previewMirrored];
    [self setStreamerMirrored:self.streamerMirrored];
    
    [self setupStFilter:_stFilter];
    //textToBuffer --> stFilter
    __weak typeof(self) weakSelf = self;
    _texToBuf.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        [weakSelf.ksyStFilter processPixelBuffer:pixelbuffer time:timeInfo];
    };
    //clear sub texture
    [self.vPreviewMixer removeAllTargets];
    [self.vStreamMixer removeAllTargets];
    
    self.gpuToStr.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo){
        if (![weakSelf.streamerBase isStreaming]) {
            return ;
        }
        [weakSelf.streamerBase processVideoPixelBuffer:pixelBuffer timeInfo:timeInfo];
    };
}
//ksyStFilter delegate
- (void)videoOutputWithTexture:(unsigned int)textOutput size:(CGSize)size time:(CMTime)timeInfo{
    _texInput = [[GPUImageTextureInput alloc] initWithTexture:textOutput size:size];
    [_texInput addTarget:self.preview];
    [_texInput addTarget:self.gpuToStr];
}
@end
