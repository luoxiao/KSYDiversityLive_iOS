//
//  KSYSTFilter.h
//  SenseArLiveBroadcastingSample
//
//  Created by 孙健 on 2017/1/14.
//  Copyright © 2017年 SenseTime. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface KSYSTFilter : GPUImageOutput<GPUImageInput>
- (id)initWithTarget:(GPUImageOutput<GPUImageInput> *)target
               width:(CGFloat)width
              height:(CGFloat)height;

@property (nonatomic , copy) NSString *strBroadcasterID;

@end
