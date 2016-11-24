//
//  KSYSTYUVInput.h
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/22.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import <GPUImage/GPUImage.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@protocol KSYSTFilterDelegate <NSObject>

- (void)videoOutputWithTexture:(unsigned int)textOutput
                          size:(CGSize)size
                          time:(CMTime)timeInfo;
@end


@interface KSYSTFilter : NSObject

@property (nonatomic, weak) id<KSYSTFilterDelegate>delegate;

- (id)initWithEAContext:(EAGLContext *)context;
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer
                      time:(CMTime)timeInfo;
- (void)stChangeSicker;

@end
