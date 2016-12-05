//
//  STStickerLoader.m
//  KSYSTStreamer
//
//  Created by 孙健 on 2016/11/21.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import "STStickerLoader.h"
#import <ZipArchive/SSZipArchive.h>

@interface STStickerLoader ()
@property (nonatomic, strong) NSMutableArray *stickerPackges;
@end

@implementation STStickerLoader

+ (instancetype)sharedManager{
    static STStickerLoader *singleManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleManager = [[self alloc] init];
    });
    return singleManager;
}
- (instancetype)init{
    self = [super init];
    if (self) {
        self.stickerPackges = [[NSMutableArray alloc] initWithArray:@[]];
    }
    return self;
}

+ (void)firstCopy{
    NSString *rabbitPath = [[NSBundle mainBundle] pathForResource:@"rabbit" ofType:@"zip"];
    NSString *starwberryPath = [[NSBundle mainBundle] pathForResource:@"starwberry" ofType:@"zip"];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    path = [path stringByAppendingPathComponent:@"Stickers"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    NSArray *tmpList = [manager contentsOfDirectoryAtPath:path error:nil];
    if ([tmpList count] == 0) {
        [manager copyItemAtPath:rabbitPath toPath:[path stringByAppendingPathComponent:@"rabbit.zip"] error:nil];
        [manager copyItemAtPath:starwberryPath toPath:[path stringByAppendingPathComponent:@"starwberry.zip"] error:nil];
    }
}
+ (void)updateTheStickers{
    [STStickerLoader firstCopy];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths[0] stringByAppendingPathComponent:@"Stickers"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    else{
        //find the zips in the Documents, and move it to th stickers
        NSArray *tmplist0 = [manager contentsOfDirectoryAtPath:paths[0] error:nil];
        for (NSString *file in tmplist0) {
            if ([[file pathExtension] isEqualToString:@"zip"]) {
                NSString *newPath = [path stringByAppendingPathComponent:file];
                [manager moveItemAtPath:[paths[0] stringByAppendingPathComponent:file] toPath:newPath error:nil];
            }
        }
        NSMutableArray *tmpList = [NSMutableArray arrayWithArray:[manager contentsOfDirectoryAtPath:path error:nil]];
        //NSLog(@"%@", tmpList);
        NSString *wrongPath = [path stringByAppendingPathComponent:@"__MACOSX"];
        if ([tmpList containsObject:@"__MACOSX"]) {
            [manager removeItemAtPath:wrongPath error:nil];
            [tmpList removeObject:@"__MACOSX"];
        }
        for(NSString *file in tmpList){
            NSString *packgePath = @"";
            if ([[file pathExtension] isEqualToString:@"zip"]) {
                packgePath = [path stringByAppendingPathComponent:file];
            }
            if (![[STStickerLoader sharedManager].stickerPackges containsObject:packgePath]) {
                 [(NSMutableArray *)([STStickerLoader sharedManager].stickerPackges) addObject:packgePath];
            }
        }
    }
}
+ (NSArray *)getStickersPaths{
    if ([[STStickerLoader sharedManager].stickerPackges count] > 0) {
        //NSLog(@"%@", [STStickerLoader sharedManager].stickerPackges);
        return (NSArray *)[STStickerLoader sharedManager].stickerPackges;
    }
    else{
        return nil;
    }
}
@end
