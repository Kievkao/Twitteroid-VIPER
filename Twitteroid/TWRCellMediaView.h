//
//  TWRCellMediaView.h
//  Twitteroid
//
//  Created by Mac on 25/07/15.
//  Copyright (c) 2015 Kievkao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWRCellMediaView : UIView

- (void)setImages:(NSArray *)images;
- (void)setLinks:(NSArray *)links;
- (void)removeAllFrames;

@end