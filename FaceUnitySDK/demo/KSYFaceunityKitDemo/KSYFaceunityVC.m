#import "KSYFaceunityVC.h"
#import "KSYFaceunityFilter.h"

// 为防止将手机存储写满,限制录像时长为30s
#define REC_MAX_TIME 30 //录制视频的最大时间，单位s

@interface KSYFaceunityVC ()<UICollectionViewDelegate,UICollectionViewDataSource>
{
    UISwipeGestureRecognizer *_swipeGest;
    NSDateFormatter * _dateFormatter;
    int64_t _seconds;
    NSMutableDictionary *_obsDict;
    NSMutableArray  *_resourceArray;
    KSYFaceunityFilter * _faceUnityFilter;
    NSString *_recFile;// 录制文件
    BOOL _bRecord;//是否录制
    int _strSeconds; // 推流持续的时间 , 单位s
    NSURL * _url;//暂存推流地址
}
@end

@implementation KSYFaceunityVC

- (id) initWithCfg:(KSYPresetCfgView*)presetCfgView{
    self = [super init];
    _presetCfgView = presetCfgView;
    [self initObservers];
    self.view.backgroundColor = [UIColor whiteColor];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //NSArray *array = [NSArray arrayWithObjects:@"open",@"kitty.bundle", @"fox.bundle", @"evil.bundle", @"eyeballs.bundle", @"mood.bundle", @"tears.bundle", @"rabbit.bundle", @"cat.bundle", @"close", nil];
    NSArray *array = @[
                       @"tiara",
                       @"YellowEar",
                       @"tears",
                       @"PrincessCrown",
                       @"Mood",
                       @"Deer",
                       @"BeagleDog",
                       @"HappyRabbi",
                       @"hartshorn",
                       @"item0204",
                       @"item0208",
                       @"item0210",
                       @"item0501",
                       ];
    
    _resourceArray = [NSMutableArray arrayWithArray:array];
    
    _kit = [[KSYGPUStreamerKit alloc] initWithDefaultCfg];
    [self addSubViews];
    [self addSwipeGesture];
    // 采集相关设置初始化
    [self setCaptureCfg];
    //推流相关设置初始化
    [self setStreamerCfg];
    //设置贴纸相关
    [self setupFaceUnity];
    // 打印版本号信息
    NSLog(@"version: %@", [_kit getKSYVersion]);
    
    if (_kit) { // init with default filter
        _kit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_kit startPreview:self.view];
    }
    [self iniWithUI];
    
    _url = self.hostURL;
    _recFile =[NSHomeDirectory() stringByAppendingString:@"/Documents/rec.mp4"];
    _bRecord = NO;
}
- (void)addSubViews{
    _ctrlView  = [[KSYCtrlView alloc] init];
    _ctrlView.lblNetwork.text = @"点击Open";
    [self.view addSubview:_ctrlView];
    _ctrlView.frame = self.view.frame;
    
    // connect UI
    __weak KSYFaceunityVC *weakself = self;
    _ctrlView.onBtnBlock = ^(id btn){
        [weakself onBasicCtrl:btn];
    };
}
- (void) addSwipeGesture{
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
- (void)viewDidAppear:(BOOL)animated {
    [self layoutUI];
    [UIApplication sharedApplication].idleTimerDisabled=YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled=NO;
}
- (void) layoutUI {
    if(_ctrlView){
        _ctrlView.frame = self.view.frame;
        [_ctrlView layoutUI];
    }
}

#pragma mark -  state change
- (void) onCaptureStateChange:(NSNotification *)notification{
    NSLog(@"new capStat: %@", _kit.getCurCaptureStateName );
    self.ctrlView.lblStat.text = [_kit getCurCaptureStateName];
}

- (void) onNetStateEvent     :(NSNotification *)notification{
    switch (_kit.streamerBase.netStateCode) {
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
    if (_kit.streamerBase){
        NSLog(@"stream State %@", [_kit.streamerBase getCurStreamStateName]);
    }
    _ctrlView.lblStat.text = [_kit.streamerBase getCurStreamStateName];
    if(_kit.streamerBase.streamState == KSYStreamStateError) {
        [self onStreamError:_kit.streamerBase.streamErrorCode];
    }
    else if (_kit.streamerBase.streamState == KSYStreamStateConnecting) {
        [_ctrlView.lblStat initStreamStat]; // 尝试开始连接时,重置统计数据
    }
    //状态为KSYStreamStateIdle且_bRecord为ture时，录制视频
    if (_kit.streamerBase.streamState == KSYStreamStateIdle && _bRecord){
        [self saveVideoToAlbum:_recFile];
    }
}

- (void) onStreamError:(KSYStreamErrorCode) errCode{
    _ctrlView.lblStat.text  = [_kit.streamerBase getCurKSYStreamErrorCodeName];
    if (errCode == KSYStreamErrorCode_CONNECT_BREAK) {
        // Reconnect
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            _kit.streamerBase.bWithVideo = YES;
            [_kit.streamerBase startStream:self.hostURL];
        });
    }
    else if (errCode == KSYStreamErrorCode_AV_SYNC_ERROR) {
        NSLog(@"audio video is not synced, please check timestamp");
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            NSLog(@"try again");
            _kit.streamerBase.bWithVideo = YES;
            [_kit.streamerBase startStream:self.hostURL];
        });
    }
}
#pragma mark - timer respond per second
- (void)onTimer:(NSTimer *)theTimer{
    if (_kit.streamerBase.streamState == KSYStreamStateConnected ) {
        [_ctrlView.lblStat updateState: _kit.streamerBase];
    }
    _strSeconds++;
    [self updateRecLabel];  // 本地录制:直接存储到本地, 不推流
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
    else if (btn == _ctrlView.btnCapture){
        [self onCapture];
    }
    else if (btn == _ctrlView.btnStream){
        _bRecord = NO;
        [self onStream];
    }
    else if(btn == _ctrlView.btnRecord){
        _bRecord = YES;
        [self onStream];
    }
}
#pragma mark - subviews: basic ctrl
- (void) onFlash {
    [_kit toggleTorch];
}
- (void) onCameraToggle{ // see kit or block
    [_kit switchCamera];
    if (_kit.vCapDev && _kit.vCapDev.cameraPosition == AVCaptureDevicePositionBack) {
        [_ctrlView.btnFlash setEnabled:YES];
    }
    else{
        [_ctrlView.btnFlash setEnabled:NO];
    }
}
- (void) onCapture{
    if (!_kit.vCapDev.isRunning){
        _kit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_kit startPreview:self.view];
    }
    else {
        [_kit stopPreview];
    }
}
- (void) onStream{
    if (_kit.streamerBase.streamState == KSYStreamStateIdle ||
        _kit.streamerBase.streamState == KSYStreamStateError) {
        [self updateStreamCfg:YES];
        [_kit.streamerBase startStream:self.hostURL];
    }
    else {
        [self updateStreamCfg:NO];
        [_kit.streamerBase stopStream];
    }
}
- (void) onQuit{
    [_kit stopPreview];
    _kit = nil;
    [self rmObservers];
    [self dismissViewControllerAnimated:FALSE completion:nil];
}

