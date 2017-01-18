//
//  BroadcasterViewController.m
//  SenseArLiveBroadcastingSample
//
//  Created by sluin on 16/7/9.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import "BroadcasterViewController.h"
#import "AppDelegate.h"
#import "GoldViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <OpenGLES/ES2/glext.h>
#import "STGLView.h"
#import "STFrameBuffer.h"
#import "STCollectionViewCell.h"

#import "SenseAr.h"

#import "cam_live.h"

#import <CommonCrypto/CommonDigest.h>

#import "STFrameBuffer.h"

#define SCREEN_WIDTH  [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

#import "STMobileLog.h"

#import "STMaterialDisplayConfig.h"

//ksy streamer
#import <libksygpulive/libksygpulive.h>
#import <libksygpulive/libksygpuimage.h>
#import <libksygpulive/KSYGPUStreamerKit.h>


// 两种 check license 的方式 , 一种是根据 license 文件的路径 , 另一种是 license 文件的缓存选择应用场景合适的即可
#define CHECK_LICENSE_WITH_PATH 1

// 设置显示及视频编码帧率
#define kENCODE_FPS 20

// 提示动作标签停留时间
#define kACTION_TIP_STAY_TIME 2.0f

@interface BroadcasterViewController () <AVCaptureVideoDataOutputSampleBufferDelegate ,UICollectionViewDelegate , UICollectionViewDataSource , UIAlertViewDelegate>

{
    int _iImageWidth;
    int _iImageHeight;
    
    CVOpenGLESTextureRef _cvOriginalTexture;
    CVOpenGLESTextureCacheRef _cvTextureCache;
    
    GLuint _textureOriginalIn;
    GLuint _textureBeautifyOut;
    GLuint _textureStickerOut;
    
    GLuint _textureResult;
}


// SenseAR

@property (nonatomic , strong) SenseArMaterial *currentMaterial;
@property (nonatomic , strong) SenseArMaterial *prepareMaterial;
@property (nonatomic , strong) SenseArMaterialService *service;
@property (nonatomic , strong) SenseArBroadcasterClient *broadcaster;
@property (nonatomic , strong) SenseArMaterialRender *render;

@property (nonatomic , strong) dispatch_queue_t bufferQueue;
@property (nonatomic , strong) dispatch_queue_t streamingQueue;

@property (nonatomic , strong) NSCondition *encodeCondition;

// camera
@property (nonatomic , strong) AVCaptureSession *captureSession;
@property (nonatomic , strong) AVCaptureDevice *videoDevice;
@property (nonatomic , strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic , strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic , strong) AVCaptureConnection *videoConnection;

@property (nonatomic , strong) STGLView *preview;

@property (nonatomic , strong) EAGLContext *glRenderContext;

// encoding & streaming
@property (nonatomic) st_live_context_t *stLiveContext;
@property (nonatomic , assign) BOOL isStreaming;

@property (nonatomic , strong) STFrameBuffer *frameBuffer;

@property (nonatomic , strong) NSThread *encodingThread;


// ad list
@property (nonatomic , strong) NSMutableArray *arrAdvertisings;
@property (nonatomic , strong) NSMutableArray *arrStickers;

@property (weak, nonatomic) IBOutlet UICollectionView *adsCollectionView;

@property (weak, nonatomic) IBOutlet UIView *personInfoView;
@property (weak, nonatomic) IBOutlet UIImageView *fansAnimationView;
@property (weak, nonatomic) IBOutlet UIImageView *messageAnimationView;

@property (weak, nonatomic) IBOutlet UILabel *lblGold;
@property (weak, nonatomic) IBOutlet UILabel *lblAdGold;
@property (weak, nonatomic) IBOutlet UIView *introductionView;
@property (weak, nonatomic) IBOutlet UIImageView *introductionDetail;

@property (weak, nonatomic) IBOutlet UIButton *btnIntroduction;
@property (weak, nonatomic) IBOutlet UIButton *btnCloseAdList;
@property (weak, nonatomic) IBOutlet UIButton *btnAdTab;
@property (weak, nonatomic) IBOutlet UIButton *btnStickerTab;
@property (weak, nonatomic) IBOutlet UIButton *btnSreaming;

@property (nonatomic , assign) BOOL bShowStickerList;
@property (nonatomic , assign) BOOL isIntroductionViewShowing;
@property (nonatomic , assign) BOOL isAppActive;

@property (nonatomic , strong) NSCache *thumbnailCache;

@property (nonatomic , strong) NSTimer *timer;

@property (nonatomic , copy) NSString *strThumbnailPath;

@property (nonatomic , strong) NSFileManager *fManager;


@property (weak, nonatomic) IBOutlet UIView *adDetailView;

@property (weak, nonatomic) IBOutlet UILabel *lblAdName;
@property (weak, nonatomic) IBOutlet UILabel *lblAdAction;

@property (weak, nonatomic) IBOutlet UIImageView *adThumbView;
@property (weak, nonatomic) IBOutlet UIImageView *adActionView;
@property (weak, nonatomic) IBOutlet UIImageView *adPriceTypeView;
@property (weak, nonatomic) IBOutlet UILabel *lblAdIntroduction;
@property (weak, nonatomic) IBOutlet UIButton *btnStartShowAd;

@property (nonatomic , strong) SenseArMaterial *showingDetailMaterial;
@property (weak, nonatomic) IBOutlet UIButton *btnCloseDetail;

@property (weak, nonatomic) IBOutlet UILabel *lblPricingIntroduction;

@property (weak, nonatomic) IBOutlet UIImageView *actionTipImageView;
@property (weak, nonatomic) IBOutlet UILabel *lblActionTip;
@property (nonatomic , assign) double dLastActionTipPTS;

@property (nonatomic , strong) NSDictionary *dicMaterialDisplayConfig;
@property (nonatomic , strong) NSArray *arrLastMaterialParts;

@property (nonatomic , copy) NSString *strLastMaterialID;
@property (nonatomic , assign) BOOL isLastFrameTriggered;

@property (nonatomic, strong) KSYGPUStreamerKit *kit;
@property (nonatomic, strong) GPUImageTextureInput *tx_In;
@property (nonatomic, strong) GPUImageFilter *cu_filter;
@end

@implementation BroadcasterViewController

- (void)appWillResignActive
{
    self.isAppActive = NO;
}

- (void)appWillEnterForeground
{
    self.isAppActive = YES;
}

- (void)appDidBecomeActive
{
    self.isAppActive = YES;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil
     ];
    
    self.bufferQueue = dispatch_queue_create("com.sensetime.sensear.buffer", NULL);
    self.streamingQueue = dispatch_queue_create("com.sensetime.sensear.streaming", NULL);
    self.encodeCondition = [[NSCondition alloc] init];
    
    self.dLastActionTipPTS = 0.0;
    self.bShowStickerList = YES;
    self.isIntroductionViewShowing = NO;
    self.isStreaming = NO;
    self.isAppActive = YES;
    self.isLastFrameTriggered = NO;
    
    self.arrAdvertisings = [NSMutableArray array];
    self.arrStickers = [NSMutableArray array];
    
    
    // 默认的素材展示序列及子素材展示配置
    STMaterialDisplayConfig *config1 = [[STMaterialDisplayConfig alloc] init];
    config1.iTriggerType = SENSEAR_HAND_LOVE;
    config1.arrMaterialPartsSequence = @[@[@"ear", @"face", @"pink"],
                                         @[@"ear", @"face", @"yellow"],
                                         @[@"ear", @"face", @"purple"]];
    
    STMaterialDisplayConfig *config2 = [[STMaterialDisplayConfig alloc] init];
    config2.iTriggerType = SENSEAR_HAND_PALM;
    config2.arrMaterialPartsSequence = @[@[@"head", @"face", @"cocacolab"],
                                         @[@"head", @"face", @"jdba"],
                                         @[@"head", @"face", @"milk"]];
    
    self.dicMaterialDisplayConfig = @{
                                      @"20170109124245233850861" : config1 ,
                                      @"20170109124355279333705" : config2
                                      };
    
    // 根据 AVCaptureSession 设置的实际 sessionPreset 来设置宽高 , 因为使用了旋转 , 所以宽是短边 .
    _iImageWidth = 540;
    _iImageHeight = 960;
    
    [self.adsCollectionView registerNib:
     [UINib nibWithNibName:@"STCollectionViewCell"
                    bundle:[NSBundle mainBundle]]
             forCellWithReuseIdentifier:@"STCollectionViewCell"];
    
    // 设置缩略图缓存
    [self setupThumbnailCache];
    
    // 设置金币的label显示
    [self setupFakeGoldenView];
    
    // 展示粉丝聊天等动画
    [self showFakeAnimation];
    
    // 设置预览
