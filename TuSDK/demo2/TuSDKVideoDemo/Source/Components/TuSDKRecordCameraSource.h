//
//  TuSDKRecordCameraSource.h
//  TuSDKVideoDemo
//
//  Created by Yanlin on 5/9/16.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "TuSDKFramework.h"

#pragma mark - TuSDKRecordCameraSourceDelegate
@class TuSDKRecordCameraSource;

/**
 *  录制事件代理
 */
@protocol TuSDKRecordCameraSourceDelegate <NSObject>

@optional

/**
 *  视频录制完成
 *
 *  @param result   TuSDKVideoResult 对象
 */
- (void)onMovieRecordCompleted:(TuSDKVideoResult *)result;

@end

#pragma mark - TuSDKRecordCameraSource

/**
 *  视频处理
 */
@interface TuSDKRecordCameraSource : NSObject

/**
 *  事件代理
 */
@property (nonatomic) id<TuSDKRecordCameraSourceDelegate>   delegate;

/**
 *  运行状态
 */
@property (nonatomic, readwrite, assign) BOOL isRunning;

/** 相机视图 */
@property (nonatomic, readonly) UIView *cameraView;

/**
 *  摄像头前后方向 (默认为后置优先)
 */
@property (nonatomic) AVCaptureDevicePosition avPostion;

/**
 *  摄像头分辨率模式 (默认: AVCaptureSessionPresetHigh)
 *  @see AVCaptureSession for acceptable values
 */
@property (nonatomic, copy) NSString *sessionPreset;

/**
 *  相机画幅
 */
@property (nonatomic) NSUInteger cameraSizeType;

/**
 *  输出画面分辨率，默认原始采样尺寸输出。
 *  如果设置了输出尺寸，则对画面进行等比例缩放，必要时进行裁剪，保证输出尺寸和预设尺寸一致。
 */
@property (nonatomic) CGSize outputSize;

/**
 *  初始化
 *
 *  @param cameraPosition 默认摄像头 前|后
 *  @param view           预览视图
 *
 *  @return
 */
- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition
                            cameraView:(UIView *)view;

/**
 *  初始化
 *
 *  @param cameraPosition 默认摄像头 前|后
 *  @param view           预览视图
 *  @param outputSize     视频输出尺寸
 *
 *  @return
 */
- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition
                            cameraView:(UIView *)view
                             videoSize:(CGSize)outputSize;

/**
 *  切换前/后摄像头
 */
- (void)toggleCamera;

/**
 *  销毁对象
 */
- (void)destroy;

/**
 *  切换滤镜
 *
 *  可查看 TuSDK.bundle/others/lsq_tusdk_configs.json ，找到 lsq_filter_SkinNature, lsq_filter_SkinPink ...，其中 SkinNature, SkinPink 即滤镜代码
 *
 *  @param code 滤镜代码
 */
- (void)switchFilterCode:(NSString *)code;

/**
 *  启动相机，开始预览
 */
- (void)startCamera;

/**
 *  停止预览，如需再次启动，请调用 startCamera
 */
- (void)stopCamera;

/**
 *  开始录制
 */
- (void)startRecording;

/**
 *  停止
 */
- (void)stopRecording;

/**
 *  录制状态
 *
 *  @return
 */
- (BOOL)isRecording;

/**
 *  设置相机预览帧率
 *
 *  @param fps 帧率
 */
- (void)setFramerate:(NSUInteger)fps;

/**
 *  获取当前闪光灯模式
 *
 *  @return
 */
- (AVCaptureFlashMode)getFlashMode;

/**
 *  设置闪光灯模式
 *  @see AVCaptureFlashMode
 *
 *  @param flashMode 设置闪光灯模式
 */
-(void)setFlashMode:(AVCaptureFlashMode)flashMode;

#pragma mark - live sticker
/**
 *  显示动态贴纸
 *
 *  @param stickerGroup 贴纸组对象
 */
- (void)showGroupSticker:(TuSDKPFStickerGroup *)stickerGroup;

/**
 *  清除动态贴纸
 *
 */
- (void)removeAllLiveSticker;

/**
 *  动态贴纸组是否正在使用
 */
- (BOOL)isGroupStickerUsed:(TuSDKPFStickerGroup *)stickerGroup;
@end

