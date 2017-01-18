//
//  MainViewController.m
//  TuSDKVideoDemo
//
//  Created by Yanlin on 3/5/16.
//  Copyright © 2016 TuSDK. All rights reserved.
//

#import "MainViewController.h"
#import "LiveVideoController.h"
#import "LiveProcessorController.h"
#import "RecordVideoController.h"

#pragma mark - DemoRootView
/**
 *  演示选择
 */
@protocol DemoChooseDelegate <NSObject>
/**
 *  选中一个演示
 *
 *  @param index 演示索引
 */
- (void)onDemoChoosedWithIndex:(NSInteger)index;
@end

/**
 *  入口视图
 */
@interface DemoRootView : UIView<UITableViewDelegate, UITableViewDataSource>{
    // 表格视图
    TuSDKICTableView *_tableView;
    // 缓存标记
    NSString *_cellIdentifier;
    // 演示列表
    NSArray *_demos;
}

/**
 * 演示选择
 */
@property (nonatomic, assign) id<DemoChooseDelegate> delegate;
@end

@implementation DemoRootView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self lsqInitView];
    }
    return self;
}

- (void)lsqInitView;
{
    // 缓存标记
    _cellIdentifier = @"MainViewCellIdentify";
    
    // 演示列表
    _demos = @[NSLocalizedString(@"live_camera_sample", @"直播相机示例"),
               NSLocalizedString(@"live_processor_sample", @"图像引擎示例"),
//               NSLocalizedString(@"record_camera_sample", @"视频录制示例"),
//               NSLocalizedString(@"record_camera_square_sample", @"视频录制示例 - 正方画幅")
               ];
    
    // 表格视图
    _tableView = [TuSDKICTableView table];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.allowsMultipleSelection = NO;
    [self addSubview:_tableView];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (self.delegate) {
        [self.delegate onDemoChoosedWithIndex:indexPath.row];
    }
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return _demos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    TuSDKICTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:_cellIdentifier];
    if (!cell) {
        cell = [TuSDKICTableViewCell initWithReuseIdentifier:_cellIdentifier];
        //cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    cell.textLabel.font = lsqFontSize(15);
    cell.textLabel.text = _demos[indexPath.row];
    return cell;
}
@end

#pragma mark - MainViewController

@interface MainViewController ()<DemoChooseDelegate,TuSDKFilterManagerDelegate>
{
    
}

/**
 *  覆盖控制器视图
 */
@property (nonatomic, retain) DemoRootView *view;

@end

@implementation MainViewController
@dynamic view;

// 隐藏状态栏 for IOS7
- (BOOL)prefersStatusBarHidden;
{
    return YES;
}

- (void)loadView;
{
    [super loadView];
    
    // 设置全屏 隐藏状态栏 for IOS6
    self.wantsFullScreenLayout = YES;
    [self setNavigationBarHidden:NO animated:NO];
    [self setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    self.view = [DemoRootView initWithFrame:CGRectMake(0, 0, lsqScreenWidth, lsqScreenHeight)];
    self.view.backgroundColor = lsqRGB(255, 255, 255);
    self.view.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"app_name", @"TuSDK 涂图"), lsqVideoVersion ];
    
    // 启动GPS
    [[TuSDKTKLocation shared] requireAuthorWithController:self];
    
    // sdk统计代码，请不要加入您的应用
    [TuSDKTKStatistics appendWithComponentIdt:tkc_sdkComponent];
    
    // 异步方式初始化滤镜管理器
    // 需要等待滤镜管理器初始化完成，才能使用所有功能
    [TuSDK checkManagerWithDelegate:self];
}

#pragma mark - TuSDKFilterManagerDelegate
/**
 * 滤镜管理器初始化完成
 *
 * @param manager
 *            滤镜管理器
 */
- (void)onTuSDKFilterManagerInited:(TuSDKFilterManager *)manager;
{
    // 初始化完成
    NSLog(@"TuSDK inited");
}
#pragma mark - DemoChooseDelegate
/**
 *  选中一个演示
 *
 *  @param index 演示索引
 */
- (void)onDemoChoosedWithIndex:(NSInteger)index;
{
    switch (index) {
        case 0:
            // 视频直播相机
            [self openLiveCamera];
            break;
        case 1:
            // 视频直播，相机 + 图像引擎
            [self openEngineSample];
            break;
        case 2:
            // 视频录制
            [self openRecordCameraWithRatio:0];
            break;
        case 3:
            // 视频录制
            [self openRecordCameraWithRatio:1];
            break;
        case 4:
            // 视频录制
            [self openRecordCameraWithRatio:2];
            break;
        default:
            break;
    }
}

- (void)openLiveCamera
{
    LiveVideoController *vc = [LiveVideoController new];
    [self.navigationController presentViewController:vc animated:YES completion:^{
        //
    }];
}

- (void)openEngineSample
{
    LiveProcessorController *vc = [LiveProcessorController new];
    [self.navigationController presentViewController:vc animated:YES completion:^{
        //
    }];}

- (void)openRecordCameraWithRatio:(NSUInteger)cameraSizeType
{
    RecordVideoController *vc = [RecordVideoController new];
    vc.cameraSizeType = cameraSizeType;
    
    [self.navigationController presentViewController:vc animated:YES completion:^{
        //
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
