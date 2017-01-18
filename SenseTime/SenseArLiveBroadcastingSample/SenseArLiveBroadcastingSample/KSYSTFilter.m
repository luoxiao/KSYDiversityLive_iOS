//
//  KSYSTFilter.m
//  SenseArLiveBroadcastingSample
//
//  Created by 孙健 on 2017/1/14.
//  Copyright © 2017年 SenseTime. All rights reserved.
//

#import "KSYSTFilter.h"
#import <libksygpulive/libksygpuimage.h>
#import <CommonCrypto/CommonDigest.h>
#import "SenseAr.h"
#import "STMobileLog.h"

@interface KSYSTFilter(){
    KSYGPUPicOutput *_outPut;
    GPUImageTextureInput *_textureInput;
    GPUImageOutput *_currentTarget;
    GLuint _textureOriginalIn;
    GLuint _textureBeautifyOut;
    GLuint _textureStickerOut;
    GLuint _textureResult;
}
@property (nonatomic , strong) EAGLContext *glRenderContext;
@property (nonatomic , strong) SenseArMaterial *currentMaterial;
@property (nonatomic , strong) SenseArMaterial *prepareMaterial;
@property (nonatomic , strong) SenseArMaterialService *service;
@property (nonatomic , strong) SenseArBroadcasterClient *broadcaster;
@property (nonatomic , strong) SenseArMaterialRender *render;
@property (nonatomic , strong) NSDictionary *dicMaterialDisplayConfig;
@end
@implementation KSYSTFilter
- (id)initWithTarget:(GPUImageOutput<GPUImageInput> *)target
               width:(CGFloat)width
              height:(CGFloat)height{
    if (self = [super init]) {
        //------check lisence--------//
        // 验证 license
        [self checkActiveCode];
        [self setupMaterialRender];
        [self setupSenseArServiceAndBroadcaster];
        
        //---------------------------//
        _outPut = [[KSYGPUPicOutput alloc] initWithOutFmt:kCVPixelFormatType_32BGRA];
        _textureInput = [[GPUImageTextureInput alloc] initWithTexture:_textureStickerOut size:CGSizeMake(width, height)];
        [_textureInput addTarget:target];
        __weak typeof(self) weakself = self;
        _outPut.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo){
            [weakself processPixelbuffer:pixelBuffer time:timeInfo];
        };
        _currentTarget = [[GPUImageOutput alloc] init];
        _currentTarget = target;
    }
    return self;
}
//overwrite super function
- (void)addTarget:(id<GPUImageInput>)newTarget{
    [_currentTarget addTarget:newTarget];
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
#pragma mark - processPixelbuffer
- (void)processPixelbuffer:(CVPixelBufferRef)pixelBuffer time:(CMTime)time{
    
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
    _textureResult = 0;
    if (!self.render || ![SenseArMaterialService isAuthorizedForRender]) {
        
        iRenderStatus = RENDER_NOT_AUTHORIZED;
        _textureResult = _textureOriginalIn;
    }else{
        
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
@end
