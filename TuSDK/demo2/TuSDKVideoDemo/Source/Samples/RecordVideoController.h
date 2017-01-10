//
//  RecordVideoController.h
//  TuSDKVideoDemo
//
//  Created by Yanlin on 4/29/16.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import "SimpleVideoController.h"
#import "TuSDKRecordCameraSource.h"

/**
 *  视频录制相机示例
 */
@interface RecordVideoController : SimpleVideoController

/**
 *  是否有访问系统相册权限
 */
@property (nonatomic, readonly) BOOL hasAlbumAccess;

/**
 *  相机画幅
 */
@property (nonatomic) NSUInteger cameraSizeType;

@end