//    [self setupPreview];
    
    // 验证 license
    [self checkActiveCode];
    
    // 设置渲染模块 , 美颜参数
    [self setupMaterialRender];
    
    // 设置并开启 SenseArService , 设置 SenseArBroadcaster
    [self setupSenseArServiceAndBroadcaster];
    
    // 配置相机
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        // 设置 AVCaptureSession .
//        if ([self setupCaptureSession]) {
//            
//            [self startCaptureSession];
//        }else{
//            
//            STLog(@"setup capture failed");
//            
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"AVCapture 设置失败" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
//            
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                
//                [alert show];
//            });
//        }
//    });
    //ksy initialized
    _kit = [[KSYGPUStreamerKit alloc] init];
    // 创建美颜和贴纸的结果纹理
    _tx_In = [[GPUImageTextureInput alloc] initWithTexture:_textureStickerOut size:CGSizeMake(720, 1280)];
    [_tx_In addTarget:self.kit.filter];
    [self setCapture];
    [self setStream];
    [self onBtnLock:nil];
    if (_kit) {
        [_kit startPreview:self.view];
    }
}

- (void)dealloc
{
    self.bufferQueue = NULL;
    self.streamingQueue = NULL;
    
    [self.thumbnailCache removeAllObjects];
    self.thumbnailCache = nil;
}


#pragma - mark -
#pragma - mark Check License

- (NSString *)getSHA1StringWithData:(NSData *)data
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    
    NSMutableString *strSHA1 = [NSMutableString string];
    
    for (int i = 0 ; i < CC_SHA1_DIGEST_LENGTH ; i ++) {
        
        [strSHA1 appendFormat:@"%02x" , digest[i]];
    }
    
    return strSHA1;
}

- (BOOL)checkActiveCode
{
    NSString *strLicensePath = [[NSBundle mainBundle] pathForResource:@"SENSEME" ofType:@"lic"];
    NSData *dataLicense = [NSData dataWithContentsOfFile:strLicensePath];
    
    NSString *strKeySHA1 = @"SENSEME";
    NSString *strKeyActiveCode = @"ACTIVE_CODE";
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *strStoredSHA1 = [userDefaults objectForKey:strKeySHA1];
    NSString *strLicenseSHA1 = [self getSHA1StringWithData:dataLicense];
    
    NSString *strActiveCode = nil;
    
    NSError *error = nil;
    BOOL bSuccess = NO;
    
    if (strStoredSHA1.length > 0 && [strLicenseSHA1 isEqualToString:strStoredSHA1]) {
        
        // Get current active code
        // In this app active code was stored in NSUserDefaults
        // It also can be stored in other places
        strActiveCode = [userDefaults objectForKey:strKeyActiveCode];
        
        // Check if current active code is available
#if CHECK_LICENSE_WITH_PATH
        
        // use file
        bSuccess = [SenseArMaterialService checkActiveCode:strActiveCode licensePath:strLicensePath error:&error];
#else
        
        // use buffer
        NSData *licenseData = [NSData dataWithContentsOfFile:strLicensePath];
        
        bSuccess = [SenseArMaterialService checkActiveCode:strActiveCode
                                               licenseData:licenseData
                                                     error:&error];
        
#endif
        
        if (bSuccess && !error) {
            
            // check success
            return YES;
        }
    }
    
    /*
     1. check fail
     2. new one
     3. update
     */
    
    
    // generate one
#if CHECK_LICENSE_WITH_PATH
    
    // use file
    strActiveCode = [SenseArMaterialService generateActiveCodeWithLicensePath:strLicensePath
                                                                        error:&error];
    
#else
    
    // use buffer
    strActiveCode = [SenseArMaterialService generateActiveCodeWithLicenseData:dataLicense
                                                                        error:&error];
#endif
    
    if (!strActiveCode.length && error) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"使用 license 文件生成激活码时失败，可能是授权文件过期。" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
        
        return NO;
        
    } else {
        
        // Store active code
        
        [userDefaults setObject:strActiveCode forKey:strKeyActiveCode];
        [userDefaults setObject:strLicenseSHA1 forKey:strKeySHA1];
        
        [userDefaults synchronize];
    }
    
    return YES;
}


- (void)setupSenseArServiceAndBroadcaster
{
    // 初始化服务
    self.service = [SenseArMaterialService shareInstnce];
    // 使用AppID , AppKey 进行授权 , 如果不授权将无法使用 SenseArMaterialService 相关接口 .
    [self.service authorizeWithAppID:@"7f76ce6bd292444b9368a7ba436c39fd"
                              appKey:@"fa8e3603044c41ff8dbbd5531624ab0d"
                           onSuccess:^{
                               
                               self.broadcaster = [[SenseArBroadcasterClient alloc] init];
                               
                               // 根据实际情况设置主播的属性
                               self.broadcaster.strID = self.strBroadcasterID;
                               self.broadcaster.strName = [@"name_" stringByAppendingString:self.strBroadcasterID];
                               self.broadcaster.strBirthday = @"19901023";
                               self.broadcaster.strGender = @"男";
                               self.broadcaster.strArea = @"北京市/海淀区";
                               self.broadcaster.strPostcode = @"067306";
                               self.broadcaster.latitude = 39.977813;
                               self.broadcaster.longitude = 116.317188;
                               self.broadcaster.iFollowCount = 2000;
                               self.broadcaster.iFansCount = 2000;
                               self.broadcaster.iAudienceCount = 6000;
                               self.broadcaster.strType = @"游戏";
                               self.broadcaster.strTelephone = @"13600000000";
                               self.broadcaster.strEmail = @"broadcasteriOS@126.com";
                               
                               SenseArConfigStatus iStatus = [self.service configureClientWithType:Broadcaster client:self.broadcaster];
                               
                               if (CONFIG_OK == iStatus) {
                                   
                                   // 设置缓存大小 , 默认为 100M
                                   [self.service setMaxCacheSize:120000000];
                                   
                                   // 开始直播
                                   [self.broadcaster broadcastStart];
                                   
                               }else{
                                   
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"服务配置失败" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                                   
                                   [alert show];
                               }
                               
                               
                           } onFailure:^(SenseArAuthorizeError iErrorCode) {
                               
                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"服务初始化失败" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                               
                               [alert show];
                           }];
}

