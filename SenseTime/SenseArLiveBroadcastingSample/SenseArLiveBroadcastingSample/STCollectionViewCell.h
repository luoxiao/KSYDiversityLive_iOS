//
//  STCollectionViewCell.h
//  SenseArLiveBroadcastingSample
//
//  Created by sluin on 16/8/8.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface STCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;

@property (weak, nonatomic) IBOutlet UIImageView *downloadSign;

@property (weak, nonatomic) IBOutlet UIImageView *adTypeView;

@property (weak, nonatomic) IBOutlet UILabel *lblInfo;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end
