#import "KSYFaceunityFilter.h"
#include <sys/mman.h>
#include <sys/stat.h>
#import "FURenderer.h"
#import "authpack.h"

static int g_frame_id = 0;

static size_t osal_GetFileSize(int fd){
    struct stat sb;
    sb.st_size = 0;
    fstat(fd, &sb);
    return (size_t)sb.st_size;
}
static void* mmap_bundle(NSString* fn_bundle,intptr_t* psize){
    // Load item from predefined item bundle
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fn_bundle];
    //    path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:fn_bundle];
    const char *fn = [path UTF8String];
    int fd = open(fn,O_RDONLY);
    void* g_res_zip = NULL;
    size_t g_res_size = 0;
    if(fd == -1){
        NSLog(@"faceunity: failed to open bundle");
        g_res_size = 0;
    }else{
        g_res_size = osal_GetFileSize(fd);
        g_res_zip = mmap(NULL, g_res_size, PROT_READ, MAP_SHARED, fd, 0);
        NSLog(@"faceunity: %@ mapped %08x %ld\n", path, (unsigned int)g_res_zip, g_res_size);
    }
    *psize = g_res_size;
    return g_res_zip;
    return nil;
}


@interface KSYFaceunityFilter()
{
    
    int _lastItem;
    
    // items' bundle name
    NSArray *itemArray;
    
    NSLock *_lock;
}

@property KSYGPUPicOutput* pipOut;
@property EAGLContext* gl_context;
@property (nonatomic, assign) int curItem;
@property (nonatomic, retain) dispatch_queue_t queue;
@end

@implementation KSYFaceunityFilter


-(id) initWithArray:(NSArray *) items
{
    self = [super initWithFmt:kCVPixelFormatType_32BGRA];
    
    if(self)
    {
        _queue = dispatch_queue_create("com.ksyun.faceunity.queue", DISPATCH_QUEUE_SERIAL);
        
        itemArray = [items copy];
        
        [self initFaceUnity];
        
        [self loadItem:items.firstObject];
        
        _pipOut = [[KSYGPUPicOutput alloc]initWithOutFmt:kCVPixelFormatType_32BGRA];
        __weak KSYFaceunityFilter *weak_filter = self;
        _pipOut.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo ){
            [weak_filter renderFaceUnity:pixelBuffer timeInfo:timeInfo];
        };
    }
    return self;

}
- (id) init {
    return [self initWithArray:nil];
}

-(void)dealloc{
    _pipOut = nil;
    _lock = nil;
    fuDestroyAllItems();
}

-(void)loadItem:(NSString *)itemName{
    dispatch_sync(self.queue, ^{
        if(![EAGLContext setCurrentContext:_gl_context]){
            NSLog(@"faceunity: failed to create / set a GLES2 context");
        }
        
        intptr_t size;
        void* data = mmap_bundle(itemName, &size);
        int itemId = fuCreateItemFromPackage(data, (int)size);
        
        [_lock lock];
        _lastItem = _curItem;
        _curItem = itemId;
        [_lock unlock];
    });
}

- (void)destroyItem:(int)item {
    dispatch_sync(self.queue, ^{
        fuDestroyItem(item);
    });
}

-(void)renderFaceUnity:(CVPixelBufferRef)pixelBuffer
              timeInfo:(CMTime)timeInfo
{
    dispatch_sync(self.queue, ^{
        if(![EAGLContext setCurrentContext:_gl_context]){
            NSLog(@"faceunity: failed to create / set a GLES2 context");
        }
        
        CVPixelBufferRef output_pixelBuffer = [[FURenderer shareRenderer] renderPixelBuffer:pixelBuffer withFrameId:g_frame_id items:&_curItem itemCount:1];
        ++g_frame_id;
        [self processPixelBuffer:output_pixelBuffer time:timeInfo];
    });
}

-(void)initFaceUnity
{
    _gl_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(![EAGLContext setCurrentContext:_gl_context]){
        NSLog(@"faceunity: failed to create / set a GLES2 context");
    }
    
    intptr_t size = 0;
    void* v3data = mmap_bundle(@"v3.bundle", &size);
    
    [[FURenderer shareRenderer] setupWithData:v3data ardata:NULL authPackage:g_auth_package authSize:sizeof(g_auth_package)];
}

#pragma GPUImageInput
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    [_pipOut newFrameReadyAtTime:frameTime atIndex:textureIndex];
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    [_pipOut setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
}

- (NSInteger)nextAvailableTextureIndex {
    return 0;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    [_pipOut setInputSize:newSize atIndex:textureIndex];
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation
                 atIndex:(NSInteger)textureIndex {
    [_pipOut setInputRotation:newInputRotation atIndex:textureIndex];
}

- (GPUImageRotationMode)  getInputRotation {
   return [_pipOut getInputRotation];
}

- (CGSize)maximumOutputSize {
    return [_pipOut maximumOutputSize];
}

- (void)endProcessing {
    
}
- (BOOL)shouldIgnoreUpdatesToThisTarget {
    return NO;
}

- (BOOL)wantsMonochromeInput {
    return NO;
}
- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue {
    
}

- (void)setChoosedIndex:(int)choosedIndex{
    if (_choosedIndex == choosedIndex) {
        return;
    }
    _choosedIndex = choosedIndex;
    
    [self loadItem:itemArray[choosedIndex]];
    [self destroyItem:_lastItem];
}

@end