- (void)setupMaterialRender
{
    // 记录调用 SDK 之前的渲染环境以便在调用 SDK 之后设置回来.
    EAGLContext *preContext = [self getPreContext];
    
    // 创建 OpenGL 上下文 , 根据实际情况与预览使用同一个 context 或 shareGroup .
    self.glRenderContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                                                            sharegroup:[GPUImageContext sharedImageProcessingContext].context.sharegroup];;
    
    // 调用 SDK 之前需要切换到 SDK 的渲染环境
    [self setCurrentContext:self.glRenderContext];
    
    // 创建美颜和贴纸的结果纹理
    activeAndBindTexture(GL_TEXTURE1, &_textureBeautifyOut, NULL, GL_RGBA, 720, 1280);
    
    activeAndBindTexture(GL_TEXTURE2, &_textureStickerOut, NULL, GL_RGBA, 720, 1280);
    
    // 获取模型路径
    NSString *strModelPath = [[NSBundle mainBundle] pathForResource:@"action3.1.0"
                                                             ofType:@"model"];
    // 根据实际需求决定是否开启美颜和动作检测
    self.render = [SenseArMaterialRender instanceWithModelPath:strModelPath
                                                        config:SENSEAR_ENABLE_HUMAN_ACTION |SENSEAR_ENABLE_BEAUTIFY
                                                       context:self.glRenderContext];
    
    
    if (self.render) {
        
        // 初始化渲染模块使用的 OpenGL 资源
        [self.render initGLResource];
        
        // 根据需求设置美颜参数
        if (![self.render setBeautifyValue:0.71 forBeautifyType:BEAUTIFY_CONTRAST_STRENGTH]) {
            
            STLog(@"set BEAUTIFY_CONTRAST_STRENGTH failed");
        }
        if (![self.render setBeautifyValue:0.71 forBeautifyType:BEAUTIFY_SMOOTH_STRENGTH]) {
            
            STLog(@"set BEAUTIFY_SMOOTH_STRENGTH failed");
        }
        if (![self.render setBeautifyValue:0.0 forBeautifyType:BEAUTIFY_WHITEN_STRENGTH]) {
            
            STLog(@"set BEAUTIFY_WHITEN_STRENGTH failed");
        }
        if (![self.render setBeautifyValue:0.11 forBeautifyType:BEAUTIFY_SHRINK_FACE_RATIO]) {
            
            STLog(@"set BEAUTIFY_SHRINK_FACE_RATIO failed");
        }
        if (![self.render setBeautifyValue:0.17 forBeautifyType:BEAUTIFY_ENLARGE_EYE_RATIO]) {
            
            STLog(@"set BEAUTIFY_ENLARGE_EYE_RATIO failed");
        }
        if (![self.render setBeautifyValue:0.2 forBeautifyType:BEAUTIFY_SHRINK_JAW_RATIO]) {
            
            STLog(@"set BEAUTIFY_SHRINK_JAW_RATIO failed");
        }
        
    }else{
        
        STLog(@"setupMaterialRender failed.");
    }
    
    // 需要设为之前的渲染环境防止与其他需要 GPU 资源的模块冲突.
    [self setCurrentContext:preContext];
}

#pragma - mark -
#pragma - mark Setup UI

- (void)setupFakeGoldenView
{
    NSString *strGlod = @" 金币: 3656566 >";
    NSMutableAttributedString *strAttrGlod = [[NSMutableAttributedString alloc] initWithString:strGlod];
    [strAttrGlod addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(1, 3)];
    [self.lblGold setAttributedText:strAttrGlod];
    
    NSString *strAdGlod = @" 广告币: 29567 >";
    NSMutableAttributedString *strAttrAdGlod = [[NSMutableAttributedString alloc] initWithString:strAdGlod];
    [strAttrAdGlod addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(1, 4)];
    
    [self.lblAdGold setAttributedText:strAttrAdGlod];
    
    UITapGestureRecognizer *tapGoldView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAdGoldView)];
    
    [self.lblAdGold setUserInteractionEnabled:YES];
    [self.lblAdGold addGestureRecognizer:tapGoldView];
    
    self.lblAdGold.hidden = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).bAgree ? NO : YES;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(randomTheGold) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    [self.timer fire];
}

- (void)showFakeAnimation
{
    // animation
    NSMutableArray *arrFansImages = [NSMutableArray array];
    
    for (int i = 0; i < 5; i ++) {
        
        UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"fans%d" , i] ofType:@"png"]];
        
        [arrFansImages addObject:image];
    }
    
    NSMutableArray *arrMessageImages = [NSMutableArray array];
    
    for (int i = 0; i < 6; i ++) {
        
        UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"chat%d" , i] ofType:@"png"]];
        
        [arrMessageImages addObject:image];
    }
    
    [self.fansAnimationView setAnimationImages:arrFansImages];
    [self.fansAnimationView setAnimationDuration:2.0];
    [self.fansAnimationView setAnimationRepeatCount:0];
    [self.fansAnimationView startAnimating];
    
    [self.messageAnimationView setAnimationImages:arrMessageImages];
    [self.messageAnimationView setAnimationDuration:2.0];
    [self.messageAnimationView setAnimationRepeatCount:0];
    [self.messageAnimationView startAnimating];
}

- (CGRect)getZoomedRectWithImageWidth:(int)iWidth height:(int)iHeight inRect:(CGRect)rect scaleToFit:(BOOL)bScaleToFit
{
    CGRect rectRet = rect;
    
    float fScaleX = iWidth / CGRectGetWidth(rect);
    float fScaleY = iHeight / CGRectGetHeight(rect);
    float fScale = bScaleToFit ? fmaxf(fScaleX, fScaleY) : fminf(fScaleX, fScaleY);
    
    iWidth /= fScale;
    iHeight /= fScale;
    
    CGFloat fX = rect.origin.x - (iWidth - rect.size.width) / 2.0f;
    CGFloat fY = rect.origin.y - (iHeight - rect.size.height) / 2.0f;
    
    rectRet.origin.x = fX;
    rectRet.origin.y = fY;
    rectRet.size.width = iWidth;
    rectRet.size.height = iHeight;
    
    return rectRet;
}

