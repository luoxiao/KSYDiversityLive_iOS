//
//  LiveProcessorController.h
//  TuSDKVideoDemo
//
//  Created by Yanlin on 4/18/16.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimpleVideoController.h"

/**
 *  视频直播引擎示例
 *  用户自己控制相机，引擎负责处理每帧画面，并返回处理后的帧数据
 */
@interface LiveProcessorController : SimpleVideoController

/**
 *  房间信息
 */
@property (nonatomic, retain) NSDictionary *roomInfo;

/**
 *  推流状态
 */
@property (nonatomic, readonly) UILabel *mStatusLabel;

@end
