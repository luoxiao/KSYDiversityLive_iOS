//
//  STCollectionViewCell.m
//  SenseArLiveBroadcastingSample
//
//  Created by sluin on 16/8/8.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import "STCollectionViewCell.h"

@implementation STCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.thumbnail.layer setBorderWidth:0.0f];
    [self.loadingIndicator stopAnimating];
    [self.thumbnail setImage:nil];
}

@end