- (void)setupPreview
{
    CGRect displayRect = [self getZoomedRectWithImageWidth:_iImageWidth height:_iImageHeight inRect:self.view.bounds scaleToFit:NO];
    self.preview = [[STGLView alloc] initWithFrame:displayRect];
    [self.view insertSubview:self.preview atIndex:0];
}
#pragma - mark -
#pragma - mark KSYStreamer capture & stream config
- (void)setCapture{
    _kit.capPreset = AVCaptureSessionPreset1280x720;
    _kit.vCapDev.outputPixelFmt = kCVPixelFormatType_32BGRA;
    __weak typeof(self) weakSelf = self;
    //video call back
    _kit.vCapDev.videoProcessingCallback = ^(CMSampleBufferRef videoBuffer){
        [weakSelf processCMSampeBuffer:videoBuffer];
    };
    //audio call back
    _kit.audioProcessingCallback = ^(CMSampleBufferRef audioBuffer){
        
    };
}
- (void)setStream{
    _strRTMPURL = @"rtmp://test.uplive.ks-cdn.com/live/123";
}
- (void)processCMSampeBuffer:(CMSampleBufferRef)sampleBuffer{
    // 应用未激活状态不做任何渲染
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        
        return;
    }
    
    if (!self.isAppActive) {
        
        return;
    }
    
    // get pts
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    long lPTS = (long)(timestamp.value / (timestamp.timescale / 1000));
    TIMELOG(totalCost)
    
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    unsigned char * pBGRAImageInput = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    int iBytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    int iWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int iHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    size_t iTop , iLeft , iBottom , iRight = 0;
    CVPixelBufferGetExtendedPixels(pixelBuffer, &iLeft, &iRight, &iTop, &iBottom);
    
    iWidth += ((int)iLeft + (int)iRight);
    iHeight += ((int)iTop + (int)iBottom);
    
    iBytesPerRow += (iLeft + iRight);
    
    // 记录之前的渲染环境
    EAGLContext *preContext = [self getPreContext];
    // 设置 SDK 的渲染环境
    [self setCurrentContext:self.glRenderContext];
    
    GLuint textureBeautifyIn;
    activeAndBindTexture(GL_TEXTURE0, &textureBeautifyIn, pBGRAImageInput, GL_BGRA, iWidth, iHeight);
    
    // 用于推流的图像数据
    Byte *pNV12ImageOut = NULL;
    int iImageNV12Length = sizeof(Byte) * iWidth * iHeight * 3 / 2;
    
    // 分配渲染信息的内存空间
    Byte *pFrameInfo = (Byte *)malloc(sizeof(Byte) * 10000);
    memset(pFrameInfo, 0, 10000 * sizeof(Byte));
    int iInfoLength = 10000;
    
    SenseArRenderStatus iRenderStatus = RENDER_UNKNOWN;
    NSString *strCurrentMaterialID = self.currentMaterial.strID;
    
    // 渲染未授权时主播端渲染原图
    if (!self.render || ![SenseArMaterialService isAuthorizedForRender]) {
        
        iRenderStatus = RENDER_NOT_AUTHORIZED;
        _textureResult = _textureOriginalIn;
    }else{
        
        if (self.isStreaming) {
            
            pNV12ImageOut = (Byte *)malloc(iImageNV12Length);
            
            memset(pNV12ImageOut, 0, iImageNV12Length);
        }
        
        // 美颜输出
        [self.render setFrameWidth:iWidth height:iHeight stride:iBytesPerRow];
        
        SenseArRotateType iRotate = [self getRotateTypeWithDeviceOrientation];
        
        TIMELOG(beautifyCost)
        
        iRenderStatus = [self.render beautifyAndGenerateFrameInfo:pFrameInfo
                                                  frameInfoLength:&iInfoLength
                                                withPixelFormatIn:PIX_FMT_BGRA8888
                                                          imageIn:pBGRAImageInput
                                                        textureIn:textureBeautifyIn
                                                       rotateType:iRotate
                                                   needsMirroring:NO
                                                   pixelFormatOut:PIX_FMT_BGRA8888
                                                         imageOut:pNV12ImageOut
                                                       textureOut:_textureBeautifyOut];
        
        
        
        glFlush();
        
        TIMEPRINT(beautifyCost, "美颜")
        
        SenseArFrameActionInfo *currentFrameActionInfo = nil;
        
        // 美颜异常时可以避免黑屏可以渲染原图
        if (RENDER_SUCCESS != iRenderStatus) {
            
            _textureResult = _textureOriginalIn;
            
            // 美颜异常时输出不可用
            if (pNV12ImageOut) {
                
                free(pNV12ImageOut);
                pNV12ImageOut = NULL;
            }
        }else{
            
            currentFrameActionInfo = [self.render getCurrentFrameActionInfo];
            
            // 贴纸输出
            TIMELOG(stickerCost)
            
            // 如果需要直接推流贴纸后的效果 , imageOut 需要传入有效的内存 .
            iRenderStatus = [self.render renderMaterial:strCurrentMaterialID
                                          withFrameInfo:pFrameInfo
                                        frameInfoLength:iInfoLength
                                              textureIn:_textureBeautifyOut
                                             textureOut:_textureStickerOut
                                            pixelFormat:PIX_FMT_BGRA8888
                                               imageOut:NULL];
            
            glFlush();
            
            TIMEPRINT(stickerCost, "贴纸")
            
            // 当贴纸异常时可以渲染操作成功的结果以保证主播端不会黑屏 , 这里渲染美颜的输出纹理
            _textureResult = RENDER_SUCCESS == iRenderStatus ?
            _textureStickerOut : _textureBeautifyOut;
            
            if (self.currentMaterial && [self.dicMaterialDisplayConfig objectForKey:strCurrentMaterialID]) {
                
                if (![strCurrentMaterialID isEqualToString:self.strLastMaterialID]) {
                    
                    NSArray *arrCurrentMaterialParts = [self.render getMaterialParts];
                    
                    if (arrCurrentMaterialParts.count
                        && currentFrameActionInfo) {
                        
                        [self resetCurrentPartsIndexWithID:strCurrentMaterialID];
                        [self changeToNextPartsWithMaterialID:strCurrentMaterialID
                                                materialParts:arrCurrentMaterialParts];
                    }
                    
                    self.arrLastMaterialParts = arrCurrentMaterialParts;
                    self.isLastFrameTriggered = NO;
                    
                }else{
                    
                    if (self.arrLastMaterialParts.count
                        && currentFrameActionInfo) {
                        
                        BOOL isTriggered = [self isMaterialTriggered:strCurrentMaterialID
                                                     frameActionInfo:currentFrameActionInfo];
                        
                        if (!isTriggered && self.isLastFrameTriggered) {
                            
                            [self changeToNextPartsWithMaterialID:strCurrentMaterialID
                                                    materialParts:self.arrLastMaterialParts];
                        }
                        
                        self.isLastFrameTriggered = isTriggered;
                    }
                }
            }
        }
    }
    [_tx_In processTextureWithFrameTime:timestamp];
    self.strLastMaterialID = strCurrentMaterialID;
    glDeleteTextures(1, &textureBeautifyIn);
    
    // 恢复之前的渲染环境
    [self setCurrentContext:preContext];
    
    glFlush();
    
    // 可以在异常的情况下将原图编码推流以保证粉丝端不会因为异常而黑屏 , 需要根据具体的推流方案实现 , 这里在异常情况下不做推流 .
    if (self.isStreaming &&
        self.streamingQueue &&
        pNV12ImageOut &&
        iInfoLength > 0) {
        
        dispatch_async(self.streamingQueue, ^{
            
            STFrame *frame = [[STFrame alloc] init];
            frame.width = iWidth;
            frame.height = iHeight;
            frame.stride = iWidth;
            frame.imageData = [NSData dataWithBytes:pNV12ImageOut length:iImageNV12Length];
            frame.extraData = [NSData dataWithBytes:pFrameInfo length:iInfoLength];
            frame.pts = lPTS;
            
            free(pFrameInfo);
            free(pNV12ImageOut);
            
            [self.frameBuffer enqueueFrameToBuffer:frame];
            
            [self.encodeCondition lock];
            [self.encodeCondition signal];
            [self.encodeCondition unlock];
            
        });
        
    }else{
        
        free(pFrameInfo);
        free(pNV12ImageOut);
    }
    
    [self showActionTipsIfNeed];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    
    TIMEPRINT(totalCost, "总耗时")

}
#pragma - mark -
#pragma - mark Streaming & Encoding

- (BOOL)setupAndStartStreaming
{
    self.encodingThread = [[NSThread alloc] initWithTarget:self selector:@selector(encodeAndSendFrame) object:nil];
    [self.encodingThread setName:@"com.sensetime.sensear.encodeThread"];
    
    // 设置缓存帧数 , 保证预览的流畅度
    self.frameBuffer = [[STFrameBuffer alloc] initWithCapacity:10];
    
    st_live_context_t *stLiveContext = NULL;
    
    st_live_config_t stConfig;
    memset(&stConfig, 0, sizeof(stConfig));
    
    NSInteger iSysVersion = [[[UIDevice currentDevice] systemVersion] integerValue];
    
    // 可以根据实际情况设置软编码或硬编码 , 这里根据版本自动切换
    stConfig.codec = iSysVersion >= 8.0 ? ST_LIVE_CODEC_VIDEOTOOLBOX : ST_LIVE_CODEC_X264;
    stConfig.mode = "faster";
    // 可根据实际情况调整
    stConfig.video_bit_rate = 800000;
    
    int iRet = st_live_create_context(ST_LIVE_SINK_RTMP, [self.strRTMPURL UTF8String], &stConfig, &stLiveContext);
    
    if (iRet || !stLiveContext) {
        
        STLog(@"fail to init live streaming");
        
        return NO;
    }
    
    self.stLiveContext = stLiveContext;
    
    BOOL bStart = [self startStreamingAndEncoding];
    
    return bStart;
}

- (BOOL)startStreamingAndEncoding
{
    int iRet = st_live_start_streaming(
                                       self.stLiveContext,
                                       _iImageWidth,
                                       _iImageHeight,
                                       kENCODE_FPS,
                                       ST_LIVE_FMT_NV12);
    
    self.isStreaming = 0 == iRet;
    
    if (![self.encodingThread isExecuting]) {
        
        [self.encodingThread start];
    }
    
    return self.isStreaming;
}

// 编码并推流
- (void)encodeAndSendFrame
{
    while (1) {
        
        [self.encodeCondition lock];
        [self.encodeCondition wait];
        [self.encodeCondition unlock];
        
        if ([[NSThread currentThread] isCancelled]) {
            
            [NSThread exit];
            
        }else{
            
            @autoreleasepool {
                
                STFrame *frame = [self.frameBuffer readFrameFromBuffer];
                
                if (frame) {
                    
                    st_nv12_descriptor_t desc;
                    desc.Y_base = (unsigned char *)[frame.imageData bytes];
                    desc.Y_stride = frame.stride;
                    desc.CrBr_base = ((unsigned char *)[frame.imageData bytes] + (sizeof(unsigned char) * frame.stride * frame.height));
                    desc.CrBr_stride = frame.stride;
                    
                    TIMELOG(enqueueAndSendFrame)
                    
                    int iPublishRet = st_live_enqueue_frame(self.stLiveContext,  &desc, frame.pts, (void *)[frame.extraData bytes], (unsigned int)[frame.extraData length]);
                    
                    TIMEPRINT(enqueueAndSendFrame, "编码+推流")
                    
                    if (0 != iPublishRet) {
                        
                        STLog(@"st_live_enqueue_frame %d" , iPublishRet);
                    }
                }
            }
        }
    }
}


