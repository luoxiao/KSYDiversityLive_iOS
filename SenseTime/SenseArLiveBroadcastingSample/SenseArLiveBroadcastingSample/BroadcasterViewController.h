//
//  BroadcasterViewController.h
//  SenseArLiveBroadcastingSample
//
//  Created by sluin on 16/7/9.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import <UIKit/UIKit.h>


#define APP_SERVER @"app.ad.sensetime.com"

@interface BroadcasterViewController : UIViewController

@property (nonatomic , copy) NSString *strBroadcasterID;
@property (nonatomic , copy) NSString *strRTMPURL;
@property (nonatomic , copy) NSURL *hostURL;

@end
