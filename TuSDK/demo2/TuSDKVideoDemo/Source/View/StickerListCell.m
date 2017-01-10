//
//  StickerListCell.m
//  TuSDKVideoDemo
//
//  Created by Yanlin Qiu on 20/10/2016.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import "StickerListCell.h"

#pragma mark - StickerThumbView
/**
 *  贴纸缩略图
 */
@implementation StickerThumbView
- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        _thumbView = [UIImageView initWithFrame:self.bounds];
        _thumbView.contentMode = UIViewContentModeScaleAspectFill;
        [self makeRadius];
        [self addSubview:_thumbView];
    }
    return self;
}

- (UIImageView *)thumbView;
{
    return _thumbView;
}

-(void)viewNeedRest;
{
    self.hidden = YES;
    self.thumbView.image = nil;
    [[TuSDKPFStickerLocalPackage package] cancelLoadImage:self.thumbView];
}

-(void)setData:(TuSDKPFStickerGroup *)data;
{
    _data = data;
    if (!_data) return;
    
    self.hidden = NO;
    [[TuSDKPFStickerLocalPackage package]loadThumbWithStickerGroup:_data imageView:self.thumbView];
}

- (void)setInnerWarpSpace:(NSInteger)innerWarpSpace;
{
    if (innerWarpSpace >= 0)
    {
        _innerWarpSpace = innerWarpSpace;
        _thumbView.frame = CGRectMake(innerWarpSpace, innerWarpSpace, self.getSizeWidth - innerWarpSpace * 2, self.getSizeHeight - innerWarpSpace * 2);
    }
    [self makeRadius];
}

-(id)setSize:(CGSize)size;
{
    [super setSize:size];
    
    [_thumbView setSize:size];
    self.innerWarpSpace = self.innerWarpSpace;
    return self;
}

/**
 *  绘制成圆形
 */
- (void)makeRadius;
{
    [_thumbView setCornerRadius:8];
}
@end


#pragma mark - StickerListCell

@interface StickerListCell()
{
    // 单元格视图
    StickerThumbView *_gridView;
}
@end

@implementation StickerListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = lsqRGBA(1, 1, 1, 0.2);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self lsqInitView];
    }
    
    return self;
}


// 初始化视图
- (void)lsqInitView;
{
    // 单元格视图
    _gridView = [[StickerThumbView alloc] initWithFrame:self.bounds];
    [self addSubview:_gridView];
}

-(id)setSize:(CGSize)size;
{
    [super setSize:size];
    [_gridView setSize:size];
    return self;
}

- (void)setStickerGroup:(TuSDKPFStickerGroup *)stickerGroup
{
    _stickerGroup = stickerGroup;
    _gridView.data = stickerGroup;
}

// 重置视图
- (void)viewNeedRest;
{
    [_gridView viewNeedRest];
}

- (void)setInnerWarpSpace:(NSInteger)innerWarpSpace;
{
    _innerWarpSpace = innerWarpSpace;
    _gridView.innerWarpSpace = innerWarpSpace;
}
@end
