# 金山云-商汤科技动态贴纸（AR直播）

##1.概述

金山视频云拥有功能全面的推流和拉流解决方案，商汤在图像识别和图像处理有多年的技术积累，两家在各自领域的强者结合一定会产生出不一样的效果，下面我们就介绍一下，集成了金山采集、编码、推流功能和商汤人脸识别、图像处理功能的例子。

商汤科技动态贴纸效果(脸部识别)视频请点击一下链接：

[![ScreenShot](https://raw.githubusercontent.com/wiki/ksvc/KSYDiversityLive_iOS/images/st/st_bi.jpg)](http://www.bilibili.com/video/av7410986/)

商汤科技动态贴纸效果(肢体识别)视频请点击一下链接：

[![ScreenShot](https://raw.githubusercontent.com/wiki/ksvc/KSYDiversityLive_iOS/images/st/stbodyios_bilibili.jpg)](http://www.bilibili.com/video/av8063572/)


##2.集成

###2.1 需要从商汤获取安装包，framework下为试用版本。[详细文档介绍](https://ks3-cn-beijing.ksyun.com/ksy.vcloud.sdk/Ios/%E7%89%B9%E6%95%88%E8%B4%B4%E7%BA%B8%E8%AF%B4%E6%98%8E%E6%96%87%E6%A1%A3%20v3.2.2.pdf)
###2.2 需要从商汤获取Appid,AppKey.
###2.3 开源了金山封装的KSYSTFilter，把贴纸做成一个滤镜模式，和其他美颜滤镜相同的使用方式。

##3.KSYSTFilter接口

###3.1初始化(需要传入appID，appKey）

-(id)initWithAppid:(NSString *)appID
            appKey:(NSString *)appKey;

###3.2选择贴纸

- (void)changeSticker:(int) index
            onSuccess:(void (^)(SenseArMaterial *))completeSuccess
            onFailure:(void (^)(SenseArMaterial *, int, NSString *))completeFailure
           onProgress:(void (^)(SenseArMaterial *, float, int64_t))processingCallBack;

注意需要在获取贴纸列表后选择，获取贴纸列表回调总的贴纸数，客户可自行选择业务需要的贴纸。 

###3.3 高级功能（关闭贴纸，关闭美颜）

注意美颜效果请自行调节，KSYSTFilter里的只是推荐美颜效果。

## 4. 效果展示
## 效果展示
| | |
| :---: | :---:|
|sticker1| sticker2 |
|![sticker1](https://raw.githubusercontent.com/wiki/ksvc/KSYDiversityLive_iOS/images/fu/IMG_0245.PNG )| ![sticker2](https://raw.githubusercontent.com/wiki/ksvc/KSYDiversityLive_iOS/images/fu/IMG_0246.PNG )|
|sticker3| sticker4 |
|![sticker3](https://raw.githubusercontent.com/wiki/ksvc/KSYDiversityLive_iOS/images/fu/IMG_0247.PNG)| ![sticker4](https://raw.githubusercontent.com/wiki/ksvc/KSYDiversityLive_iOS/images/fu/IMG_0249.PNG)|
|sticker5| sticker6|
|![sticker3](https://raw.githubusercontent.com/wiki/ksvc/KSYDiversityLive_iOS/images/fu/IMG_0251.PNG)| ![sticker4](https://raw.githubusercontent.com/wiki/ksvc/KSYDiversityLive_iOS/images/fu/IMG_0252.PNG)|



## 5. 反馈与建议
### 5.1 金山云
* 主页：[金山云](http://www.ksyun.com/)
* 邮箱：<zengfanping@kingsoft.com>
* QQ讨论群：574179720
* Issues:https://github.com/ksvc/KSYDiversityLive_iOS/issues

### 5.2 商汤科技
* 主页：[SenseMe](http://www.sensetime.com/aboutUs/)
* 咨询电话：010-52725279（周一至周五 9:30 - 18:00）
* 商务合作：business@sensetime.com
* 媒体合作：media@sensetime.com
* 市场合作：mkt@sensetime.com


