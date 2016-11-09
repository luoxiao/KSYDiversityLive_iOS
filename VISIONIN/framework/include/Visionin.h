//
//  Visionin.h
//  Visionin
//
//  Created by Rex on 16/2/25.
//  Copyright © 2016年 Rex. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "VSVideoCamera.h"

@interface Visionin : NSObject
+(void)initialize:(NSString*)appId appKey:(NSString*)appKey;
+(void)setDebug:(BOOL)debug;
+(BOOL)authorization;
@end