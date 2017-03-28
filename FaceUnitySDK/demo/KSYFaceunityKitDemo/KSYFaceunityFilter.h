#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>
#import <libksygpulive/libksygpuimage.h>

@interface KSYFaceunityFilter : KSYGPUPicInput <GPUImageInput>
/**
 @abstract   构造函数
 
 **/
-(id) initWithArray:(NSArray *) items;


/**
 @abstract      选择的bundle包，可以动态选择
 **/
@property (nonatomic,assign) int choosedIndex;

@end
