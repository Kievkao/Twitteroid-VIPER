//
//  TWRFeedViewModel.h
//  Twitteroid
//
//  Created by Andrii Kravchenko on 2/14/16.
//  Copyright © 2016 Kievkao. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TWRFeedViewModelDelegate <NSObject>

- (void)viewModelWillChangeContent;
- (void)viewModelDidChangeContent;
- (void)rowNeedToBeInserted:(NSIndexPath *)indexPath;
- (void)rowNeedToBeDeleted:(NSIndexPath *)indexPath;
- (void)rowNeedToBeUpdated:(NSIndexPath *)indexPath;
- (void)rowNeedToBeMoved:(NSIndexPath *)oldIndexPath newIndexPath:(NSIndexPath *)newIndexPath;
- (void)needToReloadData;
- (void)showAlertWithTitle:(NSString *)title text:(NSString *)text;
@end


@interface TWRFeedViewModel : NSObject

- (instancetype)initWithHashtag:(NSString *)hashtag delegate:(UIViewController<TWRFeedViewModelDelegate> *)delegate;
- (void)checkEnvironmentAndLoadFromTweetID:(NSString *)tweetID withCompletion:(void (^)(NSError *error))loadingCompletion;
- (void)loadFromTweetID:(NSString *)tweetID withCompletion:(void (^)(NSError *error))loadingCompletion;
- (void)parseTweetsArray:(NSArray *)items forHashtag:(NSString *)hashtag;

- (void)startFetching;

- (id)dataObjectAtIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)numberOfDataSections;
- (NSUInteger)numberOfObjectsInSection:(NSUInteger)section;

@property (weak, nonatomic) id<TWRFeedViewModelDelegate> delegate;

@end