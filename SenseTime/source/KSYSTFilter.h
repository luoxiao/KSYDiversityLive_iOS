//
//  KSYSTFilterThree.h
//  KSYLiveDemo
//
//  Created by 孙健 on 2017/1/16.
//  Copyright © 2017年 qyvideo. All rights reserved.
//

#import <GPUImage/GPUImage.h>
#import "senseAr.h"

@interface KSYSTFilter : GPUImageOutput<GPUImageInput>

//初始化appid
-(id)initWithAppid:(NSString *)appID
            appKey:(NSString *)appKey;

//下载素材
- (void)changeSticker:(int)index;
@end