#define SEL_VALUE(SEL_NAME) [NSValue valueWithPointer:@selector(SEL_NAME)]

- (void) initObservers{
    _obsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                SEL_VALUE(onCaptureStateChange:) ,  KSYCaptureStateDidChangeNotification,
                SEL_VALUE(onStreamStateChange:) ,   KSYStreamStateDidChangeNotification,
                SEL_VALUE(onNetStateEvent:) ,       KSYNetStateEventNotification,
                nil];
}
- (void) addObservers {
    [super addObservers];
    //KSYStreamer state changes
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    for (NSString* key in _obsDict) {
        SEL aSel = [[_obsDict objectForKey:key] pointerValue];
        [dc addObserver:self
               selector:aSel
                   name:key
                 object:nil];
    }
}

- (void) rmObservers {
    [super rmObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)iniWithUI{
    //创建一个
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    //设置布局方向为垂直流布局
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    //设置每个item的大小为100 * 100
    layout.itemSize = CGSizeMake(50, 50);
    //创建collectionview通过一个布局策略来创建
    UICollectionView *collect = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 100, self.view.frame.size.width, 100)  collectionViewLayout:layout];
    //设置代理
    collect.delegate = self;
    collect.dataSource = self;
    collect.backgroundColor = [UIColor blackColor];
    collect.alpha = 0.5;
    //组册item类型，这里使用系统的类型
    [collect registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellid"];
    [self.view addSubview:collect];
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView  cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor blueColor];
    
    [self changeStickerName:indexPath.row];
    _faceUnityFilter.choosedIndex = indexPath.row;
}
- (void)changeStickerName:(NSInteger)idx{
    _ctrlView.lblNetwork.text = _resourceArray[idx];
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView  cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
}
//返回分区个数
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
//返回每个分区的item个数
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _resourceArray.count;
}
//获取cell
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell * cell  = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellid" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    label.textColor = [UIColor redColor];
    label.text = [NSString stringWithFormat:@"%@",[_resourceArray objectAtIndex:indexPath.row]];
    for (id subView in cell.contentView.subviews) {
        [subView removeFromSuperview];
    }
    [cell.contentView addSubview:label];
    return cell;
}
- (void)loadDataWithItem:(NSString *)fileName{
    //创建url
    NSString *urlStr = [NSString stringWithFormat:@"http://ks3-cn-beijing.ksyun.com/ksy.vcloud.sdk/Ios/%@",fileName];
    //urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlStr];
    //创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //__weak typeof(self) weakSelf = self;
    //创建会话 这里使用一个全局会话 并启动任务
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            //注意location是下载后的临时保存路径，需要将他移动到需要保存的位置
            NSError *saveError;
            NSString *cachePath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            NSString *savePath=[cachePath stringByAppendingPathComponent:fileName];
            NSURL *saveUrl = [NSURL fileURLWithPath:savePath];
            [[NSFileManager defaultManager] copyItemAtURL:location toURL:saveUrl error:&saveError];
            if (!saveError) {
                NSLog(@"save sucess.");
            }else{
                NSLog(@"saveError is :%@",saveError.localizedDescription);
            }
        }else{
            NSLog(@"error is %@", error.localizedDescription);
        }
    }];
    [downloadTask resume];
}
- (NSString *)dataFilePathWithName:(NSString *)name{
    NSString *cachePath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *savePath=[cachePath stringByAppendingPathComponent:name];
    return savePath;
}
#pragma mark - Capture & stream setup
- (void) setCaptureCfg {
    _kit.capPreset        = [self.presetCfgView capResolution];
    _kit.previewDimension = [self.presetCfgView capResolutionSize];
    _kit.streamDimension  = [self.presetCfgView strResolutionSize ];
    _kit.videoFPS       = [self.presetCfgView frameRate];
    _kit.cameraPosition = [self.presetCfgView cameraPos];
}

