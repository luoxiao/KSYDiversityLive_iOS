#import "KSYVSController.h"

@interface KSYVSController (){
    UISwipeGestureRecognizer *_swipeGest;
    NSDateFormatter * _dateFormatter;
    int64_t _seconds;
    NSMutableDictionary *_obsDict;
}

@end

@implementation KSYVSController


- (id) initWithCfg:(KSYPresetCfgView*)presetCfgView{
    self = [super init];
    _presetCfgView = presetCfgView;
    [self initObservers];
    self.view.backgroundColor = [UIColor whiteColor];
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    _vsKit = [[KSYVSStreamerKit alloc] initWithDefaultCfg];
    [self addSubViews];
    [self addSwipeGesture];
    // 采集相关设置初始化
    [self setCaptureCfg];
    // 设置vsFrame
    [self setVSFrame];
    //推流相关设置初始化
    _vsBase = [[KSYStreamerBase alloc] initWithDefaultCfg];
    [self setStreamerCfg];
    // 打印版本号信息
    NSLog(@"version: %@", [_vsKit getKSYVersion]);
    if (_vsKit) { // init with default filter
        _vsKit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [self onCapture];
    }
}
- (void)setVSFrame{
    UIView *testView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:testView];
    [self.view sendSubviewToBack:testView];
    _vsKit.vsVideoFrame = [[VSVideoFrame alloc] initWithPosition:AVCaptureDevicePositionFront pixelFormat:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange view:testView];
    _vsKit.vsVideoFrame.outputSize = CGSizeMake(360, 640);
    _vsKit.vsVideoFrame.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
    [_vsKit.vsVideoFrame startVideoFrame];
    [_vsKit startFaceTracking];
    [self setVSStream];
}

- (void)setVSStream{
    __weak typeof(self) weakSelf = self;
    _vsKit.vCapDev.videoProcessingCallback = ^(CMSampleBufferRef sampleBuffer){
        [weakSelf.vsKit.vsVideoFrame processVideoSampleBuffer:sampleBuffer];
    };
    _vsKit.vsVideoFrame.bgraPixelBlock = ^(CVPixelBufferRef buffer, CMTime time){
        [weakSelf.vsBase processVideoPixelBuffer:buffer timeInfo:time];
    };
    _vsKit.aCapDev.audioProcessingCallback = ^(CMSampleBufferRef sampleBuffer){
        [weakSelf.vsBase processAudioSampleBuffer:sampleBuffer];
    };
}
- (void)addSubViews{
    _ctrlView  = [[KSYCtrlView alloc] init];
    [self.view addSubview:_ctrlView];
    _ctrlView.frame = self.view.frame;
    // connect UI
    __weak KSYVSController *weakself = self;
    _ctrlView.onBtnBlock = ^(id btn){
        [weakself onBasicCtrl:btn];
    };
}
- (void)addSwipeGesture{
    SEL onSwip =@selector(swipeController:);
    _swipeGest = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                          action:onSwip];
    _swipeGest.direction |= UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:_swipeGest];
}
- (void)swipeController:(UISwipeGestureRecognizer *)swipGestRec{
    if (swipGestRec == _swipeGest){
        CGRect rect = self.view.frame;
        if ( CGRectEqualToRect(rect, _ctrlView.frame)){
            rect.origin.x = rect.size.width; // hide
        }
        [UIView animateWithDuration:0.1 animations:^{
            _ctrlView.frame = rect;
        }];
    }
}
#pragma mark - Notification

#define SEL_VALUE(SEL_NAME) [NSValue valueWithPointer:@selector(SEL_NAME)]

