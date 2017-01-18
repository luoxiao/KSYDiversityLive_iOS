//
//  StickerListCell.h
//  TuSDKVideoDemo
//
//  Created by Yanlin Qiu on 20/10/2016.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TuSDKFramework.h"

#pragma mark - StickerLocalGridView
/**
 *  贴纸缩略图
 */
@interface StickerThumbView : UIButton
{
    // 图片视图
    UIImageView *_thumbView;
}

/**
 *  图片边距
 */
@property (nonatomic) NSInteger innerWarpSpace;

/**
 *  图片视图
 */
@property(nonatomic,readonly) UIImageView *thumbView;

/**
 *  贴纸对象数据
 */
@property (nonatomic, retain) TuSDKPFStickerGroup *data;

/**
 *  需要重置视图
 */
-(void)viewNeedRest;

/**
 *  绘制成圆形
 */
- (void)makeRadius;
@end


#pragma mark - StickerListCell

@interface StickerListCell : UITableViewCell

/**
 *  单元格视图
 */
@property (nonatomic, readonly) StickerThumbView *gridView;

/**
 *  图片边距
 */
@property (nonatomic) NSInteger innerWarpSpace;

/**
 贴纸组对象
 */
@property (nonatomic, retain) TuSDKPFStickerGroup *stickerGroup;

@end


