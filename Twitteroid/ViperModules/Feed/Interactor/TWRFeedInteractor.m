//
//  TWRFeedInteractor.m
//  Twitteroid
//
//  Created by Andrii Kravchenko on 5/30/16.
//  Copyright © 2016 Kievkao. All rights reserved.
//

#import "TWRFeedInteractor.h"
#import "TWRTweet.h"
#import "TWRPlace.h"
#import "TWRHashtag.h"
#import "TWRMedia.h"
#import "TWRManagedTweet.h"
#import "TWRManagedPlace.h"
#import "TWRManagedHashtag.h"
#import "TWRManagedMedia.h"
#import "TWRCoreDataManager.h"
#import "TWRTweetsDAOProtocol.h"

@interface TWRFeedInteractor() <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSString *hashTag;
@property (strong, nonatomic) id<TWRTweetsDAOProtocol> tweetsDAO;

@end

@implementation TWRFeedInteractor

- (instancetype)initWithHashtag:(NSString *)hashtag tweetsDAO:(id<TWRTweetsDAOProtocol>)tweetsDAO {
    self = [super init];
    if (self) {
        _hashTag = hashtag;
        _tweetsDAO = tweetsDAO;
        _fetchedResultsController = [[TWRCoreDataManager sharedInstance] fetchedResultsControllerForTweetsHashtag:self.hashTag];
        _fetchedResultsController.delegate = self;
    }
    return self;
}

- (void)retrieveTweetsFromID:(NSString *)tweetID {
    __typeof(self) __weak weakSelf = self;

    [self.tweetsDAO loadTweetsFromID:tweetID hashtag:self.hashTag withCompletion:^(NSArray<TWRTweet *> *tweets, NSError *error) {
        if (error == nil) {
            [weakSelf saveTweetsInStorage:tweets];
        }
        else {
            [weakSelf.presenter tweetsLoadDidFinishWithError:error];
        }
    }];

    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];

    if (error) {
        [self.presenter fetchCachedTweetsDidFinishWithError:error];
    }
}

- (void)retrieveTweetsFromIndexPath:(NSIndexPath *)indexPath {
    TWRTweet *lastTweet = [self dataObjectAtIndexPath:indexPath];
    NSString *lastTweetID = lastTweet.tweetId;

    [self retrieveTweetsFromID:lastTweetID];
}

- (void)saveTweetsInStorage:(NSArray<TWRTweet *> *)tweets {

    for (TWRTweet *tweet in tweets) {    
        [[TWRCoreDataManager sharedInstance] insertNewTweet:tweet];
    }

    [[TWRCoreDataManager sharedInstance] saveContext];
    [self.presenter tweetsLoadSuccess];
}

- (NSUInteger)numberOfDataSections {
    return [[self.fetchedResultsController sections] count];
}

- (NSUInteger)numberOfObjectsInSection:(NSUInteger)section {
    NSArray *sections = [self.fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];

    return [sectionInfo numberOfObjects];
}

- (TWRTweet *)dataObjectAtIndexPath:(NSIndexPath *)indexPath {
    TWRManagedTweet *managedTweet = [self.fetchedResultsController objectAtIndexPath:indexPath];
    TWRTweet *tweet = [TWRTweet new];

    tweet.createdAt = managedTweet.createdAt;
    tweet.hashtag = managedTweet.hashtag;
    tweet.text = managedTweet.text;
    tweet.tweetId = managedTweet.tweetId;
    tweet.userAvatarURL = managedTweet.userAvatarURL;
    tweet.userName = managedTweet.userName;
    tweet.userNickname = managedTweet.userNickname;
    tweet.isRetwitted = managedTweet.isRetwitted.boolValue;
    tweet.retwittedBy = managedTweet.retwittedBy;
    tweet.hashtags = managedTweet.hashtags;
    tweet.medias = managedTweet.medias;

    TWRManagedPlace *managedPlace = managedTweet.place;
    TWRPlace *place = [TWRPlace new];

    place.countryName = managedPlace.countryName;
    place.lattitude = managedPlace.lattitude;
    place.longitude = managedPlace.longitude;
    place.tweet = tweet;

    return tweet;
}

#pragma mark - NSFetchedResultsController

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.presenter beginTweetsUpdate];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.presenter finishTweetsUpdate];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.presenter insertTweetAtIndexPath:newIndexPath];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.presenter removeTweetAtIndexPath:newIndexPath];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self.presenter updateTweetAtIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.presenter moveTweetAtIndexPath:indexPath toNewIndexPath:newIndexPath];
            break;
        }
    }
}

@end
