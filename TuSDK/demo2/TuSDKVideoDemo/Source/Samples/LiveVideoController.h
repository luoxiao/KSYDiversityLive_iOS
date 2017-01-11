//
//  LiveVideoController.h
//  TuSDKVideoDemo
//
//  Created by Yanlin on 4/18/16.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimpleVideoController.h"
#import "KSYPresetCfgView.h"

/**
 *  视频直播相机示例
 *  访问相机，显示预览，并返回处理后的帧数据。
 */
@interface LiveVideoController : SimpleVideoController
@property (nonatomic, strong) KSYPresetCfgView *cfgview;
@end