- (void)stopAndDestroyStreaming
{
    if (self.isStreaming) {
        
        self.isStreaming = NO;
        
        dispatch_sync(self.streamingQueue, ^{
            
            int iRet = st_live_stop_streaming(self.stLiveContext);
            
            if (0 != iRet) {
                
                STLog(@"st_live_stop_streaming failed .");
            }
        });
    }
    
    [self.encodingThread cancel];
    
    [self.encodeCondition lock];
    [self.encodeCondition signal];
    [self.encodeCondition unlock];
    
    [self destroyStreaming];
    
    [self.frameBuffer removeAllFrames];
}

- (void)destroyStreaming
{
    if (self.stLiveContext) {
        
        st_live_destroy_context(self.stLiveContext);
        
        self.stLiveContext = NULL;
    }
}

#pragma - mark -
#pragma - mark AVCapture

- (BOOL)setupCaptureSession
{
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // 根据实际需要修改 sessionPreset
    self.captureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540;
    
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionFront) {
                self.videoDevice = device;
            }
        }
    }
    
    NSError *error = nil;
    
    self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:&error];
    
    if (!self.videoDeviceInput || error) {
        
        STLog(@"create video device input failed.");
        
        return NO;
    }
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    [self.videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    if (!self.videoDataOutput) {
        
        return NO;
    }
    
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.bufferQueue];
    
    [self.captureSession beginConfiguration];
    
    if ([self.captureSession canAddInput:self.videoDeviceInput]) {
        [self.captureSession addInput:self.videoDeviceInput];
    }
    
    if ([self.captureSession canAddOutput:self.videoDataOutput]) {
        [self.captureSession addOutput:self.videoDataOutput];
    }
    
    CMTime frameDuration = CMTimeMake(1 , kENCODE_FPS);
    
    if ([self.videoDevice lockForConfiguration:&error]) {
        
        self.videoDevice.activeVideoMaxFrameDuration = frameDuration;
        self.videoDevice.activeVideoMinFrameDuration = frameDuration;
        
        [self.videoDevice unlockForConfiguration];
    }
    
    [self.captureSession commitConfiguration];
    
    self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if ([self.videoConnection isVideoOrientationSupported]) {
        
        [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    if ([self.videoConnection isVideoMirroringSupported]) {
        
        [self.videoConnection setVideoMirrored:self.videoDevice.position == AVCaptureDevicePositionFront];
    }
    
    return YES;
}

- (void)startCaptureSession
{
    if (self.captureSession && ![self.captureSession isRunning]) {
        
        [self.captureSession startRunning];
    }
}

- (void)stopCaptureSession
{
    if (self.captureSession && [self.captureSession isRunning]) {
        
        [self.captureSession stopRunning];
    }
}

- (void)destroyCaptureEnv
{
    if (self.captureSession) {
        
        [self stopCaptureSession];
        
        [self.captureSession beginConfiguration];
        
        [self.captureSession removeOutput:self.videoDataOutput];
        [self.captureSession removeInput:self.videoDeviceInput];
        
        [self.captureSession commitConfiguration];
        
        self.captureSession = nil;
    }
}

#pragma - mark -

- (EAGLContext *)getPreContext
{
    return [EAGLContext currentContext];
}

- (void)setCurrentContext:(EAGLContext *)context
{
    if ([EAGLContext currentContext] != context) {
        
        [EAGLContext setCurrentContext:context];
    }
}

- (void)randomTheGold
{
    NSString *strGlod = [NSString stringWithFormat:@" 金币: 365%d >" , arc4random() % 1000];
    
    NSMutableAttributedString *strAttrGlod = [[NSMutableAttributedString alloc] initWithString:strGlod];
    [strAttrGlod addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(1, 3)];
    
    [self.lblGold setAttributedText:strAttrGlod];
    
    NSString *strAdGlod = [NSString stringWithFormat:@" 广告币: 88%d >" , arc4random() % 100];
    
    NSMutableAttributedString *strAttrAdGlod = [[NSMutableAttributedString alloc] initWithString:strAdGlod];
    [strAttrAdGlod addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(1, 4)];
    
    [self.lblAdGold setAttributedText:strAttrAdGlod];
}

- (void)showMaterialDetail:(SenseArMaterial *)material enableBtn:(BOOL)bEnable
{
    self.showingDetailMaterial = material;
    
    [self.adDetailView setHidden:NO];
    [self.btnCloseDetail setHidden:NO];
    
    [self.lblAdName setText:material.strName];
    
    id obj = [self.thumbnailCache objectForKey:material.strID];
    
    if ([obj isKindOfClass:[UIImage class]]) {
        
        [self.adThumbView setImage:obj];
    }else{
        
        [self.adThumbView setImage:nil];
    }
    
    [self.adPriceTypeView setImage:[UIImage imageNamed:SENSEAR_CPC == material.iPricingType ? @"eye.png" : @"hand.png"]];
    [self.lblPricingIntroduction setText:[NSString stringWithFormat:@"每位观众%@可赚%@金币" , SENSEAR_CPC == material.iPricingType ? @"观看超30秒" : @"点击一次" ,  material.strPrice]];
    
    switch (material.iTriggerAction) {
            
            // 张嘴
        case MOUTH_AH:
        {
            [self.adActionView setImage:[UIImage imageNamed:@"张嘴.png"]];
        }
            break;
            
            // 眨眼
        case EYE_BLINK:
        {
            [self.adActionView setImage:[UIImage imageNamed:@"眨眼.png"]];
        }
            break;
            
            // 点头
        case HEAD_PITCH:
        {
            [self.adActionView setImage:[UIImage imageNamed:@"点头.png"]];
        }
            break;
            
            // 摇头
        case HEAD_YAW:
        {
            [self.adActionView setImage:[UIImage imageNamed:@"转头.png"]];
        }
            break;
            
            // 挑眉
        case BROW_JUMP:
        {
            [self.adActionView setImage:[UIImage imageNamed:@"挑眉.png"]];
        }
            break;
            
            // 手掌
        case HAND_PALM:
        {
            [self.adActionView setImage:[UIImage imageNamed:@"手掌.png"]];
        }
            break;
            
            // 大拇哥
        case HAND_GOOD:
        {
            [self.adActionView setImage:[UIImage imageNamed:@"大拇哥.png"]];
        }
            break;
            
            // 托手
        case HAND_HOLDUP:
        {
            [self.adActionView setImage:[UIImage imageNamed:@"托起.png"]];
        }
            break;
            
            // 爱心手
        case HAND_LOVE:
        {
            [self.adActionView setImage:[UIImage imageNamed:@"爱心.png"]];
        }
            break;
            
            // 恭贺(抱拳)
        case HAND_CONGRATULATE:
        {
            [self.adActionView setImage:[UIImage imageNamed:@"抱拳.png"]];
        }
            
        default:
        {
            [self.adActionView setImage:nil];
        }
            
            break;
    }
    
    [self.lblAdAction setText:material.strTriggerActionTip];
    [self.lblAdIntroduction setText:material.strInstructions];
    
    [self.btnStartShowAd setBackgroundColor:bEnable ? [UIColor colorWithRed:1.0 green:127.0 / 255.0 blue:0 alpha:1.0] : [UIColor lightGrayColor]];
}

- (void)startShowingMaterial:(SenseArMaterial *)material
{
    [self closeAdDetail];
    [self closeAdList];
    
    self.dLastActionTipPTS = CFAbsoluteTimeGetCurrent();
    
    if (![self.currentMaterial.strID isEqualToString:material.strID]) {
        
        [self endShowingAd];
    }else{
        
        return;
    }
    
    self.prepareMaterial = material;
    
    
    // 判断素材是否已经下载
    if ([self.service isMaterialDownloaded:material.strID]) {
        
        if ([self.prepareMaterial.strID isEqualToString:material.strID]) {
            
            self.currentMaterial = material;
        }
    }else{
        
        // 若未下载需先下载素材包
        [self.service downloadMaterial:material onSuccess:^(SenseArMaterial *material) {
            
            
            if ([self.prepareMaterial.strID isEqualToString:material.strID]) {
                
                self.currentMaterial = material;
            }
        } onFailure:^(SenseArMaterial *material,
                      int iErrorCode,
                      NSString *strMessage) {
            
            STLog(@"download ad faild errorCode : %d , message %@" , iErrorCode , strMessage);
            
        } onProgress:^(SenseArMaterial *material,
                       float fProgress,
                       int64_t iSize) {
            
            STLog(@"on progress %f , %lld " , fProgress , iSize);
        }];
    }
}

- (void)endShowingAd
{
    self.currentMaterial = nil;
}


- (void)closeAdDetail
{
    [self.btnCloseDetail setHidden:YES];
    [self.adDetailView setHidden:YES];
}

- (void)closeAdList
{
    [self.btnIntroduction setImage:[UIImage imageNamed:@"ques.png"] forState:UIControlStateNormal];
    self.isIntroductionViewShowing = NO;
    
    [self.btnAdTab setHidden:YES];
    [self.btnStickerTab setHidden:YES];
    [self.adsCollectionView setHidden:YES];
    [self.btnCloseAdList setHidden:YES];
    [self.btnIntroduction setHidden:YES];
    [self.introductionDetail setHidden:YES];
}

- (void)changePanelStatusIfShowStickerList:(BOOL)bShowStickerList
{
    self.bShowStickerList = bShowStickerList;
    
    [self.adsCollectionView reloadData];
    
    UIColor *colorSelected = [UIColor colorWithRed:48.0 / 255.0 green:48.0 / 255.0 blue:48.0 / 255.0 alpha:1.0];
    
    UIColor *colorUnselected = [UIColor colorWithRed:36.0 / 255.0 green:36.0 / 255.0 blue:36.0 / 255.0 alpha:1.0];
    
    [self.btnAdTab setBackgroundColor:bShowStickerList ? colorUnselected : colorSelected];
    [self.btnAdTab setImage:[UIImage imageNamed:bShowStickerList ? @"ads2.png" : @"ads1.png"] forState:UIControlStateNormal];
    
    [self.btnStickerTab setBackgroundColor:bShowStickerList ? colorSelected : colorUnselected];
    [self.btnStickerTab setImage:[UIImage imageNamed:bShowStickerList ? @"sticker1.png" : @"sticker2.png"] forState:UIControlStateNormal];
    
    [self.btnIntroduction setHidden:bShowStickerList];
}

- (void)setupThumbnailCache
{
    self.thumbnailCache = [[NSCache alloc] init];
    self.fManager = [[NSFileManager alloc] init];
    
    // 可以根据实际情况实现素材列表缩略图的缓存策略 , 这里仅做演示 .
    self.strThumbnailPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"sensear_thumbnail"];
    
    NSError *error = nil;
    BOOL bCreateSucceed = [self.fManager createDirectoryAtPath:self.strThumbnailPath
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error];
    if (!bCreateSucceed || error) {
        
        STLog(@"create thumbnail cache directory failed !");
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"创建列表图片缓存文件夹失败" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
        
        [alert show];
    }
}

