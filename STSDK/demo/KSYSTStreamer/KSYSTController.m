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
//录制音视频
#import <AVFoundation/AVFoundation.h>

#define CHECK_LICENSE_WITH_PATH 1

@interface KSYSTController ()<KSYSTFilterDelegate>{
    KSYGPUStreamerKit    *_kit;
    GPUImageTextureInput *_inputTexture;
    KSYSTFilter          *_stFilter;
    GPUImageView         *_preview;
    NSURL                *_hostURL;
    KSYGPUCamera         *_vCapDev;
    KSYAUAudioCapture    *_aCapDev;
    KSYGPUPicOutput      *_ksyRGBOutput;
    KSYGPUPicOutput      *_ksyGpuToStr;
    KSYStreamerBase      *_streameBase;
    KSYGPUBeautifyPlusFilter *_buautiFilter;
    AVAssetWriter        *_avWriter;
    AVAssetWriterInput   *_videoWriterInput;
    AVAssetWriterInput   *_audioWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *_adaptor;
    KSYAudioMixer        *_stAudioMix;
}
@end
    
@implementation KSYSTController
- (void)initVideoAudioWriter{
    //分辨率
    CGSize size = CGSizeMake(480, 320);
    //保存路径
    NSString *savePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    NSError *error = nil;
    //若存在此路径就删除
    unlink([savePath UTF8String]);
    //初始化音视频写入
    _avWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:savePath]
                                          fileType:AVFileTypeQuickTimeMovie
                                             error:&error];
    NSParameterAssert(_avWriter);
    if (error) {
        NSLog(@"error = %@", [error localizedDescription]);
        return;
    }
    
    //配置信息
    NSDictionary *videoCompressionProps = @{AVVideoAverageBitRateKey : [NSNumber numberWithDouble:128.0*1024.0]};
    NSDictionary *videoSettings = @{AVVideoCodecKey:AVVideoCodecH264,
                                    AVVideoWidthKey : [NSNumber numberWithInt:size.width],
                                    AVVideoHeightKey: [NSNumber numberWithInt:size.height],
                                    AVVideoCompressionPropertiesKey:videoCompressionProps};
    //初始化视频输入
    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                           outputSettings:videoSettings];
    NSParameterAssert(_videoWriterInput);
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput
                                                                                sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(_videoWriterInput);
    NSParameterAssert([_avWriter canAddInput:_videoWriterInput]);
    
    if ([_avWriter canAddInput:_videoWriterInput]) {
        NSLog(@"I can add this input");
    }else{
        NSLog(@"I can't add this input");
    }
    
    //add audio input
    AudioChannelLayout acl;
    
    bzero(&acl, sizeof(acl));
    
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
    NSDictionary *audioOutputSettings = nil;
    
    audioOutputSettings = @{AVFormatIDKey       : [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
                            AVEncoderBitRateKey : [NSNumber numberWithInt:64000],
                            AVSampleRateKey     : [NSNumber numberWithFloat:44100.0],
                            AVNumberOfChannelsKey: [NSNumber numberWithInt:1],
                            AVChannelLayoutKey: [NSData dataWithBytes:&acl length:sizeof(acl)]};
    _audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                           outputSettings:audioOutputSettings];
    
    _audioWriterInput.expectsMediaDataInRealTime = YES;
    
    [_avWriter addInput:_audioWriterInput];
    [_avWriter addInput:_videoWriterInput];
}
- (IBAction)startWriter:(id)sender {
    if (_avWriter.status != AVAssetWriterStatusWriting) {
        [_avWriter startWriting];
    }
}
- (IBAction)stopWriter:(id)sender {
    [_avWriter finishWritingWithCompletionHandler:^{
        NSLog(@"writer finished");
    }];
}

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
    //init writer
    [self initVideoAudioWriter];
}
- (void)setCapture{
    _vCapDev = [[KSYGPUCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
    _vCapDev.frameRate = 30;
    //TODO:
//    _kit.capPreset = AVCaptureSessionPreset640x480;
//    _kit.previewDimension = CGSizeMake(640, 360);
//    _kit.streamDimension  = CGSizeMake(640, 360);
//    _kit.vCapDev.frameRate = 15;
//    _kit.cameraPosition = AVCaptureDevicePositionFront;
    _aCapDev = [[KSYAUAudioCapture alloc] init];
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
    _streameBase = [[KSYStreamerBase alloc] initWithDefaultCfg];
    _streameBase.videoFPS = 30;
    //set stream url from uuid
    NSString *rtmpStr = @"rtmp://test.uplive.ks-cdn.com/live/ksyun";
//    NSString *devCode = [[[[[UIDevice currentDevice] identifierForVendor] UUIDString] lowercaseString] substringToIndex:3];
//    _hostURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", rtmpStr, devCode]];
    _hostURL = [NSURL URLWithString:rtmpStr];
//    NSLog(@"hostURL is %@", _hostURL);
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
    _vCapDev.videoProcessingCallback = ^(CMSampleBufferRef sampleBuffer){
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf->_videoWriterInput isReadyForMoreMediaData]) {
            [strongSelf->_videoWriterInput appendSampleBuffer:sampleBuffer];
        }
    };
    
    _ksyRGBOutput.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_stFilter processPixelBuffer:pixelbuffer time:timeInfo];
    };
    
    _ksyGpuToStr.videoProcessingCallback = ^(CVPixelBufferRef pixelbuffer, CMTime timeInfo){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_kit.streamerBase processVideoPixelBuffer:pixelbuffer timeInfo:timeInfo];
        
    };

}
- (void)setAudioChain{
    _stAudioMix = [[KSYAudioMixer alloc] init];
    __weak typeof(self) weakSelf = self;
    _aCapDev.audioProcessingCallback = ^(CMSampleBufferRef sampleBuffer){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_stAudioMix processAudioSampleBuffer:sampleBuffer of:0];
//        [strongSelf->_kit.streamerBase processAudioSampleBuffer:sampleBuffer];
        NSLog(@"streame state is %lu \n encodeVKbps is %f \n encodeAKbps is %f", (unsigned long)strongSelf->_kit.streamerBase.streamState, strongSelf->_kit.streamerBase.encodeVKbps,strongSelf->_kit.streamerBase.encodeAKbps);
//        static int frame = 0;
//        CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//        
//        if (frame == 0 && strongSelf->_avWriter.status != AVAssetWriterStatusWriting) {
//            [strongSelf->_avWriter startWriting];
//            [strongSelf->_avWriter startSessionAtSourceTime:lastSampleTime];
//            if ([strongSelf->_audioWriterInput isReadyForMoreMediaData]) {
//                [strongSelf->_audioWriterInput appendSampleBuffer:sampleBuffer];
//            }
//        }
    };
    _stAudioMix.audioProcessingCallback = ^(CMSampleBufferRef buf){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_kit.streamerBase processAudioSampleBuffer:buf];
    };
    // mixer 的主通道为麦克风,时间戳以main通道为准
    _stAudioMix.mainTrack = 0;
    [_stAudioMix setTrack:0 enable:YES];
}
//遇到的问题：开启预览后很卡
- (IBAction)onCapture:(id)sender {
    if (!_vCapDev.isRunning) {
        _kit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_vCapDev startCameraCapture];
        [_aCapDev startCapture];
    }
    else{
        [_vCapDev stopCameraCapture];
        [_aCapDev stopCapture];
        [_avWriter finishWritingWithCompletionHandler:^{
            NSLog(@"writer finished");
        }];
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
- (IBAction)sticker:(id)sender {
    [_stFilter stChangeSicker];
}
- (void)addObserver{
    
}
@end
