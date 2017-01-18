//
//  TuSDKLocalSmartStickerDataSource.m
//  TuSDKVideoDemo
//
//  Created by Yanlin Qiu on 09/12/2016.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import "TuSDKLocalSmartStickerDataSource.h"
#import "StickerListCell.h"

@interface TuSDKLocalSmartStickerDataSource()
{
    NSArray<TuSDKPFStickerGroup *> *_smartStickerGroups;
    
    // 缓存标记
    NSString *_stickerCellIdentifier;
}

@end

@implementation TuSDKLocalSmartStickerDataSource


- (instancetype)init;
{
    self = [super init];
    
    if (self)
    {
        [self initSource];
    }
    
    return self;
}

- (void)initSource;
{
    // 获取智能贴纸列表
    _smartStickerGroups = [[TuSDKPFStickerLocalPackage package] getSmartStickerGroups];
    
    // 缓存标记
    _stickerCellIdentifier = [NSString stringWithFormat:@"%@", [StickerListCell class]];
}

/**
 根据索引获取本地贴纸组
 
 @param index 索引
 @return 贴纸组对象
 */
- (TuSDKPFStickerGroup *)getGroupAtIndex:(NSUInteger)index;
{
    if (_smartStickerGroups == nil || index > _smartStickerGroups.count)
    {
        return nil;
    }
    return [_smartStickerGroups objectAtIndex:index];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    if (_smartStickerGroups)
        return _smartStickerGroups.count;
    
    return 0;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    StickerListCell * cell = [tableView dequeueReusableCellWithIdentifier:_stickerCellIdentifier];
    if (!cell) {
        cell = [[StickerListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_stickerCellIdentifier];
        [cell rotationWithAngle:_cellRotation];
        cell.innerWarpSpace = 2;
        cell.gridView.enabled = NO;
        [cell setSize:CGSizeMake(_cellWidth, _cellHeight)];
    }
    
    TuSDKPFStickerGroup *stickerGroup = [_smartStickerGroups objectAtIndex:indexPath.row];
    
    [cell viewNeedRest];
    cell.stickerGroup = stickerGroup;
    return cell;
}
@end
