//
//  TWRLoginWebWireframe.h
//  Twitteroid
//
//  Created by Andrii Kravchenko on 5/30/16.
//  Copyright © 2016 Kievkao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TWRLoginWebWireframeProtocol.h"
#import "TWRLoginWebModuleDelegate.h"

@class STTwitterAPI;

@interface TWRLoginWebWireframe : NSObject <TWRLoginWebWireframeProtocol>

- (instancetype)initWithTwitterAPI:(STTwitterAPI *)twitterAPI;

- (void)presentLoginWebScreenFromViewController:(UIViewController*)viewController withURLRequest:(NSURLRequest *)request moduleDelegate:(id<TWRLoginWebModuleDelegate>)moduleDelegate;

@end
