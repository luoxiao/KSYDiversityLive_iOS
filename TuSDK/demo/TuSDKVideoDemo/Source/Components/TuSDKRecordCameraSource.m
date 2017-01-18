//
//  TuSDKRecordCameraSource.m
//  TuSDKVideoDemo
//
//  Created by Yanlin on 5/9/16.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import "TuSDKRecordCameraSource.h"
#import "FilterConfigView.h"

@interface TuSDKRecordCameraSource() <TuSDKRecordVideoCameraDelegate>
{
    // 相机对象
    TuSDKRecordVideoCamera *_camera;
    // 当前比例类型
    lsqRatioType _currentRatioType;
    // 当前屏幕比例
    lsqRatioType _screenRatioType;
    // 当前闪光灯模式
    AVCaptureFlashMode _flashMode;
    
    // 滤镜参数配置
    FilterConfigView *_filterConfigView;
}

@end

@implementation TuSDKRecordCameraSource

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
{
    return [self initWithCameraPosition:cameraPosition cameraView:view videoSize:CGSizeZero];
}

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
{
    self = [super init];
    if (self) {
        _avPostion = cameraPosition;
        _cameraView = view;
        
        _outputSize = outputSize;
        
        //
        _flashMode = AVCaptureFlashModeAuto;
    }
    
    return self;
}

/**
 *  摄像头分辨率模式 (默认：AVCaptureSessionPresetHigh)
 *  @see AVCaptureSession for acceptable values
 */
-(NSString *)sessionPreset;
{
    if (!_sessionPreset) {
        _sessionPreset = AVCaptureSessionPresetHigh;
    }
    return _sessionPreset;
}

// 开始启动相机
-(void)startCamera;
{
    [self destoryCamera];
    
    // 启动摄像头
    _camera = [TuSDKRecordVideoCamera initWithSessionPreset:self.sessionPreset
                                           cameraPosition:self.avPostion
                                               cameraView:self.cameraView];
    
    
    // 设置委托
    _camera.videoDelegate = self;
    
    // 配置相机参数
    
    // 禁用持续自动对焦
    _camera.disableContinueFoucs = NO;
    
    if (_cameraSizeType == 2)
    {
        // 预览视图和输出尺寸比例一致，所见即所得
        _camera.cameraViewRatio = 1.0f;
        _camera.outputSize = CGSizeMake(640, 640);
    }
    else if (_cameraSizeType == 1)
    {
        // 预览视图和输出尺寸比例一致，所见即所得
        _camera.cameraViewRatio = 1.0f;
        
        _camera.outputSize = CGSizeMake(640, 640);
    }
    else
    {
        // 视频视图显示比例 (默认：0， 0 <= mRegionRatio, 当设置为0时全屏显示)
        // 0 全屏 | 1:1 正方形 | 2:3 | 3:4 | 9:16
        _camera.cameraViewRatio = 0;
        
        /**
         *  输出画面分辨率，默认原始采样尺寸输出。
         *  如果设置了输出尺寸，则对画面进行等比例缩放，必要时进行裁剪。
         */
        // _camera.outputSize = _outputSize;
    }
    
    // 视频覆盖区域颜色 (默认：[UIColor blackColor])
    _camera.regionViewColor = [UIColor blackColor];
    // 禁用前置摄像头自动水平镜像 (默认: NO，前置摄像头拍摄结果自动进行水平镜像)
    _camera.disableMirrorFrontFacing = NO;
    
    // 默认闪光灯模式
    [_camera flashWithMode:_flashMode];
    // 切换滤镜
    [_camera switchFilterWithCode:nil];
    
    // 启用智能贴纸
    _camera.enableFaceAutoBeauty = YES;
    
    // 最大录制时长 8s
    _camera.limitDuration = 8;
    
    // 启动相机
    [_camera tryStartCameraCapture];
    
    // 滤镜参数配置
    CGRect rect = self.cameraView.frame;
    _filterConfigView = [[FilterConfigView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y + 80, rect.size.width, rect.size.height - 80)];
    [self.cameraView.superview addSubview:_filterConfigView];
}

- (void)setOutputSize:(CGSize)outputSize
{
    _outputSize = outputSize;
    
    if (_camera)
    {
        _camera.outputSize = outputSize;
    }
}

/**
 *  销毁相机
 */
- (void)destoryCamera;
{
    if (_camera) {
        [_camera destory];
        _camera = nil;
    }
}

