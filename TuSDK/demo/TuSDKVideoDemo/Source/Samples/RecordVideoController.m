//
//  RecordVideoController.m
//  TuSDKVideoDemo
//
//  Created by Yanlin on 4/29/16.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import "RecordVideoController.h"
#import "FilterConfigView.h"

#pragma mark - RecordVideoController

/**
 *  视频录制相机示例
 */
@interface RecordVideoController () <TuSDKRecordCameraSourceDelegate>
{
    // 录制相机
    TuSDKRecordCameraSource *_camera;
}

@end

#pragma mark - RecordVideoController

@implementation RecordVideoController

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

- (void)loadView
{
    [super loadView];
    
    // 滤镜列表
    _videoFilters = @[@"VideoFair", @"VideoWhiteSkin", @"VideoYoungGirl", @"VideoHuaJiao", @"VideoJelly"];
    _videoFilterIndex = 0;
    
    //
    _muteButtonEnabled = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 测试相册访问权限
    [TuSDKTSAssetsManager testLibraryAuthor:^(NSError *error) {
        if (error) {
            [TuSDKTSAssetsManager showAlertWithController:self loadFailure:error];
        }else{
            _hasAlbumAccess = true;
        }
    }];

}

- (void)lsqInitView
{
    [super lsqInitView];
    
    self.mActionButton.hidden = NO;
    
    [self initSettingsAndStartPreview];
}

/**
 *  创建贴纸列表
 */
- (void)initStickerListView;
{
    [super initStickerListView];
    
    // 贴纸选择列表
    CGRect rect = _stickerList.frame;
    rect.origin.y -= 100;
    [_stickerList setFrame:rect];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopRunning];
}

- (void)initSettingsAndStartPreview
{
    
    // Off | On | Auto
    self.flashModeIndex = 0;
    
    [self updateFlashModeStatus];
    
    AVCaptureDevicePosition pos = [AVCaptureDevice lsqFirstFrontCameraPosition];
    
    if (!pos)
    {
        pos = [AVCaptureDevice lsqFirstBackCameraPosition];
    }
    
    _camera = [[TuSDKRecordCameraSource alloc] initWithCameraPosition:pos cameraView:_cameraView];
    
    _camera.cameraSizeType = _cameraSizeType;
    
    _camera.delegate = self;
    
    [_camera startCamera];
    
}

- (void)switchFilter:(NSString *)code
{
    dispatch_async(self.sessionQueue, ^{
        [_camera switchFilterCode:code];
    });
}

- (void)dealloc
{
    self.sessionQueue = nil;
    
    [_camera destroy];
}

#pragma mark - Operation

- (void)stopRunning
{
    [self updateShowStatus: NO];
    dispatch_async(self.sessionQueue, ^{
        [_camera stopRecording];
    });
}

- (void)startRunning
{
    
    [self updateShowStatus: YES];
    dispatch_async(self.sessionQueue, ^{
        [_camera startRecording];
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
        // 切换显示比例
    }
    else if (sender == self.mToggleCameraButton)
    {
        [_camera toggleCamera];
        
        [self.mFlashButton setEnabled:_camera.avPostion == AVCaptureDevicePositionBack];
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
            [_camera setFlashMode:[self getFlashModeByValue:self.flashModeIndex]];
        });
    }
}

- (void)updateFlashModeStatus
{
    [super updateFlashModeStatus];
    
    [self.mFlashButton setEnabled:_camera.avPostion != AVCaptureDevicePositionFront];
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
    if ([_camera isRecording])
    {
        [self stopRunning];
    }
    else
    {
        [self startRunning];
    }
}

#pragma mark - smart sticker handle

/**
 选中了某个贴纸组
 
 @param group 贴纸组
 */
- (void)onStickerGroupSelected:(TuSDKPFStickerGroup *)group;
{
    if ([_camera isGroupStickerUsed:group])
    {
        [_camera removeAllLiveSticker];
    }
    else
    {
        [_camera showGroupSticker:group];
    }
    
}

#pragma mark - TuSDKRecordCameraSourceDelegate

/**
 *  视频录制完成
 *
 *  @param result   TuSDKVideoResult 对象
 */
- (void)onMovieRecordCompleted:(TuSDKVideoResult *)result;
{
    [self updateShowStatus:NO];
}

@end

