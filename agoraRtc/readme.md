## 金山云推流＋agora连麦 ##
IOS 连麦功能 （KSYLive_IOS + agora） 金山云开放平台，提供SDK全链路数据，可以和容易和第三方数据处理服务商合作。以下是金山直播SDK和agora实现的连麦功能。


----------
## 效果图 ##
## 如何集成？##

 - 客户需要自己指定agora的appid填入：
```
    _agoraKit = [[KSYAgoraClient alloc] initWithAppId;
```
 - 需要手动导入库文件：
```
AgoraRtcEngineKit.framework
videoprp.framework
```
 - pod方式导入库文件：
```
pod 'libksygpulive/KSYGPUResource', :git =>
'https://github.com/ksvc/KSYLive_iOS.git', :tag => 'v1.8.7’    pod
'libksygpulive/libksygpulive', :git =>
'https://github.com/ksvc/KSYLive_iOS.git', :tag => 'v1.8.7’
```
 - 手动导入文件列表：
```
> libyuv头文件（见demo目录）
> KSYAgoraClient.h/m
> KSYAgoraStreamerKit.h/m
```
## 代码结构 ##

 - KSYAgoraClient类：封装agora sdk
 - KSYAgoraStreamerKit类：音视频渲染层
 - KSYRTCAgoraVC类：demo UI层

## 采集＋推流＋连麦，你需要做的 ##
### 采集 ###

 - 参数设置：
```
(void) setCaptureCfg {
_kit.capPreset = [self.presetCfgView capResolution];//分辨率
_kit.videoFPS  = [self.presetCfgView frameRate];／／帧率
_kit.cameraPosition = [self.presetCfgView cameraPos];／／摄像头位置}
```
 - 美颜设置：
 
```
(void) onFilterChange:(id)sender{
    [_kit setupRtcFilter:self.ksyFilterView.curFilter];}
```
 - 启停预览
```
    [_kit startPreview:self.view];
    [_kit stopPreview];
```

 - 开启闪光灯，摄像头切换等参看demo

## 推流 ##

 - 参数设置：
```
(void) setStreamerCfg {
    if (_presetCfgView){
        _streamerBase.videoCodec       = [_presetCfgView videoCodec];//视频编码格式
        _streamerBase.videoInitBitrate = [_presetCfgView videoKbps]／／init码率
        _streamerBase.videoMaxBitrate  = [_presetCfgView videoKbps];／／最大码率
        _streamerBase.videoMinBitrate  = 0; //最小码率
        _streamerBase.audiokBPS        = [_presetCfgView audioKbps];／／音频码率
        _streamerBase.videoFPS         = [_presetCfgView frameRate];／／视频帧率
        _hostURL = [NSURL URLWithString:[_presetCfgView hostUrl]];／／推流地址
    }
```
 - 启停推流：
```
     [_streamerBase startStream:self.hostURL];
     [_kit.streamerBase stopStream];
```
## 连麦相关 ##

 - 参数设置
```
        - (void) setAgoraStreamerKitCfg {
        _kit.selfInFront = NO;//小窗口显示自己还是对方
        _kit.winRect = CGRectMake(0.6, 0.6, 0.3, 0.3);//设置小窗口大小
        _kit.rtcLayer = 4;//设置小窗口图层，因为主版本占用了1~3，设置为4
        _kit.onCallStart =^(int status){}//连麦接通后回调
        _kit.onCallStop = ^(int status){}//连麦停止回调
        _kit.onChannelJoin = ^(int status){}//加入通道回调
    }
```
 - 加入通道：
```
[_kit joinChannel:@"ksy22"];
```
 - 离开通道:
```
 [_kit leaveChannel];
```
## 深入了解？ ##

 - 阅读KSYAgoraClient.h/m,KSYAgoraStreamerKit.h/m
 - 参看[金山云推流sdk][1]
 - 参考[agora官方文档][2]
 

  [1]: https://github.com/ksvc/KSYLive_iOS/
  [2]: http://docs-origin.agora.io/cn/user_guide/Agora_Native_SDK_for_iOS_Reference_Manual.html