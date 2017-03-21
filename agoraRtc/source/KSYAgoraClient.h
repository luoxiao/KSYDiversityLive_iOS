//
//  KSYKitDemoVC.h
//  KSYGPUStreamerDemo
//
//  Created by yiqian on 6/23/16.
//  Copyright © 2016 ksyun. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>

@class AgoraRtcStats;

typedef void (^RTCVideoDataBlock)(CVPixelBufferRef pixelBuffer);
typedef void (^RTCAudioDataBlock)(void* buffer,int sampleRate,int samples,int bytesPerSample,int channels,int64_t pts);


@interface KSYAgoraClient:NSObject

-(instancetype)initWithAppId:(NSString *)appId
                    delegate:(id<AgoraRtcEngineDelegate>)delegate;

/*
 @abstract 是否静音
 */
@property (assign, nonatomic) BOOL isMuted;
/*
 @abstract 设置视频的profile，具体参看声网的定义
 */
@property (assign, nonatomic) AgoraRtcVideoProfile videoProfile;
/*
 @abstract 加入通道
 */
-(void)joinChannel:(NSString *)channelName;


@property(nonatomic, copy) void(^joinChannelBlock)(NSString* channel, NSUInteger uid, NSInteger elapsed);
/*
 @abstract 离开通道
 */
-(void)leaveChannel;

@property(nonatomic, copy) void(^leaveChannelBlock)(AgoraRtcStats* stat);
/*
 @abstract 发送视频数据到云端
 */
-(void)ProcessVideo:(CVPixelBufferRef)buf
           timeInfo:(CMTime)pts;

/*
 @abstract 远端视频数据回调
 */
@property (nonatomic, copy)RTCVideoDataBlock videoDataCallback;

/*
  @abstract 远端音频数据回调
 */
@property (nonatomic, copy)RTCAudioDataBlock remoteAudioDataCallback;

/*
 @abstract 本地音频数据回调
 */
@property (nonatomic, copy)RTCAudioDataBlock localAudioDataCallback;

@end
