#import <libksygpulive/KSYGPUStreamerKit.h>
#import "VSVideoFrame.h"
#import "VSProps.h"
#import "VSFacer.h"

@interface KSYVSStreamerKit : KSYGPUStreamerKit

//property
@property (nonatomic, strong) VSVideoFrame *vsVideoFrame;
//method
- (void)startFaceTracking;

@end
