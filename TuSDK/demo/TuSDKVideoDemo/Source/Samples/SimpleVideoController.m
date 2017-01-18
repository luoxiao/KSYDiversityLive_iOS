//
//  SimpleVideoController.m
//  TuSDKVideoDemo
//
//  Created by Yanlin on 5/11/16.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import "SimpleVideoController.h"
#import "TuSDKLocalSmartStickerDataSource.h"

@interface SimpleVideoController ()<UIGestureRecognizerDelegate, UITableViewDelegate>
{
    // 滑动切换滤镜
    UISwipeGestureRecognizer *_leftSwipeGestureHandler;
    
    UISwipeGestureRecognizer *_rightSwipeGestureHandler;
    
    BOOL uiInited;

    
    TuSDKLocalSmartStickerDataSource *_smartStickerSource;
}

@end

@implementation SimpleVideoController

// 隐藏状态栏 for IOS7
- (BOOL)prefersStatusBarHidden;
{
    return YES;
}

- (void)loadView;
{
    [super loadView];
    
    self.view.backgroundColor = lsqRGB(255, 255, 255);
    
    // 设置全屏 隐藏状态栏 for IOS6
    self.wantsFullScreenLayout = YES;
    [self setNavigationBarHidden:YES];
    [self setStatusBarHidden:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 默认不显示静音按钮
    _muteButtonEnabled = NO;
    
    self.view.backgroundColor = lsqRGB(255, 255, 255);
    
    
    _sessionQueue = dispatch_queue_create("org.lasque.tusdkvideo", DISPATCH_QUEUE_SERIAL);
    
    _leftSwipeGestureHandler = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeGesture:)];
    _rightSwipeGestureHandler = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeGesture:)];
    
    _leftSwipeGestureHandler.direction = UISwipeGestureRecognizerDirectionLeft;
    _rightSwipeGestureHandler.direction = UISwipeGestureRecognizerDirectionRight;
    _leftSwipeGestureHandler.delegate = self;
    _rightSwipeGestureHandler.delegate = self;
    
    if (_videoFilters.count > 1)
    {
        [self.view addGestureRecognizer:_leftSwipeGestureHandler];
        [self.view addGestureRecognizer:_rightSwipeGestureHandler];
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!uiInited)
    {
        [self lsqInitView];
        
        [self initStickerListView];
        
        [self updateBeautyStatus:_beautyEnabled];
        
        uiInited = YES;
    }
}

#pragma mark - init view

/**
 *  构建界面元素
 */
- (void)lsqInitView
{
    // 顶部工具栏按钮
    CGRect rect = [[UIScreen mainScreen] applicationFrame];
    
    // 添加视频预览图层
    _cameraView = [[UIView alloc] initWithFrame:rect];
    [self.view insertSubview:_cameraView atIndex:0];

    
    CGFloat buttonWidth = 44;
    CGFloat margin = 16;
    
    NSUInteger buttonNum = _muteButtonEnabled? 6 : 5;
    
    CGFloat padding = (rect.size.width - margin * 2 - buttonWidth * buttonNum)/(buttonNum-1);
    
    _mCloseButton = [self buildConfigButton:@"icon_closed" frame:CGRectMake(margin, 0, buttonWidth, buttonWidth)];
    _mFilterButton = [self buildConfigButton:@"icon_beauty_off" frame:CGRectMake(margin + (buttonWidth + padding)*1, 0, buttonWidth, buttonWidth)];
    _mSettingButton = [self buildConfigButton:nil frame:CGRectMake(margin + (buttonWidth + padding)*1.5, 0, buttonWidth * 2, buttonWidth)];
    [_mSettingButton setTitle:@"推流" forState:UIControlStateNormal];
    [_mSettingButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    _mFlashButton = [self buildConfigButton:@"icon_flash_off" frame:CGRectMake(margin + (buttonWidth + padding)*3, 0, buttonWidth, buttonWidth)];
    if (_muteButtonEnabled)
    {
        _mMuteButton = [self buildConfigButton:@"icon_volume_on" frame:CGRectMake(margin + (buttonWidth + padding)*4, 0, buttonWidth, buttonWidth)];
        _mToggleCameraButton = [self buildConfigButton:@"icon_camera_flip" frame:CGRectMake(margin + (buttonWidth + padding)*5, 0, buttonWidth, buttonWidth)];
    }
    else
    {
        _mToggleCameraButton = [self buildConfigButton:@"icon_camera_flip" frame:CGRectMake(margin + (buttonWidth + padding)*4, 0, buttonWidth, buttonWidth)];
    }
    
    // 底部操作按钮
    buttonWidth = 64;
    _mActionButton = [[UIButton alloc] initWithFrame:CGRectMake((rect.size.width - buttonWidth)/2, rect.size.height - buttonWidth - 16, buttonWidth, buttonWidth)];
    
    UIImage *image = [UIImage imageNamed:@"icon_play"];
    [_mActionButton setImage:image forState:UIControlStateNormal];
    [_mActionButton setAdjustsImageWhenHighlighted:NO];
    [_mActionButton setBackgroundColor:lsqRGB(0xff, 0x55, 0x34)];
    _mActionButton.layer.cornerRadius = buttonWidth/2;
    [_mActionButton addTouchUpInsideTarget:self action:@selector(onActionHandle:)];
    _mActionButton.hidden = YES;
    [self.view addSubview:_mActionButton];
}

/**
 *  创建贴纸列表
 */
- (void)initStickerListView;
{
    // 顶部工具栏按钮
    CGRect rect = [[UIScreen mainScreen] applicationFrame];
    
    _smartStickerSource = [[TuSDKLocalSmartStickerDataSource alloc] init];
    
    NSUInteger cellWidth = 80;
    // 旋转
    CGFloat mainRotate = -M_PI * 0.5f;
    
    _smartStickerSource.cellWidth = cellWidth;
    _smartStickerSource.cellHeight = cellWidth;
    _smartStickerSource.cellRotation = -mainRotate;
    
    // 列表视图
    _stickerList = [UITableView initWithFrame:CGRectMake(15, rect.size.height - cellWidth - 10, cellWidth, rect.size.width - 30)];
    _stickerList.separatorStyle = UITableViewCellSeparatorStyleNone;
    _stickerList.backgroundColor = [UIColor clearColor];
    _stickerList.showsVerticalScrollIndicator = NO;
    _stickerList.showsHorizontalScrollIndicator = NO;
    _stickerList.directionalLockEnabled = YES;
    _stickerList.delegate = self;
    _stickerList.dataSource = _smartStickerSource;
    [self.view addSubview:_stickerList];
    
    // 列表视图旋转为水平方向
    [_stickerList rotationWithAngle:mainRotate];
    [_stickerList setOrigin:CGPointMake(15, rect.size.height - cellWidth - 10)];
}

- (UIButton *)buildConfigButton:(NSString *)iconName frame:(CGRect)frame
{
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    
    UIImage *image = [UIImage imageNamed:iconName];
    [btn setImage:image forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onConfigButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn];
    return btn;
}

#pragma mark - button click handler

- (void)onConfigButtonClicked:(id)sender
{
    
}

- (void)onActionHandle:(id)sender
{
    
}

- (void)switchFilter:(NSString *)code
{
    
}

#pragma mark - swipe gesture for changing filter

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ([touch.view isKindOfClass:[TuSDKVideoFocusTouchView class]] || touch.view == self.view) ;
}