- (SenseArRotateType)getRotateTypeWithDeviceOrientation
{
    UIDeviceOrientation iDeviceOrientation = [[UIDevice currentDevice] orientation];
    
    SenseArRotateType iRotate;
    
    switch (iDeviceOrientation) {
            
        case UIDeviceOrientationPortrait:
            
            iRotate = CLOCKWISE_ROTATE_0;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            
            iRotate = CLOCKWISE_ROTATE_180;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            
            iRotate = CLOCKWISE_ROTATE_270;
            
            break;
            
        case UIDeviceOrientationLandscapeRight:
            
            iRotate = CLOCKWISE_ROTATE_90;
            
            break;
            
        default:
            
            iRotate = CLOCKWISE_ROTATE_90;
            break;
    }
    
    return iRotate;
}

#pragma - mark -
#pragma - mark Touch Event

- (IBAction)onBtnBack:(id)sender {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self.timer invalidate];
    self.timer = nil;
    
    [self stopAndDestroyStreaming];
    
    self.frameBuffer = nil;
    
    [self stopCaptureSession];
    
    [self destroyCaptureEnv];
    
    if (self.currentMaterial) {
        
        [self endShowingAd];
    }
    
    [self.broadcaster broadcastEnd];
    
    EAGLContext *preContext = [self getPreContext];
    
    [self setCurrentContext:self.glRenderContext];
    
    // 释放渲染模块占用的 OpenGL 相关资源
    [self.render releaseGLResource];
    
    glDeleteTextures(1, &_textureBeautifyOut);
    glDeleteTextures(1, &_textureStickerOut);
    
    if (_cvOriginalTexture) {
        
        CFRelease(_cvOriginalTexture);
        _cvOriginalTexture = NULL;
    }
    
    if (_cvTextureCache) {
        
        CFRelease(_cvTextureCache);
        _cvTextureCache = NULL;
    }
    
    [self setCurrentContext:preContext];
    
    // 关闭 SenseArMaterialService 释放资源
    [SenseArMaterialService releaseResources];
    
    self.service = nil;
    
    // logout
    NSString *strURL = [NSString stringWithFormat:@"http://%@/sdkserver/logout?broadcaster_id=%@&type=1" , APP_SERVER , self.strBroadcasterID];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:strURL]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:30];
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onTapAdGoldView
{
    GoldViewController *goldVC = [self.storyboard instantiateViewControllerWithIdentifier:@"GoldViewController"];
    [self.navigationController pushViewController:goldVC animated:YES];
}

- (IBAction)onBtnAdTab:(id)sender {
    
    [self changePanelStatusIfShowStickerList:NO];
}

- (IBAction)onBtnStickerTab:(id)sender {
    
    [self changePanelStatusIfShowStickerList:YES];
}

- (IBAction)onBtnStartShowAd:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    
    if ([btn backgroundColor] == [UIColor lightGrayColor]) {
        
        return;
    }
    
    [self startShowingMaterial:self.showingDetailMaterial];
}

- (IBAction)onBtnCloseDetail:(id)sender {
    
    [self closeAdDetail];
}

- (IBAction)onBtnCancelAgreement:(id)sender {
    
    self.introductionView.hidden = YES;
    self.lblAdGold.hidden = YES;
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).bAgree = NO;
}
- (IBAction)onBtnApplyAgreement:(id)sender {
    
    self.introductionView.hidden = YES;
    
    self.lblAdGold.hidden = self.lblGold.hidden;
    
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).bAgree = YES;
    
    [self onBtnShowAdList:nil];
}


- (IBAction)onBtnLock:(id)sender {
    
    self.fansAnimationView.hidden = !self.fansAnimationView.hidden;
    self.messageAnimationView.hidden = !self.messageAnimationView.hidden;
    self.personInfoView.hidden = !self.personInfoView.hidden;
    self.lblGold.hidden = !self.lblGold.hidden;
    
    self.lblAdGold.hidden = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).bAgree ? !self.lblAdGold.hidden : YES;
}

- (IBAction)onBtnSreaming:(id)sender {
    if (_kit.streamerBase.streamState == KSYStreamStateIdle ||
        _kit.streamerBase.streamState == KSYStreamStateError) {
        _hostURL = [NSURL URLWithString:_strRTMPURL];
        [_kit.streamerBase startStream:_hostURL];
    }
    else {
        [_kit.streamerBase stopStream];
    }
}


