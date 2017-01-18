//
//  TuSDKLocalSmartStickerDataSource.h
//  TuSDKVideoDemo
//
//  Created by Yanlin Qiu on 09/12/2016.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuSDKFramework.h"

@interface TuSDKLocalSmartStickerDataSource : NSObject <UITableViewDataSource>

/**
 单元格宽度
 */
@property (nonatomic) NSUInteger cellWidth;

/**
 单元格高度
 */
@property (nonatomic) NSUInteger cellHeight;

/**
 单元格旋转角度
 */
@property (nonatomic) CGFloat cellRotation;


/**
 根据索引获取本地贴纸组

 @param index 索引
 @return 贴纸组对象
 */
- (TuSDKPFStickerGroup *)getGroupAtIndex:(NSUInteger)index;

@end