- (void)onSwipeGesture:(UISwipeGestureRecognizer *)sender;
{
    if (!_beautyEnabled) return;
    
    if (sender.direction == UISwipeGestureRecognizerDirectionRight)
    {
        _videoFilterIndex--;
        
        if (_videoFilterIndex < 0)
        {
            _videoFilterIndex = _videoFilters.count - 1;
        }
    }
    else
    {
        _videoFilterIndex++;
        
        if (_videoFilterIndex >= _videoFilters.count)
        {
            _videoFilterIndex = 0;
        }
    }
    
    NSString *code = [_videoFilters objectAtIndex:_videoFilterIndex];
    
    [self switchFilter:code];
    
    NSString *key = [NSString stringWithFormat:@"lsq_filter_%@", code];
    [[TuSDK shared].messageHub showToast:NSLocalizedString(key, @"")];
}


#pragma mark - update view status

/**
 *  更新操作按钮
 *
 *  @param isRunning 是否直播中
 */
- (void)updateShowStatus:(BOOL)isRunning
{
    NSString *imageName = isRunning ? @"icon_pause" : @"icon_play";
    UIImage *image = [UIImage imageNamed:imageName];
    [_mActionButton setImage:image forState:UIControlStateNormal];
}

- (void)updateBeautyStatus:(BOOL)isBeautyEnabled
{
    NSString *imageName = isBeautyEnabled ? @"icon_beauty_on" : @"icon_beauty_off";
    
    UIImage *image = [UIImage imageNamed:imageName];
    [_mFilterButton setImage:image forState:UIControlStateNormal];
    
    NSString *key = isBeautyEnabled ? @"beauty_on" : @"beauty_off";
    
    [[TuSDK shared].messageHub showToast:NSLocalizedString(key, @"")];
}

- (void)updateMuteStatus:(BOOL)isMuted
{
    NSString *imageName = isMuted ? @"icon_volume_off" : @"icon_volume_on";
    
    UIImage *image = [UIImage imageNamed:imageName];
    [_mMuteButton setImage:image forState:UIControlStateNormal];
}

- (void)updateFlashModeStatus
{
    NSString *imageName = @"";
    
    if (_flashModeIndex == 2)
    {
        imageName = @"icon_flash_auto";
    }
    else if(_flashModeIndex == 1)
    {
        imageName = @"icon_flash_on";
    }
    else
    {
        imageName = @"icon_flash_off";
    }
    
    UIImage *image = [UIImage imageNamed:imageName];
    [_mFlashButton setImage:image forState:UIControlStateNormal];
    
    //[_mFlashButton setEnabled:_camera.avPostion == AVCaptureDevicePositionBack];
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

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return _smartStickerSource.cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSInteger index = indexPath.row;
    
    TuSDKPFStickerGroup *data = [_smartStickerSource getGroupAtIndex:index];
    if (!data) return;
    
    [self onStickerGroupSelected:data];
}

/**
 选中了某个贴纸组
 
 @param group 贴纸组
 */
- (void)onStickerGroupSelected:(TuSDKPFStickerGroup *)group;
{
    
}
@end