- (IBAction)onBtnShowAdList:(id)sender {
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (!appDelegate.bAgree) {
        
        self.introductionView.hidden = NO;
    }else{
        
        if (!self.bShowStickerList) {
            
            [self.btnIntroduction setHidden:NO];
        }
        
        [self.adsCollectionView setHidden:NO];
        
        [self.btnStickerTab setHidden:NO];
        [self.btnAdTab setHidden:NO];
        
        [self.btnCloseAdList setHidden:NO];
        
        
        // 获取素材分组列表
        [self.service fetchAllGroupsOnSuccess:^(NSArray<SenseArMaterialGroup *> *arrMaterialGroups) {
            
            STLog(@"fetchAllGroupsOnSuccess");
        } onFailure:^(int iErrorCode, NSString *strMessage) {
            
            STLog(@"fetchAllGroups failed %d , %@" , iErrorCode , strMessage);
        }];
        
        // 获取素材列表
        [self.service fetchMaterialsWithGroupID:@"AD_LIST" onSuccess:^(NSArray<SenseArMaterial *> *arrMaterials) {
            
            NSMutableArray *arrAds = [NSMutableArray array];
            
            for (int i = 0; i < arrMaterials.count; i ++) {
                
                SenseArMaterial *material = [arrMaterials objectAtIndex:i];
                
                [arrAds addObject:material];
                
                [self cacheThumbnailOfMaterial:material materialIndex:i isStickerList:NO];
            }
            
            self.arrAdvertisings = arrAds;
            
            if (!self.bShowStickerList) {
                
                [self.adsCollectionView reloadData];
            }
            
        } onFailure:^(int iErrorCode, NSString *strMessage) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
            
            [alert setMessage:[NSString stringWithFormat:@"获取素材列表失败 , %@" , strMessage]];
            
            [alert show];
        }];
        
        [self.service fetchMaterialsWithGroupID:@"SE_LIST" onSuccess:^(NSArray<SenseArMaterial *> *arrMaterials) {
            
            NSMutableArray *arrStickers = [NSMutableArray array];
            
            for (int i = 0; i < arrMaterials.count; i ++) {
                
                SenseArMaterial *material = [arrMaterials objectAtIndex:i];
                
                // 趣味特效
                [arrStickers addObject:material];
                
                [self cacheThumbnailOfMaterial:material materialIndex:i isStickerList:YES];
            }
            
            self.arrStickers = arrStickers;
            
            if (self.bShowStickerList) {
                
                [self.adsCollectionView reloadData];
            }
            
        } onFailure:^(int iErrorCode, NSString *strMessage) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
            
            [alert setMessage:[NSString stringWithFormat:@"获取贴纸列表失败 , %@" , strMessage]];
            
            [alert show];
        }];
    }
}

- (void)cacheThumbnailOfMaterial:(SenseArMaterial *)material
                   materialIndex:(int)iIndex
                   isStickerList:(BOOL)isStickerList
{
    id obj = [self.thumbnailCache objectForKey:material.strID];
    
    if (obj) {
        
        if ([obj isKindOfClass:[UIImage class]]) {
            
            // in cache
        } else if ([obj isKindOfClass:[NSString class]] && [obj isEqualToString:material.strID]) {
            
            // downloading ..
        } else {
            
            [self.thumbnailCache removeObjectForKey:material.strID];
        }
    }else{
        
        NSString *strThumbnailImagePath = [self.strThumbnailPath stringByAppendingPathComponent:material.strID];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:strThumbnailImagePath]) {
            
            UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:strThumbnailImagePath];
            
            [self.thumbnailCache setObject:thumbnailImage forKey:material.strID];
            
        }
    }
}


- (IBAction)onBtnIntroduction:(id)sender {
    
    self.isIntroductionViewShowing = !self.isIntroductionViewShowing;
    
    [self.btnIntroduction setImage:[UIImage imageNamed:self.isIntroductionViewShowing ? @"back.png" : @"ques.png"] forState:UIControlStateNormal];
    
    [self.introductionDetail setHidden:!self.isIntroductionViewShowing];
    
    
    [self.btnAdTab setHidden:self.isIntroductionViewShowing];
    [self.btnStickerTab setHidden:self.isIntroductionViewShowing];
    
    if (!self.bShowStickerList) {
        
        [self.adsCollectionView setHidden:self.isIntroductionViewShowing];
    }
}

- (IBAction)onBtnCloseAdList:(id)sender {
    
    [self closeAdList];
}

#pragma - mark -
#pragma - mark Private Method

- (void)showActionTipsIfNeed
{
    if (self.currentMaterial) {
        
        if ((CFAbsoluteTimeGetCurrent() - self.dLastActionTipPTS) > kACTION_TIP_STAY_TIME) {
            
            if (![self.lblActionTip isHidden]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.lblActionTip setHidden:YES];
                    [self.actionTipImageView setImage:nil];
                    [self.lblActionTip setText:@""];
                });
            }
            
        }else{
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.lblActionTip setHidden:NO];
                
                [self.lblActionTip setText:self.currentMaterial.strTriggerActionTip];
                
                [self.actionTipImageView setHidden:NO];
                
                switch (self.currentMaterial.iTriggerAction) {
                        
                        // 张嘴
                    case 1:
                    {
                        [self.actionTipImageView setImage:[UIImage imageNamed:@"张嘴.png"]];
                    }
                        break;
                        
                        // 眨眼
                    case 2:
                    {
                        [self.actionTipImageView setImage:[UIImage imageNamed:@"眨眼.png"]];
                    }
                        break;
                        
                        // 点头
                    case 3:
                    {
                        [self.actionTipImageView setImage:[UIImage imageNamed:@"点头.png"]];
                    }
                        break;
                        
                        // 摇头
                    case 4:
                    {
                        [self.actionTipImageView setImage:[UIImage imageNamed:@"转头.png"]];
                    }
                        break;
                        
                        // 挑眉
                    case 5:
                    {
                        [self.actionTipImageView setImage:[UIImage imageNamed:@"挑眉.png"]];
                    }
                        break;
                        
                        // 手掌
                    case 6:
                    {
                        [self.actionTipImageView setImage:[UIImage imageNamed:@"手掌.png"]];
                    }
                        break;
                        
                        // 大拇哥
                    case 7:
                    {
                        [self.actionTipImageView setImage:[UIImage imageNamed:@"大拇哥.png"]];
                    }
                        break;
                        
                        // 托手
                    case 8:
                    {
                        [self.actionTipImageView setImage:[UIImage imageNamed:@"托起.png"]];
                    }
                        break;
                        
                        // 爱心手
                    case 9:
                    {
                        [self.actionTipImageView setImage:[UIImage imageNamed:@"爱心.png"]];
                    }
                        break;
                        
                    default:
                    {
                        [self.actionTipImageView setImage:nil];
                    }
                        
                        break;
                }
            });
        }
        
    }else{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.lblActionTip setHidden:YES];
            [self.actionTipImageView setImage:nil];
        });
    }
}

- (void)sovlePaddingImage:(Byte *)pImage width:(int)iWidth height:(int)iHeight bytesPerRow:(int *)pBytesPerRow
{
    
    int iBytesPerPixel = *pBytesPerRow / iWidth;
    int iBytesPerRowCopied = iWidth * iBytesPerPixel;
    int iCopiedImageSize = sizeof(Byte) * iWidth * iBytesPerPixel * iHeight;
    
    Byte *pCopiedImage = (Byte *)malloc(iCopiedImageSize);
    memset(pCopiedImage, 0, iCopiedImageSize);
    
    for (int i = 0; i < iHeight; i ++) {
        
        memcpy(pCopiedImage + i * iBytesPerRowCopied,
               pImage + i * *pBytesPerRow,
               iBytesPerRowCopied);
    }
    
    memcpy(pImage, pCopiedImage, iCopiedImageSize);
    free(pCopiedImage);
    
    *pBytesPerRow = iBytesPerRowCopied;
}

void activeAndBindTexture(GLenum textureActive,
                          GLuint *textureBind,
                          Byte *sourceImage,
                          GLenum sourceFormat,
                          GLsizei iWidth,
                          GLsizei iHeight)
{
    glGenTextures(1, textureBind);
    glActiveTexture(textureActive);
    glBindTexture(GL_TEXTURE_2D, *textureBind);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, iWidth, iHeight, 0, sourceFormat, GL_UNSIGNED_BYTE, sourceImage);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glFlush();
}


- (BOOL)isMaterialTriggered:(NSString *)strMaterialID frameActionInfo:(SenseArFrameActionInfo *)frameActionInfo
{
    STMaterialDisplayConfig *config = [self.dicMaterialDisplayConfig objectForKey:strMaterialID];
    
    if (!config) {
        
        return NO;
    }
    
    if (!frameActionInfo) {
        
        return NO;
    }
    
    for (SenseArFace *arFace in frameActionInfo.arrFaces) {
        
        if ((arFace.iAction & config.iTriggerType) > 0) {
            
            return YES;
        }
    }
    
    for (SenseArHand *arHand in frameActionInfo.arrHands) {
        
        if ((arHand.iAction & config.iTriggerType) > 0) {
            
            return YES;
        }
    }
    
    return NO;
}