-(void)setupFaceUnity
{
    NSMutableArray * g_item_names = [NSMutableArray array];
    
    [_resourceArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [g_item_names addObject:[obj stringByAppendingString:@".bundle"]];
    }];
    // faceUnityFilter
    _faceUnityFilter = [[KSYFaceunityFilter alloc]initWithArray:g_item_names];
    
    // beautyFilter
    GPUImageOutput<GPUImageInput>* beautyFilter = [[KSYGPUBeautifyPlusFilter alloc]init];
    
    // 用滤镜组 将 滤镜 串联成整体
    GPUImageFilterGroup * fg = [[GPUImageFilterGroup alloc] init];
    [fg addFilter:_faceUnityFilter];
    [fg addFilter:beautyFilter];
    
    [_faceUnityFilter addTarget:beautyFilter];
    
    [fg setInitialFilters:[NSArray arrayWithObject:_faceUnityFilter]];
    [fg setTerminalFilter:beautyFilter];
    
    [_kit setupFilter:fg];
}

- (void) setStreamerCfg { // must set after capture
    if (_kit.streamerBase == nil) {
        return;
    }
    if (_presetCfgView){ // cfg from presetcfgview
        _kit.streamerBase.videoCodec       = [_presetCfgView videoCodec];
        _kit.streamerBase.videoInitBitrate = [_presetCfgView videoKbps]*6/10;//60%
        _kit.streamerBase.videoMaxBitrate  = [_presetCfgView videoKbps];
        _kit.streamerBase.videoMinBitrate  = 0; //
        _kit.streamerBase.audioCodec       = [_presetCfgView audioCodec];
        _kit.streamerBase.audiokBPS        = [_presetCfgView audioKbps];
        _kit.streamerBase.videoFPS         = [_presetCfgView frameRate];
        _kit.streamerBase.bwEstimateMode   = [_presetCfgView bwEstMode];
        _kit.streamerBase.shouldEnableKSYStatModule = YES;
        _kit.streamerBase.logBlock = ^(NSString* str){ };
        _hostURL = [NSURL URLWithString:[_presetCfgView hostUrl]];
    }
    [self defaultStramCfg];
}
- (void) defaultStramCfg{
    // stream default settings
    _kit.streamerBase.videoCodec = KSYVideoCodec_AUTO;
    _kit.streamerBase.videoInitBitrate =  800;
    _kit.streamerBase.videoMaxBitrate  = 1000;
    _kit.streamerBase.videoMinBitrate  =    0;
    _kit.streamerBase.audiokBPS        =   48;
    _kit.streamerBase.videoFPS = [_presetCfgView frameRate];
    _kit.streamerBase.logBlock = ^(NSString* str){
        //            NSLog(@"%@", str);
    };
    _hostURL = [NSURL URLWithString:@"rtmp://test.uplive.ksyun.com/live/823"];
}

