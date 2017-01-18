//
//  TuSDKVideoProcessor.m
//  Pods
//
//  Created by Yanlin on 2/22/16.
//
//

#import "TuSDKVideoProcessor.h"

@interface TuSDKVideoProcessor() <TuSDKLiveVideoProcessorDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    // 当前比例类型
    lsqRatioType _currentRatioType;
    // 当前屏幕比例
    lsqRatioType _screenRatioType;
    
    // 当前闪光灯模式
    AVCaptureFlashMode _flashMode;
    
    //
    AVCaptureSession *_captureSession;
    
    AVCaptureDevice *_inputCamera;
    
    AVCaptureDeviceInput *_videoInput;
    
    AVCaptureVideoDataOutput *_videoOutput;
    
    // 视频输出朝向
    UIInterfaceOrientation _videoOutputPrientation;
    
    // 视频处理对象
    TuSDKLiveVideoProcessor *_videoProcessor;
    
    dispatch_queue_t cameraProcessingQueue;
}

@property (nonatomic, strong) AVCaptureVideoDataOutput *deviceOutput;

@end

@implementation TuSDKVideoProcessor

/**
 *  初始化
 *
 *  @param cameraPosition 摄像头位置
 *  @param view           预览视图
 *  @param outputSize     输出尺寸
 *
 *  @return
 */
- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition
                            cameraView:(UIView *)view
                             videoSize:(CGSize)outputSize;
{
    self = [super init];
    if (self) {
        _cameraView = view;
        
        _avPostion = cameraPosition;
        
        _outputSize = outputSize;
        
        // 竖屏
        _videoOutputPrientation = UIInterfaceOrientationPortrait;
        
        //
        _flashMode = AVCaptureFlashModeAuto;
        
        [self initCamera];
        
        [self initProcessor];
    }
    
    return self;
}


/**
 *  初始化处理器
 */
-(void)initProcessor;
{
    //
    _videoProcessor = [[TuSDKLiveVideoProcessor alloc] initWithCaptureSession:_captureSession VideoDataOutput:_videoOutput cameraView:_cameraView];
    
    // 设置委托
    _videoProcessor.delegate = self;
    
    /**
     *  输出画面分辨率，默认原始采样尺寸输出。
     *  如果设置了输出尺寸，则对画面进行等比例缩放，必要时进行裁剪，保证输出尺寸和预设尺寸一致。
     */
    _videoProcessor.outputSize = _outputSize;
    /**
     *  输出 PixelBuffer 格式，可选: lsqFormatTypeBGRA | lsqFormatTypeYUV420F | lsqFormatTypeRawData
     *  默认:lsqFormatTypeBGRA
     */
    // _videoProcessor.pixelFormatType = lsqFormatTypeYUV420F;
    
    // 视频视图显示比例 (默认：0， 0 <= mRegionRatio, 当设置为0时全屏显示)
    _videoProcessor.cameraViewRatio = 0;
    // 视频覆盖区域颜色 (默认：[UIColor blackColor])
    _videoProcessor.regionViewColor = [UIColor blackColor];
    
    // 设置默认相机方向，需要与VideoOrientation保持一致
    _videoProcessor.outputImageOrientation = _videoOutputPrientation;
    // 禁用前置摄像头水平镜像 (默认: NO，前置摄像头输出画面进行水平镜像)
    _videoProcessor.disableMirrorFrontFacing = YES;

    // 切换滤镜
    [_videoProcessor switchFilterWithCode:nil];
    
    // 更新处理器中的Camera
    _videoProcessor.cameraPosition = _avPostion;
    _videoProcessor.inputCamera = _inputCamera;
}

/**
 *  初始化相机
 */
- (void)initCamera;
{
    // Grab the back-facing or front-facing camera
    _inputCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == _avPostion)
        {
            _inputCamera = device;
        }
    }
    
    if (!_inputCamera) {
        return;
    }
    
    // Create the capture session
    _captureSession = [[AVCaptureSession alloc] init];
    
    [_captureSession beginConfiguration];
    
    // Add the video input
    NSError *error = nil;
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_inputCamera error:&error];
    if ([_captureSession canAddInput:_videoInput])
    {
        [_captureSession addInput:_videoInput];
    }
    
    // Add the video frame output
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setAlwaysDiscardsLateVideoFrames:NO];
    

    cameraProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
    
    [_videoOutput setSampleBufferDelegate:self queue:cameraProcessingQueue];
    if ([_captureSession canAddOutput:_videoOutput])
    {
        [_captureSession addOutput:_videoOutput];
    }
    else
    {
        NSLog(@"Couldn't add video output");
        return;
    }
    
    [_captureSession setSessionPreset:[self sessionPreset]];
    
    // This will let you get 60 FPS video from the 720p preset on an iPhone 4S, but only that device and that preset
    //    AVCaptureConnection *conn = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    //
    //    if (conn.supportsVideoMinFrameDuration)
    //        conn.videoMinFrameDuration = CMTimeMake(1,60);
    //    if (conn.supportsVideoMaxFrameDuration)
    //        conn.videoMaxFrameDuration = CMTimeMake(1,60);
    
    [_captureSession commitConfiguration];
}