- (void)changeToNextPartsWithMaterialID:(NSString *)strMaterialID
                          materialParts:(NSArray <SenseArMaterialPart *>*)arrMaterialParts
{
    STMaterialDisplayConfig *config = [self.dicMaterialDisplayConfig objectForKey:strMaterialID];
    
    NSArray <NSString *> *arrNextParts = [config nextParts];
    
    if (arrNextParts.count) {
        
        for (SenseArMaterialPart *materialPart in arrMaterialParts) {
            
            for (NSString *strPartName in arrNextParts) {
                
                if ([materialPart.strPartName isEqualToString:strPartName]) {
                    
                    materialPart.isEnable = YES;
                    
                    break;
                }else{
                    
                    materialPart.isEnable = NO;
                }
            }
        }
        
        [self.render enableMaterialParts:arrMaterialParts];
    }
}

- (void)resetCurrentPartsIndexWithID:(NSString *)strID
{
    STMaterialDisplayConfig *config = [self.dicMaterialDisplayConfig objectForKey:strID];
    
    config.iCurrentPartsIndex = -1;
}
#pragma - mark -
#pragma - mark UICollectionView delegate & dataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.bShowStickerList ? self.arrStickers.count + 1: self.arrAdvertisings.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strIdentifier = @"STCollectionViewCell";
    
    STCollectionViewCell *cell = (STCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:strIdentifier forIndexPath:indexPath];
    
    if (0 == indexPath.row) {
        
        UIImage *image = [UIImage imageNamed:@"null.png"];
        
        [cell.thumbnail setImage:image];
        [cell.lblInfo setText:[NSString stringWithFormat:@"无贴纸"]];
        [cell.lblInfo setTextColor:[UIColor whiteColor]];
        [cell.adTypeView setImage:nil];
        [cell.downloadSign setHidden:YES];
        [cell.loadingIndicator stopAnimating];
        
        if (!self.currentMaterial) {
            
            [cell.thumbnail.layer setBorderWidth:2.0f];
            [cell.thumbnail.layer setBorderColor:[[UIColor colorWithRed:144.0 / 255.0 green:1.0 blue:1.0 alpha:1.0f] CGColor]];
            
            [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            
        }else{
            
            [cell.thumbnail.layer setBorderWidth:0.0f];
        }
    }else{
        
        [cell.thumbnail setImage:nil];
        
        SenseArMaterial *material = [self.bShowStickerList ? self.arrStickers : self.arrAdvertisings objectAtIndex:indexPath.row - 1];
        
        id cacheObj = [self.thumbnailCache objectForKey:material.strID];
        
        if (cacheObj && [cacheObj isKindOfClass:[UIImage class]]) {
            
            [cell.thumbnail setImage:cacheObj];
        }else{
            
            [self.thumbnailCache setObject:material.strID forKey:material.strID];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH , 0), ^{
                
                UIImage *imageDownloaded = nil;
                
                if (![material.strThumbnailURL isEqual:[NSNull null]]) {
                    
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:material.strThumbnailURL]];
                    
                    imageDownloaded = [UIImage imageWithData:imageData];
                    
                    if (imageDownloaded) {
                        
                        [self.thumbnailCache setObject:imageDownloaded forKey:material.strID];
                        
                        NSString *strThumbnailImagePath = [self.strThumbnailPath stringByAppendingPathComponent:material.strID];
                        
                        [self.fManager createFileAtPath:strThumbnailImagePath contents:imageData attributes:nil];
                    }else{
                        
                        [self.thumbnailCache removeObjectForKey:material.strID];
                    }
                }else{
                    
                    [self.thumbnailCache removeObjectForKey:material.strID];
                }
                
                NSInteger iItemsCount = [collectionView numberOfItemsInSection:indexPath.section];
                
                
                
                if (iItemsCount - 1 >= indexPath.row &&
                    (material.iEffectType == SpecialEffect) == self.bShowStickerList) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [cell.thumbnail setImage:imageDownloaded];
                    });
                }
            });
        }
        
        BOOL isMaterialDownloaded = [self.service isMaterialDownloaded:material.strID];
        
        [cell.downloadSign setHidden:isMaterialDownloaded];
        
        if (isMaterialDownloaded) {
            
            [cell.loadingIndicator stopAnimating];
        }
        
        if (!self.bShowStickerList) {
            
            [cell.lblInfo setTextColor:[UIColor colorWithRed:244.0 / 255.0 green:218 / 255.0 blue:37 / 255.0 alpha:1.0]];
            [cell.lblInfo setText:[material.strPrice stringByAppendingString:@" 金币"]];
            
            [cell.adTypeView setImage:[UIImage imageNamed: material.iPricingType == SENSEAR_CPC ? @"eye.png" : @"hand.png"]];
        }else{
            
            [cell.lblInfo setTextColor:[UIColor colorWithRed:244.0 / 255.0 green:218 / 255.0 blue:37 / 255.0 alpha:1.0]];
            [cell.lblInfo setText:@""];
            
            [cell.adTypeView setImage:nil];
        }
        
        
        if ([material.strID isEqualToString:self.currentMaterial.strID]) {
            
            [cell.thumbnail.layer setBorderWidth:2.0f];
            [cell.thumbnail.layer setBorderColor:[[UIColor colorWithRed:144.0 / 255.0 green:1.0 blue:1.0 alpha:1.0f] CGColor]];
            
            [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            
        }else{
            
            [cell.thumbnail.layer setBorderWidth:0.0f];
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    STCollectionViewCell *cell = (STCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    
    [cell.thumbnail.layer setBorderWidth:2.0f];
    [cell.thumbnail.layer setBorderColor:[[UIColor colorWithRed:144.0 / 255.0 green:1.0 blue:1.0 alpha:1.0f] CGColor]];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    STCollectionViewCell *cell = (STCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (0 == indexPath.row) {
        
        [self endShowingAd];
        
        return YES;
        
    }else{
        
        SenseArMaterial *material = [self.bShowStickerList ? self.arrStickers : self.arrAdvertisings objectAtIndex:indexPath.row - 1];
        
        [cell.downloadSign setHidden:YES];
        
        BOOL isMaterialDownloaded = [self.service isMaterialDownloaded:material.strID];
        
        if (isMaterialDownloaded) {
            
            [cell.loadingIndicator stopAnimating];
            
            if (SpecialEffect == material.iEffectType) {
                
                [self startShowingMaterial:material];
            }else{
                
                [self showMaterialDetail:material enableBtn:YES];
            }
            
            return YES;
            
        }else{
            
            if (SpecialEffect != material.iEffectType) {
                
                [self showMaterialDetail:material enableBtn:NO];
            }
            
            [cell.loadingIndicator startAnimating];
            
            [self.service downloadMaterial:material onSuccess:^(SenseArMaterial *material) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ([self.showingDetailMaterial.strID isEqualToString:material.strID]) {
                        
                        if (!self.adDetailView.hidden) {
                            
                            [self.btnStartShowAd setBackgroundColor:[UIColor colorWithRed:1.0 green:127.0 / 255.0 blue:0 alpha:1.0]];
                        }
                    }
                    [cell.loadingIndicator stopAnimating];
                });
            } onFailure:^(SenseArMaterial *material, int iErrorCode, NSString *strMessage) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [cell.loadingIndicator stopAnimating];
                    [cell.downloadSign setHidden:NO];
                });
                
            } onProgress:nil];
            
            return NO;
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    STCollectionViewCell *cell = (STCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    [cell.thumbnail.layer setBorderWidth:0.0f];
}



- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint touchPosition = [touches.allObjects.firstObject locationInView:self.view];
    
    if (!self.adDetailView.hidden) {
        
        CGRect responseArea = CGRectMake(0, 0, self.view.frame.size.width, self.adDetailView.frame.origin.y);
        
        if (CGRectContainsPoint(responseArea, touchPosition)) {
            
            [self closeAdDetail];
            [self closeAdList];
        }
    }else{
        
        if (!self.adsCollectionView.hidden  || !self.introductionDetail.hidden) {
            
            CGRect responseArea = CGRectMake(0, 0, self.view.frame.size.width, self.adsCollectionView.frame.origin.y);
            
            if (CGRectContainsPoint(responseArea, touchPosition)) {
                
                [self closeAdList];
            }
        }
    }
    
    [super touchesBegan:touches withEvent:event];
}


#pragma - mark -
#pragma - mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
            
        case 0:
        {
            [self onBtnBack:nil];
        }
            break;
            
        default:
            break;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
