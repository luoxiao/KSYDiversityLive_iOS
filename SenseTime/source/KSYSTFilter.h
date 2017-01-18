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
@property (nonatomic , readwrite) SenseArMaterial *currentMaterial;
@property (nonatomic , readwrite) NSMutableArray  *arrStickers;
//下载素材
- (void)downLoadMetarials;
- (void)changeSticker;
@end
