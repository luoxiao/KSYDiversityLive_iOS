#import "KSYTTDemoVC.h"
#import "FilterConfigView.h"
#import "KSYTuStreamerKit.h"


@interface KSYTTDemoVC ()<UIGestureRecognizerDelegate>
{
    UIView              *_preview;
    NSURL               *_hostURL;
}
@property (nonatomic, strong) KSYTuStreamerKit    *kit;
@end

@implementation KSYTTDemoVC

- (BOOL)prefersStatusBarhidden{
    return YES;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return NO;
}
- (BOOL)shouldAutorotate{
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}
- (void)loadView{
    [super loadView];
    _videoFilters = @[@"Glare",@"VideoFair",@"无"];
    _videoFilterIndex = 1;
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}
- (void)lsqInitView{
    [super lsqInitView];
    [self initSettingsAndStartPreview];
}
- (void)initSettingsAndStartPreview
{
    _kit = [[KSYTuStreamerKit alloc] initWithDefault:self.view];
    [_kit startCapture];
    
    NSString *dev = [[[[[UIDevice currentDevice] identifierForVendor]UUIDString]lowercaseString] substringToIndex:3];
    NSString *soStr = @"rtmp://test.uplive.ks-cdn.com/live";
    NSString *rtmpStr = [NSString stringWithFormat:@"%@/%@",soStr,dev];
    NSLog(@"%@", rtmpStr);
    _hostURL = [NSURL URLWithString:rtmpStr];
}



- (void)switchFilter:(NSString *)code
{
    __weak typeof(self) weakSelf =  self;
    dispatch_async(self.sessionQueue, ^{
        [weakSelf.kit.cameraSource switchFilterCode:code];
    });
}


- (void)onConfigButtonClicked:(id)sender
{
    if (sender == self.mCloseButton)
    {
        [self dismissModalViewControllerAnimated];
    }
    else if (sender == self.mFilterButton)
    {
        _beautyEnabled = !_beautyEnabled;
        
        NSString *code = _beautyEnabled ? [_videoFilters objectAtIndex:_videoFilterIndex] : @"";
        
        [self switchFilter:code];
        
        [self updateBeautyStatus:_beautyEnabled];
    }
    else if (sender == self.mSettingButton)
    {
        
    }
    else if (sender == self.mToggleCameraButton)
    {
        [_kit.cameraSource toggleCamera];
        
        [self.mFlashButton setEnabled:_kit.cameraSource.avPostion == AVCaptureDevicePositionBack];
    }
    else if (sender == self.mFlashButton)
    {
        self.flashModeIndex++;
        
        if (self.flashModeIndex >=3)
        {
            self.flashModeIndex = 0;
        }
        
        [self updateFlashModeStatus];
        
        dispatch_async(self.sessionQueue, ^{
            [_kit.cameraSource setFlashMode:[self getFlashModeByValue:self.flashModeIndex]];
        });
    }
}
- (void)startStream:(UIButton *)btn{
    [super startStream:btn];
    if (_kit.streamerBase.streamState == KSYStreamStateIdle ||
        _kit.streamerBase.streamState == KSYStreamStateError) {
        [_kit.streamerBase startStream:_hostURL];
    }
    else{
        [_kit.streamerBase stopStream];
    }
}
- (void)updateFlashModeStatus
{
    [super updateFlashModeStatus];
    [self.mFlashButton setEnabled:_kit.cameraSource.avPostion == AVCaptureDevicePositionBack];
}

- (AVCaptureFlashMode)getFlashModeByValue:(NSInteger)value
{
    if (value == 2)
    {
        return AVCaptureFlashModeAuto;
    }
    else if(value == 1)
    {
        return AVCaptureFlashModeOn;
    }
    
    return AVCaptureFlashModeOff;
}


@end
