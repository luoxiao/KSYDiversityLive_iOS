#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>
#import <libksygpulive/libksygpuimage.h>

@interface KSYFaceunityFilter : KSYGPUPicInput <GPUImageInput>


-(void)loadItem:(NSString *)itemName;

@end