- (void)toggleCamera;
{
    [_camera rotateCamera];
    
    // 摄像头方向
    self.avPostion = _camera.cameraPosition;
}

/**
 *  切换滤镜
 *
 *  可查看 TuSDK.bundle/others/lsq_tusdk_configs.json ，找到 lsq_filter_SkinNature, lsq_filter_SkinPink ...，其中 SkinNature, SkinPink 即滤镜代码
 *
 *  @param code 滤镜代码
 */
- (void)switchFilterCode:(NSString *)code;
{
    [_camera switchFilterWithCode:code];
}

- (void)stopCamera;
{
    if(!_camera) return;
    
    [self destoryCamera];
}

/**
 *  开始录制
 */
- (void)startRecording;
{
    [_camera startRecording];
}

/**
 *  停止
 */
- (void)stopRecording;
{
    [_camera finishRecording];
}

/**
 *  录制状态
 *
 *  @return
 */
- (BOOL)isRecording;
{
    if(!_camera) return NO;
    
    return [_camera isRecording];
}


/**
 *  设置相机预览帧率
 *
 *  @param fps 帧率
 */
- (void)setFramerate:(NSUInteger)fps;
{
    if (_camera)
    {
        [_camera setFrameRate:(int32_t)fps];
    }
}


/**
 *  获取当前闪光灯模式
 *
 *  @return
 */
- (AVCaptureFlashMode)getFlashMode;
{
    return _flashMode;
}

/**
 *  设置闪光灯模式
 *  @see AVCaptureFlashMode
 *
 *  @param flashMode 设置闪光灯模式
 */
-(void)setFlashMode:(AVCaptureFlashMode)flashMode;
{
    _flashMode = flashMode;
    
    if (_camera)
    {
        [_camera flashWithMode:flashMode];
    }
}

/**
 *  销毁对象
 */
- (void)destroy;
{
    [self destoryCamera];
}

#pragma mark - live sticker
/**
 *  显示动态贴纸
 *
 *  @param stickerGroup 贴纸组对象
 */
- (void)showGroupSticker:(TuSDKPFStickerGroup *)stickerGroup;
{
    if (_camera)
    {
        [_camera showGroupSticker:stickerGroup];
    }
}

/**
 *  清除动态贴纸
 *
 */
- (void)removeAllLiveSticker;
{
    if (_camera)
    {
        [_camera removeAllLiveSticker];
    }
}

/**
 *  动态贴纸组是否正在使用
 */
- (BOOL)isGroupStickerUsed:(TuSDKPFStickerGroup *)stickerGroup;
{
    if (_camera)
    {
        return [_camera isGroupStickerUsed:stickerGroup];
    }
    
    return NO;
}


#pragma mark - TuSDKVideoCameraDelegate

/**
 *  相机状态改变 (如需操作UI线程， 请检查当前线程是否为主线程)
 *
 *  @param camera 相机对象
 *  @param state  相机运行状态
 */
- (void)onVideoCamera:(id<TuSDKVideoCameraInterface>)camera stateChanged:(lsqCameraState)state;
{
    
}

/**
 *  相机滤镜改变 (如需操作UI线程， 请检查当前线程是否为主线程)
 *
 *  @param camera    相机对象
 *  @param newFilter 新的滤镜对象
 */
- (void)onVideoCamera:(id<TuSDKVideoCameraInterface>)camera filterChanged:(TuSDKFilterWrap *)newFilter;
{
    if (_filterConfigView)
    {
        _filterConfigView.filterWrap = newFilter;
    }
}

/**
 *  视频录制完成
 *
 *  @param camerea 相机
 *  @param result  TuSDKVideoResult 对象
 */
- (void)onVideoCamera:(TuSDKRecordVideoCamera *)camerea result:(TuSDKVideoResult *)result;
{
    NSLog(@"record completed, duration: %lu", (unsigned long)result.duration);
    
    [[TuSDK shared].messageHub showSuccess:LSQString(@"lsq_save_saveToAlbum_succeed", @"保存成功")];
    
    if (_delegate && [_delegate respondsToSelector:@selector(onMovieRecordCompleted:)])
    {
        [_delegate onMovieRecordCompleted:result];
    }
}
/**
 *  视频录制出错
 *
 *  @param camerea 相机
 *  @param error   错误对象
 */
- (void)onVideoCamera:(TuSDKRecordVideoCamera *)camerea failedWithError:(NSError*)error;
{
    NSLog(@"record error");
}
@end

