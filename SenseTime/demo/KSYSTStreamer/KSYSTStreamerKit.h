//
//  KSYSTStreamerKit.h
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/24.
//  Copyright © 2016年 孙健. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <libksygpulive/libksygpulive.h>
#import <libksygpulive/libksygpuimage.h>
#import "KSYSTFilter.h"

@interface KSYSTStreamerKit : NSObject
//property
@property (nonatomic, readonly) KSYGPUCamera       *vCapDev;
@property (nonatomic, readonly) GPUImageCropFilter  *cropfilter;
@property (nonatomic, readonly) GPUImageOutput<GPUImageInput>* filter;
@property (nonatomic, readonly) KSYGPUPicMixer        *vPreviewMixer;
@property (nonatomic, readonly) KSYGPUPicMixer        *vStreamMixer;
@property (nonatomic, readonly) GPUImageView          *preview;
@property (nonatomic, readonly) KSYGPUPicOutput         *gpuToStr;
@property (nonatomic, readonly) KSYStreamerBase        *streamerBase;
/** 摄像头图层 */
@property (nonatomic, readonly) NSInteger cameraLayer;
/** logo 图片的图层 */
@property (nonatomic, readonly) NSInteger logoPicLayer;
/** logo 文字的图层 */
@property (nonatomic, readonly) NSInteger logoTxtLayer;
@property (nonatomic, readonly) KSYSTFilter *ksyStFilter;//对它进行操作
@property (nonatomic, readonly) KSYGPUPicOutput         *texToBuf;
@property (nonatomic, readonly) GPUImageTextureInput    *texInput;

//method
- (instancetype) initWithDefaultCfg;
- (void) startPreview: (UIView*) view;
@end