- (void) initObservers{
    _obsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                SEL_VALUE(onCaptureStateChange:), KSYCaptureStateDidChangeNotification,
                SEL_VALUE(onStreamStateChange:), KSYStreamStateDidChangeNotification,
                SEL_VALUE(onNetStateEvent:), KSYNetStateEventNotification,
                SEL_VALUE(enterBg:), UIApplicationDidEnterBackgroundNotification,
                SEL_VALUE(becameActive:), UIApplicationDidBecomeActiveNotification, nil];
}
- (void)addObservers{
    [super addObservers];
    //KSYStreamer state chagnes
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    for (NSString *key in _obsDict) {
        SEL aSel = [[_obsDict objectForKey:key] pointerValue];
        [dc addObserver:self
               selector:aSel
                   name:key
                 object:nil];
    }
}
- (void)rmObservers{
    [super rmObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void) onCaptureStateChange:(NSNotification *)notification{
    NSLog(@"new capStat: %@", _vsKit.getCurCaptureStateName );
    self.ctrlView.lblStat.text = [_vsKit getCurCaptureStateName];
}
- (void) onNetStateEvent     :(NSNotification *)notification{
    switch (_vsBase.netStateCode) {
        case KSYNetStateCode_SEND_PACKET_SLOW: {
            _ctrlView.lblStat.notGoodCnt++;
            break;
        }
        case KSYNetStateCode_EST_BW_RAISE: {
            _ctrlView.lblStat.bwRaiseCnt++;
            break;
        }
        case KSYNetStateCode_EST_BW_DROP: {
            _ctrlView.lblStat.bwDropCnt++;
            break;
        }
        default:break;
    }
}
- (void) onStreamStateChange :(NSNotification *)notification{
    if (_vsBase){
        NSLog(@"stream State %@", [_vsBase getCurStreamStateName]);
    }
    _ctrlView.lblStat.text = [_vsBase getCurStreamStateName];
    if(_vsBase.streamState == KSYStreamStateError) {
        [self onStreamError:_vsBase.streamErrorCode];
    }
    else if (_vsBase.streamState == KSYStreamStateConnecting) {
        [_ctrlView.lblStat initStreamStat]; // 尝试开始连接时,重置统计数据
    }
}
- (void) onStreamError:(KSYStreamErrorCode) errCode{
    _ctrlView.lblStat.text  = [_vsBase getCurKSYStreamErrorCodeName];
    if (errCode == KSYStreamErrorCode_CONNECT_BREAK) {
        // Reconnect
        [self tryReconnect];
    }
    else if (errCode == KSYStreamErrorCode_AV_SYNC_ERROR) {
        NSLog(@"audio video is not synced, please check timestamp");
        [self tryReconnect];
    }
    else if (errCode == KSYStreamErrorCode_CODEC_OPEN_FAILED) {
        NSLog(@"video codec open failed, try software codec");
        _vsBase.videoCodec = KSYVideoCodec_X264;
        [self tryReconnect];
    }
}
- (void) tryReconnect {
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        NSLog(@"try again");
        _vsBase.bWithVideo = YES;
        [_vsBase startStream:self.hostURL];
    });
}
- (void)enterBg:(NSNotification *)not{
    // 进入后台时, 将预览从图像混合器中脱离, 避免后台OpenGL渲染崩溃
    [_vsKit.vPreviewMixer removeAllTargets];
    [_vsKit.vStreamMixer removeAllTargets];
    [_vsKit.aCapDev stopCapture];
}
- (void) becameActive:(NSNotification *)not{
    [_vsKit.aCapDev startCapture];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (void) layoutUI {
    if(_ctrlView){
        _ctrlView.frame = self.view.frame;
        [_ctrlView layoutUI];
    }
}
#pragma mark - Capture & stream setup
- (void) setCaptureCfg {
    _vsKit.capPreset        = [self.presetCfgView capResolution];
    _vsKit.previewDimension = [self.presetCfgView capResolutionSize];
    _vsKit.streamDimension  = [self.presetCfgView strResolutionSize ];
    _vsKit.videoFPS       = [self.presetCfgView frameRate];
    _vsKit.cameraPosition = [self.presetCfgView cameraPos];
    _vsKit.gpuOutputPixelFormat = [self.presetCfgView gpuOutputPixelFmt];
    _vsKit.videoProcessingCallback = ^(CMSampleBufferRef buf){
    };
}
- (void) setStreamerCfg { // must set after capture
    if (_vsBase == nil) {
        return;
    }
    if (_presetCfgView){ // cfg from presetcfgview
        _vsBase.videoCodec       = [_presetCfgView videoCodec];
        _vsBase.videoInitBitrate = [_presetCfgView videoKbps]*6/10;//60%
        _vsBase.videoMaxBitrate  = [_presetCfgView videoKbps];
        _vsBase.videoMinBitrate  = 0; //
        _vsBase.audioCodec       = [_presetCfgView audioCodec];
        _vsBase.audiokBPS        = [_presetCfgView audioKbps];
        _vsBase.videoFPS         = [_presetCfgView frameRate];
        _vsBase.bwEstimateMode   = [_presetCfgView bwEstMode];
        _vsBase.shouldEnableKSYStatModule = YES;
        _vsBase.logBlock = ^(NSString* str){
            //NSLog(@"%@", str);
        };
        _hostURL = [NSURL URLWithString:[_presetCfgView hostUrl]];
    }
    else {
        [self defaultStramCfg];
    }
}
- (void) defaultStramCfg{
    // stream default settings
    _vsBase.videoCodec = KSYVideoCodec_AUTO;
    _vsBase.videoInitBitrate =  800;
    _vsBase.videoMaxBitrate  = 1000;
    _vsBase.videoMinBitrate  =    0;
    _vsBase.audiokBPS        =   48;
    _vsBase.shouldEnableKSYStatModule = YES;
    _vsBase.videoFPS = 15;
    _vsBase.logBlock = ^(NSString* str){
    };
    _hostURL = [NSURL URLWithString:@"rtmp://test.uplive.ks-cdn.com/live/123"];
}
#pragma mark - UI respond
//ctrView control (for basic ctrl)
- (void) onBasicCtrl: (id) btn {
    if (btn == _ctrlView.btnFlash){
        [self onFlash];
    }
    else if (btn == _ctrlView.btnCameraToggle){
        [self onCameraToggle];
    }
    else if (btn == _ctrlView.btnQuit){
        [self onQuit];
    }
    else if(btn == _ctrlView.btnCapture){
        [self onCapture];
    }
    else if(btn == _ctrlView.btnStream){
        [self onStream];
    }
}
#pragma mark - subviews: basic ctrl
- (void) onFlash {
    [_vsKit toggleTorch];
}
- (void) onCameraToggle{ // see kit or block
    [_vsKit switchCamera];
    if (_vsKit.vCapDev && _vsKit.vCapDev.cameraPosition == AVCaptureDevicePositionBack) {
        [_ctrlView.btnFlash setEnabled:YES];
    }
    else{
        [_ctrlView.btnFlash setEnabled:NO];
    }
}
- (void) onCapture{
    if (!_vsKit.vCapDev.isRunning){
        _vsKit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_vsKit startPreview:self.view];
    }
    else {
        [_vsKit stopPreview];
    }
}
- (void) onStream{
    if (_vsBase.streamState == KSYStreamStateIdle ||
        _vsBase.streamState == KSYStreamStateError) {
        [_vsBase startStream:self.hostURL];
    }
    else {
        [_vsBase stopStream];
    }
}
- (void) onQuit{
    [_vsKit stopPreview];
    _vsKit = nil;
    [self rmObservers];
    [self dismissViewControllerAnimated:FALSE completion:nil];
}
@end
