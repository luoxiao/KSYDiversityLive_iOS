//
//  TuSDKMovieEditor.h
//  TuSDKVideo
//
//  Created by Yanlin Qiu on 19/12/2016.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import "TuSDKVideoImport.h"
#import "TuSDKMovieEditorBase.h"

#pragma mark - TuSDKMovieEditorDelegate
@class TuSDKMovieEditor;
/**
 *  视频编辑器事件委托
 */
@protocol TuSDKMovieEditorDelegate

/**
 *  视频处理进度通知
 *
 *  @param editor  编辑器
 *  @param process 进度 (0~1)
 */
- (void)onMovieEditor:(TuSDKMovieEditor *)editor process:(CGFloat)process;

/**
 *  视频处理完成
 *
 *  @param editor      编辑器
 *  @param resultAsset Asset对象
 */
- (void)onMovieEditor:(TuSDKMovieEditor *)editor resultAsset:(id<TuSDKTSAssetInterface>)videoAsset;

/**
 *  视频处理出错
 *
 *  @param editor 编辑器
 *  @param error  错误对象
 */
- (void)onMovieEditor:(TuSDKMovieEditor *)editor failedWithError:(NSError*)error;

@end

/**
 *  视频编辑
 */
@interface TuSDKMovieEditor : TuSDKMovieEditorBase

/**
 *  编辑器事件委托
 */
@property (nonatomic, weak) id<TuSDKMovieEditorDelegate> editorDelegate;

/**
 *  输入视频源 URL > Asset
 */
@property (nonatomic) NSURL *inputURL;

/**
 *  输入视频源 URL > Asset
 */
@property (nonatomic) AVAsset *inputAsset;

@end
