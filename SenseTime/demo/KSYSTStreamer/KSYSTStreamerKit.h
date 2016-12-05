//
//  KSYSTStreamerKit.h
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/24.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import <libksygpulive/libksygpulive.h>
#import <libksygpulive/libksygpuimage.h>
#import <libksygpulive/KSYGPUStreamerKit.h>
#import "KSYSTFilter.h"

@interface KSYSTStreamerKit : KSYGPUStreamerKit

@property (nonatomic, strong) KSYSTFilter *ksyStFilter;
@property (nonatomic, readonly) GPUImageOutput<GPUImageInput>* stFilter;
@property (nonatomic, readonly) KSYGPUPicMixer *texMix;

@end
