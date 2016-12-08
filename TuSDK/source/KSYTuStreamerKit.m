//
//  KSYTTStreamerKit.m
//  KSYTTStreamer
//
//  Created by 孙健 on 2016/12/8.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import "KSYTuStreamerKit.h"

@interface KSYTuStreamerKit()<KSYCameraSourceDelegate>

@end

@implementation KSYTuStreamerKit

- (instancetype)initWithDefault:(UIView *)view{
    self = [super init];
    _streamerBase = [[KSYStreamerBase alloc] initWithDefaultCfg];
    _audioCapDev = [[KSYAUAudioCapture alloc] init];
    _aMixer = [[KSYAudioMixer alloc] init];
    _preview = [[UIView alloc] initWithFrame:view.frame];
    [view insertSubview:_preview atIndex:1];
    _cameraSource = [[KSYCameraSource alloc] initWithCameraPosition:AVCaptureDevicePositionFront cameraView:_preview];
    _cameraSource.delegate = self;
    _micTrack = 1;
    [self setAudioPath];
    return self;
}

- (void)startCapture{
    [_cameraSource startRunning];
    [_audioCapDev startCapture];
}
- (void)stopCapture{
    if (!_cameraSource) {
        return;
    }
    [_cameraSource stopRunning];
    [_audioCapDev stopCapture];
}
- (void)setAudioPath{
    __weak typeof(self) weakSelf = self;
    _audioCapDev.audioProcessingCallback = ^(CMSampleBufferRef buf){
        [weakSelf mixAudioBuffer:buf to:weakSelf.micTrack];
    };
    _aMixer.audioProcessingCallback = ^(CMSampleBufferRef buf){
        [weakSelf.streamerBase processAudioSampleBuffer:buf];
    };
    _aMixer.mainTrack = _micTrack;
    [_aMixer setTrack:_micTrack enable:YES];
}
- (void)mixAudioBuffer:(CMSampleBufferRef)buffer to:(int)track{
    if (![_streamerBase isStreaming]) {
        return;
    }
    [_aMixer processAudioSampleBuffer:buffer of:_micTrack];
}
#pragma mark - KSYCameraSourceDelegate
- (void)capSource:(KSYCameraSource *)source
      pixelBuffer:(CVPixelBufferRef)pixelBuffer
             time:(CMTime)frameTime{
    [_streamerBase processVideoPixelBuffer:pixelBuffer timeInfo:frameTime];
}
@end