- (void)destroyCamera
{
    
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

/**
 *  切换前/后摄像头
 */
- (void)toggleCamera;
{
    // 切换摄像头
    [_videoProcessor rotateCamera];
    
    NSError *error;
    AVCaptureDeviceInput *newVideoInput;
    
    if (_avPostion == AVCaptureDevicePositionBack)
    {
        _avPostion = AVCaptureDevicePositionFront;
    }
    else
    {
        _avPostion = AVCaptureDevicePositionBack;
    }
    
    AVCaptureDevice *backFacingCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == _avPostion)
        {
            backFacingCamera = device;
        }
    }
    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:&error];
    
    if (newVideoInput != nil)
    {
        [_captureSession beginConfiguration];
        
        [_captureSession removeInput:_videoInput];
        if ([_captureSession canAddInput:newVideoInput])
        {
            [_captureSession addInput:newVideoInput];
            _videoInput = newVideoInput;
        }
        else
        {
            [_captureSession addInput:_videoInput];
        }
        //captureSession.sessionPreset = oriPreset;
        [_captureSession commitConfiguration];
    }
    
    _inputCamera = backFacingCamera;
    
    // 更新处理器中的Camera
    _videoProcessor.inputCamera = _inputCamera;
    [_videoProcessor setCameraPosition:_avPostion];
    // 这里的代码顺序不能变更
    [_videoProcessor setOutputImageOrientation:_videoProcessor.outputImageOrientation];
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
    if (!_captureSession || _flashMode == flashMode) {
        return ;
    }
    
    _flashMode = flashMode;
    
    [_captureSession beginConfiguration];
    
    if(_inputCamera.flashAvailable)
    {
        NSError* err = nil;
        
        if([_inputCamera lockForConfiguration:&err])
        {
            [_inputCamera setFlashMode:flashMode];
            [_inputCamera unlockForConfiguration];
            
        } else {
            NSLog(@"Error while locking device for torch: %@", err);
        }
    } else {
        NSLog(@"Torch not available in current camera input");
    }
    [_captureSession commitConfiguration];
}

/**
 *  销毁对象
 */
- (void)destroy;
{
    [_videoProcessor destroy];
}

/**
 *  设置相机预览帧率
 *
 *  @param fps 帧率
 */
- (void)setFramerate:(NSUInteger)fps;
{
    NSError *error = nil;
  
    if (![_inputCamera lockForConfiguration:&error])
    {
        NSLog(@"fail to lockForConfiguration: %@",error.localizedDescription);
    }
    else
    {
        AVFrameRateRange *range = [_inputCamera.activeFormat.videoSupportedFrameRateRanges firstObject];
    
        if (fps <= range.maxFrameRate && fps >= range.minFrameRate)
        {
            if ([_inputCamera respondsToSelector:@selector(activeVideoMaxFrameDuration)]) {
                _inputCamera.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)fps);
                _inputCamera.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)fps);
            }
        }
        
        [_inputCamera unlockForConfiguration];
    }
}

- (void)switchFilterCode:(NSString *)code;
{
    [_videoProcessor switchFilterWithCode:code];
}

-(void)startRunning;
{
    if (![_captureSession isRunning])
    {
        [_captureSession startRunning];
        
        [_videoProcessor startRunning];
    }
}

- (void)stopRunning;
{
    [_captureSession stopRunning];
    
    [_videoProcessor stopRunning];
}


#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    NSLog(@"raw buffer size: %zu - %zu", CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    
    
    [_videoProcessor processVideoSampleBuffer:sampleBuffer];
}

#pragma mark - TuSDKLiveVideoProcessorDelegate

/**
 *  获取处理后的帧缓冲数据
 *
 *  @param processor   视频处理对象
 *  @param pixelBuffer 帧数据, CVPixelBufferRef 类型, 默认为 kCVPixelFormatType_32BGRA 格式
 *  @param frameTime   帧时间戳
 */
- (void)onVideoProcessor:(TuSDKLiveVideoProcessor *)processor bufferData:(CVPixelBufferRef)pixelBuffer time:(CMTime)frameTime;
{
    NSLog(@"new buffer size: %zu - %zu", CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));

    if (self.delegate && [self.delegate respondsToSelector:@selector(videoSource:newPixelBuffer:time:)])
    {
        [self.delegate videoSource:self newPixelBuffer:pixelBuffer time:frameTime];
    }
}
/**
 *  获取滤镜处理后的帧原始数据, pixelFormatType 为 lsqFormatTypeRawData 时调用
 *
 *  @param processor   视频处理对象
 *  @param bytes       帧数据
 *  @param bytesPerRow bytesPerRow
 *  @param imageSize   尺寸
 *  @param frameTime   帧时间戳
 */
- (void)onVideoProcessor:(TuSDKLiveVideoProcessor *)processor rawData:(unsigned char *)bytes bytesPerRow:(NSUInteger)bytesPerRow imageSize:(CGSize)imageSize time:(CMTime)frameTime;
{
    // 帧原始数据接口
}

/**
 *  滤镜改变 (如需操作UI线程， 请检查当前线程是否为主线程)
 *
 *  @param processor     视频处理对象
 *  @param newFilterWrap 新的滤镜对象
 */
- (void)onVideoProcessor:(TuSDKLiveVideoProcessor *)processor filterChanged:(TuSDKFilterWrap *)newFilterWrap;
{
    // 示例代码：获取滤镜参数，修改参数
    
    NSArray * args = newFilterWrap.filterParameter.args;

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
    [newFilterWrap submitParameter];
}
@end
