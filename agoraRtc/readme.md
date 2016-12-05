## 金山云推流＋agora连麦 ##
IOS 连麦功能 （KSYLive_IOS + agora） 金山云开放平台，提供SDK全链路数据，可以和容易和第三方数据处理服务商合作。以下是金山直播SDK和agora实现的连麦功能。


----------
## 效果图 ##
## 集成说明 ##

 - 客户需要自己指定agora的appid填入：

    _agoraKit = [[KSYAgoraClient alloc] initWithAppId;

 - 需要手动导入库文件：

> AgoraRtcEngineKit.framework
> videoprp.framework

 - pod方式导入库文件：
>   pod 'libksygpulive/KSYGPUResource', :git =>
> 'https://github.com/ksvc/KSYLive_iOS.git', :tag => 'v1.8.7’    pod
> 'libksygpulive/libksygpulive', :git =>
> 'https://github.com/ksvc/KSYLive_iOS.git', :tag => 'v1.8.7’

 - 手动导入文件列表：

> libyuv头文件（见demo目录）
> KSYAgoraClient.h/m
> KSYAgoraStreamerKit.h/m

## 代码结构 ##

 - KSYAgoraClient类：封装agora sdk
 - KSYAgoraStreamerKit类：音视频渲染层
 - KSYRTCAgoraVC类：UI层

