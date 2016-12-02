##1.概述

金山视频云拥有功能全面的推流和拉流解决方案，商汤在图像识别和图像处理有多年的技术积累，两家在各自领域的强者结合一定会产生出不一样的效果，下面我们就介绍一下，集成了金山采集、编码、推流功能和商汤人脸识别、图像处理功能的例子。

##2.集成

###2.1开始集成
资源下载：

* 金山SDK：[github.com/ksvc/KSYLive_iOS](https://github.com/ksvc/KSYLive_iOS)


### 2.2 结构图
目前金山SDK流程结构图：
    
![Diagram](https://raw.githubusercontent.com/wiki/ksvc/KSYDiversityLive_iOS/images/fu/diagram.png)
  
那我们要做的事情是啥呢，请看下图：
  
![Diagram](https://raw.githubusercontent.com/wiki/ksvc/KSYDiversityLive_iOS/images/fu/SenseME.png)

###2.3开始集成

重要功能类介绍：

金山：


```
视频数据回调接口
@property(nonatomic, copy) void(^videoProcessingCallback)(CVPixelBufferRef pixelBuffer, CMTime timeInfo );
```

```
音频数据回调接口
@property(nonatomic, copy) void(^audioProcessingCallback)(CMSampleBufferRef sampleBuffer);
```

Sensetime:


```

添加了美颜、贴纸效果的图像数据回调
- (void)videoOutputWithTexture:(unsigned int)textOutput
                          size:(CGSize)size
                          time:(CMTime)timeInfo;
```

