//
//  LiveVideoController.m
//  TuSDKVideoDemo
//
//  Created by Yanlin on 4/18/16.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import "LiveVideoController.h"
#import "TuSDKLiveCameraSource.h"
#import "FilterConfigView.h"
#import "StickerListCell.h"
#import <libksygpulive/libksygpulive.h>
#import <libksygpulive/libksygpuimage.h>
#import <libksygpulive/KSYGPUStreamerKit.h>


#pragma mark - LiveVideoController

@interface LiveVideoController ()<UIGestureRecognizerDelegate, TuSDKLiveCameraSourceDelegate>
{
    // 实时相机
    TuSDKLiveCameraSource *_cameraSource;
    
    //kit
    KSYGPUStreamerKit     *_kit;
    
    // 测试视图
    UIImageView *_previewView;
}
// 推流地址 完整的URL
@property NSURL * hostURL;
@end

#pragma mark - LiveVideoController

@implementation LiveVideoController

// 隐藏状态栏 for IOS7
- (BOOL)prefersStatusBarHidden;
{
    return YES;
}

// 是否允许旋转 IOS5
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return NO;
}

// 是否允许旋转 IOS6
-(BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)loadView;
{
    [super loadView];
    
    // 直播滤镜列表
    _videoFilters = @[@"VideoFair", @"VideoWhiteSkin", @"VideoYoungGirl", @"VideoHuaJiao", @"VideoJelly"];
    _videoFilterIndex = 0;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopRunning];
}

/**
 *  构建界面元素
 */
- (void)lsqInitView
{
    [super lsqInitView];
    
    // 测试视图，显示推流画面
    _previewView = [[UIImageView alloc] initWithFrame:CGRectMake(30, 60, 160, 200)];
    _previewView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_previewView];
    
    [self initSettingsAndStartPreview];
}

- (void)initSettingsAndStartPreview
{
    //kit initialized
    _kit = [[KSYGPUStreamerKit alloc] initWithDefaultCfg];
    // Off | On | Auto
    self.flashModeIndex = 0;
    [self updateFlashModeStatus];
    
    [self setCaptureCfg];
    [self setStreamCfg];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(streamStateChange) name:KSYStreamStateDidChangeNotification object:nil];
    
    [_cameraSource startRunning];
    [_kit.aCapDev startCapture];
}
- (void) streamStateChange{
    if (_kit.streamerBase){
        [self.mSettingButton setTitle:[_kit.streamerBase getCurStreamStateName] forState:UIControlStateNormal];
    }
}
- (void)setCaptureCfg{
    _kit.previewDimension = [self.cfgview capResolutionSize];
    _kit.streamDimension  = [self.cfgview strResolutionSize ];
    AVCaptureDevicePosition pos = [AVCaptureDevice lsqFirstFrontCameraPosition];
    if (!pos)
    {
        pos = [AVCaptureDevice lsqFirstBackCameraPosition];
    }
    _cameraSource = [[TuSDKLiveCameraSource alloc] initWithCameraPosition:pos cameraView:_cameraView videoSize:[self.cfgview capResolutionSize]];
    _cameraSource.delegate = self;
}
- (void)setStreamCfg{
    if (_cfgview) {
        _kit.streamerBase.videoCodec       = [_cfgview videoCodec];
        _kit.streamerBase.videoInitBitrate = [_cfgview videoKbps]*6/10;//60%
        _kit.streamerBase.videoMaxBitrate  = [_cfgview videoKbps];
        _kit.streamerBase.videoMinBitrate  = 0; //
        _kit.streamerBase.audioCodec       = [_cfgview audioCodec];
        _kit.streamerBase.audiokBPS        = [_cfgview audioKbps];
        _kit.streamerBase.videoFPS         = [_cfgview frameRate];
        _kit.streamerBase.bwEstimateMode   = [_cfgview bwEstMode];
        _kit.streamerBase.logBlock = ^(NSString* str){
            //NSLog(@"%@", str);
        };
        _hostURL = [NSURL URLWithString:[_cfgview hostUrl]];
    }
}

- (void)switchFilter:(NSString *)code
{
    dispatch_async(self.sessionQueue, ^{
        [_cameraSource switchFilterCode:code];
    });
}

- (void)dealloc {
    self.sessionQueue = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_kit.aCapDev stopCapture];
    [_cameraSource stopRunning];
    _kit = nil;
    [_cameraSource destroy];
}

#pragma mark - Operation

- (void)stopRunning {
    dispatch_async(self.sessionQueue, ^{
        [_cameraSource stopRunning];
    });
}

- (void)startRunning {
    self.mActionButton.enabled = NO;
    dispatch_async(self.sessionQueue, ^{
        [_cameraSource startRunning];
    });
}

#pragma mark - Action

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
        self.mSettingButton.selected = !self.mSettingButton.selected;
        if (self.mSettingButton.selected) {
            [_kit.streamerBase startStream:_hostURL];
        }else{
            [_kit.streamerBase stopStream];
        }
    }
    else if (sender == self.mToggleCameraButton)
    {
        [_cameraSource toggleCamera];
        
        [self.mFlashButton setEnabled:_cameraSource.avPostion == AVCaptureDevicePositionBack];
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
            [_cameraSource setFlashMode:[self getFlashModeByValue:self.flashModeIndex]];
        });
    }
}

- (void)updateFlashModeStatus
{
    [super updateFlashModeStatus];
    [self.mFlashButton setEnabled:_cameraSource.avPostion == AVCaptureDevicePositionBack];
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

- (void)onActionHandle:(id)sender
{
    
}

#pragma mark - smart sticker handle

/**
 选中了某个贴纸组
 
 @param group 贴纸组
 */
- (void)onStickerGroupSelected:(TuSDKPFStickerGroup *)group;
{
    if ([_cameraSource isGroupStickerUsed:group])
    {
        [_cameraSource removeAllLiveSticker];
    }
    else
    {
        [_cameraSource showGroupSticker:group];
    }
    
}
#pragma mark - TuSDKLiveCameraSourceDelegate

/**
 *  经过处理的帧数据
 *
 *  @param source      TuSDKLiveCameraSource
 *  @param pixelBuffer CVPixelBufferRef对象
 */
- (void)videoSource:(TuSDKLiveCameraSource *)source newPixelBuffer:(CVPixelBufferRef)pixelBuffer time:(CMTime)frameTime;
{
    [_kit.streamerBase processVideoPixelBuffer:pixelBuffer timeInfo:frameTime];
}

- (void)updatePreview:(UIImage *)img
{
    _previewView.image = img;
    
    [_previewView setNeedsDisplay];

}
@end
