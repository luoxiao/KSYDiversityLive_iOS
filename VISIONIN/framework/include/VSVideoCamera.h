//
//  VSRexContext.h
//  CaptureDemo
//
//  Created by Rex on 15/11/30.
//  Copyright © 2015年 Fantasist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

//Delegate Protocal for Face Detection.

@protocol VSSampleDelegate <NSObject>
// 原始音频
-(void)willOutputAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;
// 原始视频
-(void)willOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
// 处理后视频原始数据
-(void)didCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

@protocol VSFaceDelegate <NSObject>
//0/1:左眼；2/3:右眼；4/5:左脸框；6/7:右脸眶；8/9:额头；10/11：嘴唇下方(暂无意义); 12/13：两眼中间
-(void)faceWithPoints:(int[][2])points count:(int)count;
@end


@interface VSVideoCamera : NSObject<VSSampleDelegate>

@property(nonatomic, assign) UIView* parentView;
@property(nonatomic, assign)CGSize size;
@property(nonatomic, retain)id<VSSampleDelegate> sampleDelegate;
@property(nonatomic, retain)id<VSFaceDelegate> faceDelegate;

-(id)initWithSessionPreset:(NSString *)sessionPreset position:(AVCaptureDevicePosition)position view:(UIView*)view;
-(id)initWithSessionPreset:(NSString *)sessionPreset position:(AVCaptureDevicePosition)position viewWithoutDisplay:(UIView*)view;
-(void)startCameraCapture;
// 暂未测试，压缩为mp4，name不带后缀
-(void)startRecode:(NSString*)path name:(NSString*)name;
-(void)stopRecode;
// 人脸跟踪
-(void)startFaceTracking;
-(void)stopFaceTracking;
// 切换摄像头
-(void)rotateCamera;
-(void*)videoCamera;
-(AVCaptureDevicePosition)cameraPosition;
// 建议值：0.5，范围:0-1.0
-(void)setSmoothLevel:(float)level;
// 建议值：1.1-1.5
-(void)setBrightenLevel:(float)level;
// 相机设备
-(AVCaptureDevice*)captureDevice;
+(VSVideoCamera*)sharedInstance;
@end