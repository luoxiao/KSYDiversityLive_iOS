//
//  STGLView.m
//
//  Created by sluin on 16/5/12.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import "STGLView.h"

@interface STGLView ()

{
    CIImage *_displayImage;
    GLuint _displayTextureID;
}

@property (nonatomic , strong) CIContext *ciContext;
@property (nonatomic , strong) EAGLContext *glContext;

@end

@implementation STGLView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    
        self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        self.ciContext = [CIContext contextWithEAGLContext:self.glContext
                                                   options:@{kCIContextWorkingColorSpace : [NSNull null]}];
        self.context = self.glContext;
    }
    return self;
}

- (void)renderWithTexture:(unsigned int)name
                     size:(CGSize)size
                  flipped:(BOOL)flipped
      applyingOrientation:(int)orientation
{
    _displayTextureID = name;
    
    EAGLContext *preContex = [self getPreContext];
    
    [self setCurrentContext:self.context];
    
    if (!self.window) {
        
        [self setCurrentContext:preContex];
        
        return;
    }
    
    CIImage *image = [CIImage imageWithTexture:name size:size flipped:flipped colorSpace:NULL];
    
    image = [image imageByApplyingOrientation:orientation];
    
    if (image) {
        
        [self renderWithCImage:image];
    }else{
        
        NSLog(@"create image with texture failed.");
    }
    
    [self setCurrentContext:preContex];
}

- (void)renderWithCImage:(CIImage *)image
{
    _displayImage = image;
    [self display];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    EAGLContext *preContex = [self getPreContext];
    [self setCurrentContext:self.context];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if (_displayImage) {
        
        CGAffineTransform scale = CGAffineTransformMakeScale(self.contentScaleFactor, self.contentScaleFactor);
        CGRect rectDraw = CGRectApplyAffineTransform(self.bounds, scale);
        [self.ciContext drawImage:_displayImage inRect:rectDraw fromRect:[_displayImage extent]];
    }
    
    [self setCurrentContext:preContex];
}

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

@end
