//
//  ViewController.m
//  SenseArLiveBroadcastingSample
//
//  Created by sluin on 16/7/8.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "BroadcasterViewController.h"


@interface ViewController () <UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (weak, nonatomic) IBOutlet UILabel *lblStatus;

@property (nonatomic , copy) NSString *strAppID;
@property (nonatomic , copy) NSString *strSDKKey;

@property (nonatomic , copy) NSString *strAppServer;
@property (nonatomic , copy) NSString *strSDKServer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.textField.text = [NSString stringWithFormat:@"%d", arc4random() % 1000 * 1000000];
    
}


- (IBAction)onBtnStartBroadcasting:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请开启相机访问权限" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
    
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined) {
        
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            
            if (!granted) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [alert show];
                });
            }else{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    [self loginAndStartBroadcasting];
                });
            }
        }];
    }else if(videoAuthStatus == AVAuthorizationStatusRestricted ||
             videoAuthStatus == AVAuthorizationStatusDenied) {
        
        [alert show];
    }else{
        
        [self loginAndStartBroadcasting];
    }
}

- (void)loginAndStartBroadcasting
{
    [self.lblStatus setText:@""];
    
    if ([self validateWithText:self.textField.text]) {
        
        NSString *strURL = [NSString stringWithFormat:@"http://%@/sdkserver/login?broadcaster_id=%@&type=1" , APP_SERVER, self.textField.text];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:strURL]];
        [request setHTTPMethod:@"POST"];
        [request setTimeoutInterval:30];
        
        NSData *dataRet = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        
        if (!dataRet) {
            
            [self.lblStatus setText:@"* 数据获取失败"];
            
            return;
        }
        
        NSDictionary *dicRet = [NSJSONSerialization JSONObjectWithData:dataRet options:NSJSONReadingAllowFragments error:nil];
        
        if (!dicRet) {
            
            [self.lblStatus setText:@"* 数据解析失败"];
            
            return;
        }
        
        
        if ([[dicRet objectForKey:@"status"] intValue] == 0) {
            
            NSString *strStreamingInfo = [dicRet objectForKey:@"stream"];
            
            NSData *streamingInfoData = [strStreamingInfo dataUsingEncoding:NSUTF8StringEncoding];
            
            NSDictionary * dicStreamingInfo = [NSJSONSerialization JSONObjectWithData:streamingInfoData options:NSJSONReadingAllowFragments error:nil];
            
            NSString *strRTMPURL = [NSString stringWithFormat:@"rtmp://%@/%@/%@?key=%@" ,
                                    [[[dicStreamingInfo objectForKey:@"hosts"] objectForKey:@"publish"] objectForKey:@"rtmp"] ,
                                    [dicStreamingInfo objectForKey:@"hub"] ,
                                    [dicStreamingInfo objectForKey:@"title"] ,
                                    [dicStreamingInfo objectForKey:@"publishKey"]
                                    ];
            
            
            
            BroadcasterViewController *broadcasterVC = [self.storyboard instantiateViewControllerWithIdentifier:@"BroadcasterViewController"];
            
            broadcasterVC.strBroadcasterID = self.textField.text;
            broadcasterVC.strRTMPURL = strRTMPURL;
            
            [self.navigationController pushViewController:broadcasterVC animated:YES];
            
            
        }else{
            
            [self.lblStatus setText:@"* 主播ID冲突 , 请更换新ID"];
        }
        
    }else{
        
        [self.lblStatus setText:@"* 请输入合法ID"];
        
    }
}


- (BOOL)validateWithText:(NSString *)str
{
    NSString *strPredicate = @"^[a-z0-9A-Z]{6,}$";
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat: @"SELF MATCHES %@", strPredicate];
    
    return [predicate evaluateWithObject:str];
}

#pragma - mark -
#pragma - mark textfiled  delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.lblStatus setText:@""];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isFirstResponder]) {
        
        return [textField resignFirstResponder];
    }
    
    return NO;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    
    [super touchesBegan:touches withEvent:event];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
