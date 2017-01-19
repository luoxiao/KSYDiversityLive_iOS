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

static int i = 0;
static int count = 74;

@implementation KSYSTKit
- (instancetype)init {
    if (self = [super init]) {
        _ksySTFitler = [[KSYSTFilter alloc]initWithAppid:@"7f76ce6bd292444b9368a7ba436c39fd" appKey:@"fa8e3603044c41ff8dbbd5531624ab0d"];
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
    [_ksySTFitler changeSticker:i onSuccess:nil onFailure:nil onProgress:nil];
    i = i + 1;
    i = i%count;
}
@end
