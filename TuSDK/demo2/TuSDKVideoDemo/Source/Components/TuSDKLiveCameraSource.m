//
//  TuSDKLiveCameraSource.m
//  TuSDKVideoDemo
//
//  Created by Yanlin on 2/22/16.
//
//

#import "TuSDKLiveCameraSource.h"
#import "FilterConfigView.h"

@interface TuSDKLiveCameraSource() <TuSDKLiveVideoCameraDelegate>
{
    // 相机对象
    TuSDKLiveVideoCamera *_camera;
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

@implementation TuSDKLiveCameraSource

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
- (NSString *)sessionPreset;
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
    _camera = [TuSDKLiveVideoCamera initWithSessionPreset:self.sessionPreset
                                       cameraPosition:self.avPostion
                                           cameraView:self.cameraView];
    
    
    // 设置委托
    _camera.videoDelegate = self;
    
    // 配置相机参数
    
    /**
     *  输出画面分辨率，默认原始采样尺寸输出。
     *  如果设置了输出尺寸，则对画面进行等比例缩放，必要时进行裁剪，保证输出尺寸和预设尺寸一致。
     */
    _camera.outputSize = _outputSize;
    /**
     *  输出 PixelBuffer 格式，可选: lsqFormatTypeBGRA | lsqFormatTypeYUV420F | lsqFormatTypeRawData
     *  默认:lsqFormatTypeBGRA
     */
     _camera.pixelFormatType = lsqFormatTypeBGRA;
    // 禁用持续自动对焦
    _camera.disableContinueFoucs = NO;
    // 点击手动聚焦 (直播相机默认关闭)
    _camera.disableTapFocus = YES;
    // 视频视图显示比例 (默认：0， 0 <= mRegionRatio, 当设置为0时全屏显示)
    _camera.cameraViewRatio = 0;
    // 视频覆盖区域颜色 (默认：[UIColor blackColor])
    _camera.regionViewColor = [UIColor blackColor];
    
    // 帧率
    _camera.frameRate = 25;
    
    // 禁用前置摄像头水平镜像 (默认: NO，前置摄像头输出画面进行水平镜像)
    _camera.disableMirrorFrontFacing = NO;
    // 默认闪光灯模式
    [_camera flashWithMode:_flashMode];
    // 切换滤镜
    [_camera switchFilterWithCode:nil];
    
    _camera.enableFaceAutoBeauty = YES;
    
    // 启动相机
    [_camera tryStartCameraCapture];
    
    // 滤镜参数配置
    CGRect rect = self.cameraView.frame;
    _filterConfigView = [[FilterConfigView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y + 80, rect.size.width, rect.size.height - 80)];
    [self.cameraView.superview addSubview:_filterConfigView];
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

- (void)startRunning;
{
    [self startCamera];
    
    [_camera startRecording];
}

- (void)stopRunning;
{
    if(!_camera) return;
    
    [self destoryCamera];
    
    [_camera cancelRecording];
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
    
    // 示例代码：获取滤镜参数，修改参数
    /*
    NSArray * args = newFilter.filterParameter.args;
    
    for (TuSDKFilterArg *arg in args)
    {
        NSLog(@"%@ - %f", arg.key, arg.value);
        
        if ([arg.key isEqualToString:@"smoothing"])
        {
            // 取值范围： 0 ~ 1.0
            arg.precent = 0.4;
        }
    }
    
    // 刷新显示
    [newFilter submitParameter];
    */
}

#pragma mark - TuSDKLiveVideoCameraDelegate

/**
 *  获取滤镜处理后的帧数据, pixelFormatType 为 lsqFormatTypeBGRA 或 lsqFormatTypeYUV420F 时调用
 *
 *  @param camera      相机
 *  @param pixelBuffer 帧数据, CVPixelBufferRef 类型, 默认为 kCVPixelFormatType_32BGRA 格式
 *  @param frameTime   帧时间戳
 */
- (void)onVideoCamera:(TuSDKLiveVideoCamera *)camera bufferData:(CVPixelBufferRef)pixelBuffer time:(CMTime)frameTime;
{
    // NSLog(@"new buffer size: %zu - %zu", CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoSource:newPixelBuffer:time:)])
    {
        [self.delegate videoSource:self newPixelBuffer:pixelBuffer time:frameTime];
    }
}

/**
 *  获取滤镜处理后的帧原始数据, pixelFormatType 为 lsqFormatTypeRawData 时调用
 *
 *  @param camera      相机
 *  @param bytes       帧数据
 *  @param bytesPerRow bytesPerRow
 *  @param imageSize   尺寸
 *  @param frameTime   帧时间戳
 */
- (void)onVideoCamera:(TuSDKLiveVideoCamera *)camera rawData:(unsigned char *)bytes bytesPerRow:(NSUInteger)bytesPerRow imageSize:(CGSize)imageSize time:(CMTime)frameTime;
{
    // 帧原始数据接口
}
@end
