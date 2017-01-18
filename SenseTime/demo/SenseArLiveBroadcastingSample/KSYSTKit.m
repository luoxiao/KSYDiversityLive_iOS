//
//  KSYSTKit.m
//  SenseArLiveBroadcastingSample
//
//  Created by 孙健 on 2017/1/17.
//  Copyright © 2017年 SenseTime. All rights reserved.
//

#import "KSYSTKit.h"
#import "KSYSTFilter.h"
@interface KSYSTKit (){
    KSYSTFilter *_ksySTFitler;
}
@end

@implementation KSYSTKit
- (instancetype)init {
    if (self = [super init]) {
        _ksySTFitler = [[KSYSTFilter alloc]init];
    }
    return self;
}
- (void)setupFilter:(GPUImageOutput<GPUImageInput> *)filter{
    [self.capToGpu addTarget:_ksySTFitler];
    [_ksySTFitler addTarget:self.preview];
    [_ksySTFitler addTarget:self.gpuToStr];
}
// 组装视频通道
- (void) setupVideoPath {
    __weak KSYGPUStreamerKit *kit = self;
    self.vCapDev.videoProcessingCallback = ^(CMSampleBufferRef buf) {
        [self.capToGpu processSampleBuffer:buf];
    };
    
    self.gpuToStr.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        if (![kit.streamerBase isStreaming]) {
            return ;
        }
        [kit.streamerBase processVideoPixelBuffer:pixelbuffer timeInfo:timeInfo];
        NSLog(@"%@",NSStringFromCGSize([kit captureDimension]));
    };
}
- (void)stickerChanger{
    [_ksySTFitler changeSticker];
    NSLog(@"click sticer change");
}
- (void)metarialsDown{
    [_ksySTFitler downLoadMetarials];
}
@end
