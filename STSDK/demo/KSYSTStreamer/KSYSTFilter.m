//
//  KSYSTYUVInput.m
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/22.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import "KSYSTFilter.h"
#import "st_mobile_sticker.h"
#import "st_mobile_beautify.h"
#import <CommonCrypto/CommonDigest.h>
#import "STStickerLoader.h"

@interface KSYSTFilter(){
    BOOL isChanging;
    BOOL processing;
    st_handle_t     _hSticker;
    st_handle_t     _hDetect;
    NSInteger       _currentIndex;
    GLuint          _textureInputRGBAID;
    GLuint          _textureOutputRGBAID;
    EAGLContext     *_glContext;
    CVOpenGLESTextureCacheRef _textureCache;
}
@end

@implementation KSYSTFilter
- (id)initWithEAContext:(EAGLContext *)context{
    if (!(self = [super init])) {
        return nil;
    }
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:context.sharegroup];
    [self checkActiveCode];
    [self setupHandle];
    return self;
}
//sha
- (NSString *)getSHA1StringWithData:(NSData *)data{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    NSMutableString *strSHA1 = [NSMutableString string];
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i ++){
        [strSHA1 appendFormat:@"%02x", digest[i]];
    }
    return strSHA1;
}

//check Active code
- (BOOL)checkActiveCode{
    NSString *strLicensePath = [[NSBundle mainBundle] pathForResource:@"SENSEME" ofType:@"lic"];
    NSData *dataLicense = [NSData dataWithContentsOfFile:strLicensePath];
    NSString *strKeySHA1 = @"SENSEME_106";
    NSString *strKeyActiveCode = @"ACTIVE_CODE";
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *strStoredSHA1 = [userDefaults objectForKey:strKeySHA1];
    NSString *strLicenseSHA1 = [self getSHA1StringWithData:dataLicense];
    st_result_t iRet = ST_OK;
    //new or update
    if (!strStoredSHA1 || ![strLicenseSHA1 isEqualToString:strStoredSHA1]) {
        char active_code[1024];
        int active_code_len = 1024;
        //use file
        //根据授权文件生成激活码，在使用新的license文件时使用
        iRet = st_mobile_generate_activecode(
                                             strLicensePath.UTF8String,
                                             active_code,
                                             &active_code_len
                                             );
        if (ST_OK != iRet) {
            [self toast:@"使用新生成的license文件生成激活码时失效"];
            return NO;
        }
        else{
            //Store active code
            NSData *activeCodeData = [NSData dataWithBytes:active_code length:active_code_len];
            [userDefaults setObject:activeCodeData forKey:strKeyActiveCode];
            [userDefaults setObject:strLicenseSHA1 forKey:strKeySHA1];
            
            [userDefaults synchronize];
        }
    }
    else{
        //Get current active code
        //In this app active code was stored in NSUserDefault
        //In also can be stored in other place
        NSData *activeCodeData = [userDefaults objectForKey:strKeyActiveCode];
        //Check if current active code is available
        //use file
        //检查激活码，必须在所有接口之前调用
        //Lisence 路径
        //当前设备的激活码
        iRet = st_mobile_check_activecode(
                                          strLicensePath.UTF8String,
                                          (const char *)[activeCodeData bytes]
                                          );
        if (ST_OK != iRet) {
            [self toast:@"激活码无效"];
        }
    }
    return YES;
}
- (void)setupHandle{
    NSString *strModelPath = [[NSBundle mainBundle] pathForResource:@"face_track" ofType:@"model"];
    _currentIndex = 0;
    double t1 = CFAbsoluteTimeGetCurrent();
    //创建人体行为监测句柄
    //模型文件
    //配置选项
    st_result_t iRet = st_mobile_human_action_create(strModelPath.UTF8String,
                                                     ST_MOBILE_HUMAN_ACTION_DEFAULT_CONFIG,
                                                     &_hDetect);
    NSLog(@"\n human action create time: %f \n", CFAbsoluteTimeGetCurrent() - t1);
    if (ST_OK != iRet) {
        [self toast:@"算法SDK初始化失败，可能是模型路径错误，SDK期限过期，与绑定包名不符"];
    }
    if ([STStickerLoader getStickersPaths]) {
        t1 = CFAbsoluteTimeGetCurrent();
        iRet = st_mobile_sticker_create([(NSString *)[STStickerLoader getStickersPaths][_currentIndex]UTF8String], &_hSticker);
        printf("\n sticker create time: %f \n",CFAbsoluteTimeGetCurrent() - t1);
    }else{
        iRet = -1;
    }
    if (ST_OK != iRet) {
        [self toast:@"贴纸SDK初始化失败，可能是app中没有素材包，SDK权限过期，或者与绑定包名不符"];
    }
}
- (void)toast:(NSString *)message{
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"提示" message:@"Successful" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
//    [self presentViewController:alert animated:YES completion:nil];
}
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [self processPixelBuffer:cameraFrame time:currentTime];
}
- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer time:(CMTime)timeInfo{
    // 设置SDK上下文 , 需要与初始化SDK时的上下文一致
    [EAGLContext setCurrentContext:_glContext];
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    unsigned char* baseAddress = (unsigned char*)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    int iWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int iHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    size_t iTop , iBottom , iLeft , iRight;
    CVPixelBufferGetExtendedPixels(pixelBuffer, &iLeft, &iRight, &iTop, &iBottom);
    
    iWidth = iWidth + (int)iLeft + (int)iRight;
    iHeight = iHeight + (int)iTop + (int)iBottom;
    
    glGenTextures(1, &_textureOutputRGBAID);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureOutputRGBAID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, iWidth, iHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glActiveTexture(GL_TEXTURE0);
    CVReturn err = CVOpenGLESTextureCacheCreate( kCFAllocatorDefault, NULL, _glContext, NULL, &_textureCache );
    
    if ( err )
    {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        NSLog( @"Error at CVOpenGLESTextureCacheCreate %d", err );
    }
    
    CVOpenGLESTextureRef texture = NULL;
    err = CVOpenGLESTextureCacheCreateTextureFromImage( kCFAllocatorDefault,
                                                       _textureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       (GLsizei)iWidth,
                                                       (GLsizei)iHeight,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &texture );
    
    if ( ! texture || err ) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        NSLog( @"CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err );
    }
    
    _textureInputRGBAID = CVOpenGLESTextureGetName( texture );
    
    glBindTexture(GL_TEXTURE_2D, _textureInputRGBAID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, iWidth , iHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    UIDeviceOrientation iDeviceOrientation = [[UIDevice currentDevice] orientation];
    st_rotate_type stMobileRotate;
    
    switch (iDeviceOrientation) {
            
        case UIDeviceOrientationPortrait:
            
            stMobileRotate = ST_CLOCKWISE_ROTATE_0;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            
            stMobileRotate = ST_CLOCKWISE_ROTATE_180;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            
            stMobileRotate = ST_CLOCKWISE_ROTATE_270;
            
            break;
            
        case UIDeviceOrientationLandscapeRight:
            
            stMobileRotate = ST_CLOCKWISE_ROTATE_90;
            
            break;
            
        default:
            
            stMobileRotate = ST_CLOCKWISE_ROTATE_0;
            break;
    }
    st_result_t iRet = ST_OK;

    st_mobile_human_action_t theResult;
    
    iRet = st_mobile_human_action_detect(_hDetect, baseAddress, ST_PIX_FMT_BGRA8888, iWidth, iHeight, iWidth * 4, stMobileRotate, ST_MOBILE_HUMAN_ACTION_DEFAULT_CONFIG, &theResult);
    
    if (strcmp((char *)baseAddress, "") == 0) {
        NSLog(@"theResult: %d", theResult.face_count);
    }
    
    unsigned int outputID = _textureOutputRGBAID;
    
    if (ST_OK == iRet && _hSticker && !isChanging) {
        
        iRet = st_mobile_sticker_process_texture(_hSticker , _textureInputRGBAID, iWidth, iHeight, stMobileRotate, false, &theResult, ksyitem_callback, _textureOutputRGBAID);
        if (_delegate) {
            [_delegate videoOutputWithTexture:outputID size:CGSizeMake(iWidth, iHeight) time:timeInfo];
        }
    }
    CFRelease(texture);
    CFRelease(_textureCache);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}
void ksyitem_callback(const char* material_name, st_material_status status) {
    switch (status){
        case ST_MATERIAL_BEGIN:
            NSLog(@"begin %s" , material_name);
            break;
        case ST_MATERIAL_END:
            NSLog(@"end %s" , material_name);
            break;
        case ST_MATERIAL_PROCESS:
            NSLog(@"process %s", material_name);
            break;
        default:
            NSLog(@"error");
            break;
    }
}

@end