- (void) updateStreamCfg: (BOOL) bStart {
    _strSeconds = 0;
    //判断是直播还是录制
    if (_bRecord){
        if (bStart){
            [self deleteFile:_recFile];
            self.hostURL =[[NSURL alloc] initFileURLWithPath:_recFile];
            _ctrlView.btnStream.enabled = NO;
        }
        else{
            _ctrlView.btnStream.enabled = YES;
        }
    }
    else{
        if (bStart){
            self.hostURL = _url;
            _ctrlView.btnRecord.enabled = NO;
        }
        else{
            _ctrlView.btnRecord.enabled = YES;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateRecLabel {
    if (!_bRecord){ // 直接录制短视频
        return;
    }
    int diff = REC_MAX_TIME - _strSeconds;
    //保持连接和限制短视频长度
    if (_kit.streamerBase.isStreaming && diff < 0){
        [self onStream];//结束录制
    }
    if (_kit.streamerBase.isStreaming){//录制时的倒计时时间
        NSString *durMsg = [NSString stringWithFormat:@"%ds/%ds", diff,REC_MAX_TIME];
        _ctrlView.lblRecDur.text = durMsg;
    }
    else{
        _ctrlView.lblRecDur.text = @"0s";
    }
}

//保存视频到相簿
- (void) saveVideoToAlbum: (NSString*) path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
            SEL onDone = @selector(video:didFinishSavingWithError:contextInfo:);
            UISaveVideoAtPathToSavedPhotosAlbum(path, self, onDone, nil);
        }
    });
}
//保存mp4文件完成时的回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
    NSString *message;
    if (!error) {
        message = @"Save album success!";
    }
    else {
        message = @"Failed to save the album!";
    }
    [KSYUIVC toast:message time:3];
}
//删除文件,保证保存到相册里面的视频时间是更新的
-(void)deleteFile:(NSString *)file{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:file]) {
        [fileManager removeItemAtPath:file error:nil];
    }
}

- (BOOL)shouldAutorotate{
    return NO;
}
@end
