//
//  KSYSTStreamerKit.m
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/24.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import "KSYSTStreamerKit.h"

@interface KSYSTStreamerKit()<KSYSTFilterDelegate>{
    dispatch_queue_t _capDev_q;
    NSLock   *       _quitLock;  // ensure capDev closed before dealloc
    GPUImagePicture *_textPic;
    CGFloat _previewRotateAng;
}
@end

@implementation KSYSTStreamerKit

/**
 @abstract 初始化方法
 @discussion 创建带有默认参数的 kit，不会打断其他后台的音乐播放
 
 @warning kit只支持单实例推流，构造多个实例会出现异常
 */
- (instancetype) initWithDefaultCfg {
    return [self initInterrupt:NO];
}

/**
 @abstract 初始化方法
 @discussion 创建带有默认参数的 kit，会打断其他后台的音乐播放
 
 @warning kit只支持单实例推流，构造多个实例会出现异常
 */
- (instancetype) initWithInterruptCfg {
    return [self initInterrupt:YES];
}

- (instancetype)initInterrupt:(BOOL)iInter{
    self = [super init];
    _quitLock = [[NSLock alloc] init];
    _capDev_q = dispatch_queue_create("com.ksyun.queue", <#dispatch_queue_attr_t  _Nullable attr#>)
    _ksyStFilter = [[KSYSTFilter alloc] initWithEAContext:[GPUImageContext sharedImageProcessingContext].context];
    _ksyStFilter.delegate = self;
    _texToBuf = [[KSYGPUPicOutput alloc] init];
    //组装视频通道
    [self setupStVideoPath];
    // 组装音频通道
    [self setupStAudioPath];
    return self;
}
- (instancetype)init {
    return [self initWithDefaultCfg];
}
- (void)dealloc{
    _ksyStFilter = nil;
}
//set filter
- (void)setupStFilter:(GPUImageOutput<GPUImageInput> *)filter{
    if (_texInput == nil) {
        return;
    }
    //采集的图像先经过前处理
    [_texInput removeAllTargets];
    GPUImageOutput *src = _texInput;
    if (self.cropfilter) {
        [self.cropfilter removeAllTargets];
        [_texInput addTarget:self.cropfilter];
        src = self.cropfilter;
    }
    if (self.filter) {
        [self.filter removeAllTargets];
        [src addTarget:self.filter];
        src = self.filter;
    }
    //组装图层
    // 组装图层
    self.vPreviewMixer.masterLayer = self.cameraLayer;
    self.vStreamMixer.masterLayer = self.cameraLayer;
    [self addStPic:src ToMixerAt:self.cameraLayer];
    [self addStPic:self.logoPic ToMixerAt:self.logoPicLayer];
    [self addStPic:_textPic ToMixerAt:self.logoTxtLayer];
    // 混合后的图像输出到预览和推流
    [self.vPreviewMixer removeAllTargets];
    [self.vPreviewMixer addTarget:self.preview];
    
    [self.vStreamMixer  removeAllTargets];
    [self.vStreamMixer  addTarget:self.gpuToStr];
    // 设置镜像
    [self setPreviewMirrored:self.previewMirrored];
    [self setStreamerMirrored:self.streamerMirrored];
}
- (void)addStPic:(GPUImageOutput *)pic ToMixerAt:(NSInteger)idx{
    if (pic == nil) {
        return;
    }
    [pic removeAllTargets];
    KSYGPUPicMixer *vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for(int i = 0; i < 2; i++){
        [vMixer[i] clearPicOfLayer:idx];
        [pic addTarget:vMixer[i] atTextureLocation:idx];
    }
}
- (void)setupStVideoPath{
    [self.vCapDev addTarget:_texToBuf];
    //textToBuffer --> stFilter
    __weak typeof(self) weakSelf = self;
    _texToBuf.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        [weakSelf.ksyStFilter processPixelBuffer:pixelbuffer time:timeInfo];
    };
    
    [self setupStFilter:self.filter];
    
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
}
- (void) mixAudio:(CMSampleBufferRef)buf to:(int)idx{
    if (![self.streamerBase isStreaming]){
        return;
    }
    [self.aMixer processAudioSampleBuffer:buf of:idx];
}
// 组装声音通道
- (void) setupStAudioPath {
    __weak typeof(self) weakSelf = self;
    //1. 音频采集, 语音数据送入混音器
    self.aCapDev.audioProcessingCallback = ^(CMSampleBufferRef buf){
        [weakSelf mixAudio:buf to:weakSelf.micTrack];
    };
    //2. 背景音乐播放,音乐数据送入混音器
    self.bgmPlayer.audioDataBlock = ^(CMSampleBufferRef buf){
        [weakSelf mixAudio:buf to:weakSelf.bgmTrack];
    };
    // 混音结果送入streamer
    self.aMixer.audioProcessingCallback = ^(CMSampleBufferRef buf){
        if (![weakSelf.streamerBase isStreaming]){
            return;
        }
        [weakSelf.streamerBase processAudioSampleBuffer:buf];
    };
    // mixer 的主通道为麦克风,时间戳以main通道为准
    self.aMixer.mainTrack = self.micTrack;
    [self.aMixer setTrack:self.micTrack enable:YES];
    [self.aMixer setTrack:self.bgmTrack enable:YES];
}
@end
