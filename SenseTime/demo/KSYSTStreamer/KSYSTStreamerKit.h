//
//  KSYSTStreamerKit.h
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/24.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import <libksygpulive/libksygpulive.h>
#import <libksygpulive/KSYGPUStreamerKit.h>
#import "KSYSTFilter.h"

@interface KSYSTStreamerKit : KSYGPUStreamerKit
@property (nonatomic, readonly) KSYSTFilter *ksyStFilter;//对它进行操作
@property (nonatomic, readonly) KSYGPUPicOutput *rgbOutput;
@property (nonatomic, readonly) GPUImageTextureInput *textInput;
@end
