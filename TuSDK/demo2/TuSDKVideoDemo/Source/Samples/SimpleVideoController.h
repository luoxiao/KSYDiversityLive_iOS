//
//  SimpleVideoController.h
//  TuSDKVideoDemo
//
//  Created by Yanlin on 5/11/16.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TuSDKFramework.h"

@interface SimpleVideoController : UIViewController
{
    @protected
    // 开启静音按钮
    BOOL _muteButtonEnabled;
    
    // 视频输出视图
    UIView *_cameraView;
    
    // 美颜是否开启，默认：NO
    BOOL _beautyEnabled;
    
    // 直播滤镜列表
    NSArray *_videoFilters;
    
    // 当前的滤镜索引
    NSInteger _videoFilterIndex;
    
    // 贴纸选择列表
    UITableView *_stickerList;
}

/**
 *  控制按钮
 */
@property (readonly, nonatomic) UIButton *mActionButton;

/**
 *  美颜按钮
 */
@property (readonly, nonatomic) UIButton *mFilterButton;

/**
 *  切换前后摄像头
 */
@property (readonly, nonatomic) UIButton *mToggleCameraButton;

/**
 *  闪光灯
 */
@property (readonly, nonatomic) UIButton *mFlashButton;

/**
 *  静音按钮
 */
@property (readonly, nonatomic) UIButton *mMuteButton;

/**
 *  帧率控制
 */
@property (nonatomic, readonly) UIButton *mSettingButton;

/**
 *  关闭按钮
 */
@property (nonatomic, readonly) UIButton *mCloseButton;


/**
 *  闪光灯索引
 */
@property (nonatomic, readwrite) NSInteger flashModeIndex;


@property (nonatomic, strong) dispatch_queue_t sessionQueue;


/**
 *  构建界面元素
 */
- (void)lsqInitView;

/**
 *  创建贴纸列表
 */
- (void)initStickerListView;

/**
 *  更新操作按钮
 *
 *  @param isRunning 是否直播中
 */
- (void)updateShowStatus:(BOOL)isRunning;

- (void)updateBeautyStatus:(BOOL)isBeautyEnabled;


- (void)updateMuteStatus:(BOOL)isMuted;

- (void)updateFlashModeStatus;


- (void)onConfigButtonClicked:(id)sender;


/**
 点击底部的运行按钮

 @param sender 点击对象
 */
- (void)onActionHandle:(id)sender;


/**
 切换滤镜

 @param code 滤镜代号
 */
- (void)switchFilter:(NSString *)code;


/**
 选中了某个贴纸组

 @param group 贴纸组
 */
- (void)onStickerGroupSelected:(TuSDKPFStickerGroup *)group;

@end
