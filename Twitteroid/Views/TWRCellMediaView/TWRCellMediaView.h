//
//  TWRCellMediaView.h
//  Twitteroid
//
//  Created by Mac on 25/07/15.
//  Copyright (c) 2015 Kievkao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWRCellMediaView : UIView

@property (nonatomic, strong) void (^mediaClickBlock)(BOOL isVideo, NSUInteger index);

- (void)setLinksToMedia:(NSArray *)images isForVideo:(BOOL)isForVideo;
- (void)removeAllFrames;

@end
