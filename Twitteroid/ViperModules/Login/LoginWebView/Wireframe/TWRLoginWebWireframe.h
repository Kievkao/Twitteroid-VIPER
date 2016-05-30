//
//  TWRLoginWebWireframe.h
//  Twitteroid
//
//  Created by Andrii Kravchenko on 5/30/16.
//  Copyright © 2016 Kievkao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TWRLoginWebWireframeProtocol.h"

@interface TWRLoginWebWireframe : NSObject <TWRLoginWebWireframeProtocol>

- (void)presentLoginWebScreenFromViewController:(UIViewController*)viewController withURLRequest:(NSURLRequest *)request;

@end
