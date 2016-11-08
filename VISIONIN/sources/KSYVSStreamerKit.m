#import "KSYVSStreamerKit.h"

@implementation KSYVSStreamerKit

//default init
- (instancetype)initWithDefaultCfg{
    if (self == [super initWithDefaultCfg]) {
        _vsVideoFrame = [[VSVideoFrame alloc] init];
    }
    return self;
}

//init with interrupt
- (instancetype)initWithInterruptCfg{
    if (self == [super initWithInterruptCfg]) {
        _vsVideoFrame = [[VSVideoFrame alloc] init];
    }
    return self;
}
- (void)startFaceTracking{
    [[VSFacer shareInstance] startFaceTracking];
    if ([[VSProps shareInstance] startProps:@"萝卜兔子"] == NO) {
        [[VSProps shareInstance] downloadProps:@"萝卜兔子" progress:^(int percent) {
        } complete:^(id error) {
            [[VSProps shareInstance] startProps:@"萝卜兔子"];
        }];
    }
}
@end
