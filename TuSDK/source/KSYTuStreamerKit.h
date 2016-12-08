#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "KSYCameraSource.h"
#import <libksygpulive/libksygpulive.h>

@interface KSYTuStreamerKit : NSObject
//property
@property(nonatomic, strong) KSYCameraSource     *cameraSource;
@property(nonatomic, strong) UIView              *preview;
@property(nonatomic, strong) KSYStreamerBase     *streamerBase;
@property(nonatomic, strong) KSYAUAudioCapture   *audioCapDev;
@property(nonatomic, strong) KSYAudioMixer       *aMixer;
@property(nonatomic, assign) int                 micTrack;
//method
- (instancetype)initWithDefault:(UIView *)view;
- (void)startCapture;
- (void)stopCapture;
@end
