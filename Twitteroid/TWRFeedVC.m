//
//  TWRFeedVC.m
//  Twitteroid
//
//  Created by Mac on 23/07/15.
//  Copyright (c) 2015 Kievkao. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "TWRFeedVC.h"
#import "TWRTwitCell.h"
#import "TWRTwitterAPIManager+TWRFeed.h"
#import "TWRTwitterAPIManager+TWRLogin.h"
#import "NSDateFormatter+LocaleAdditions.h"
#import "TWRFeedVC+TWRParsing.h"
#import "UIScrollView+INSPullToRefresh.h"
#import "INSTwitterPullToRefresh.h"
#import "INSCircleInfiniteIndicator.h"
#import "Reachability.h"

static NSUInteger const kTweetsLoadingPortion = 20;

@interface TWRFeedVC () <NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation TWRFeedVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self pullToRefreshSetup];
    [self infinitiveScrollSetup];
    [self startFetching];
}

- (NSDateFormatter *)dateFormatter {
    
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
        [_dateFormatter setDateFormat:@"eee MMM dd HH:mm:ss Z yyyy"];
    }
    
    return _dateFormatter;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
}

- (BOOL)isInternetActive {
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    return !(networkStatus == NotReachable);
}

#pragma mark - NSFetchedResultsController stuff
- (void)startFetching {
    
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    if (error) {
        [self showInfoAlertWithTitle:NSLocalizedString(@"Error", @"Error title") text:error.localizedDescription];
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self configureCell:(TWRTwitCell *)[self.tableView cellForRowAtIndexPath:indexPath] forIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (!_fetchedResultsController) {
        _fetchedResultsController = [TWRCoreDataManager fetchedResultsControllerForTweetsFeed];
        _fetchedResultsController.delegate = self;
    }
    
    return _fetchedResultsController;
}

#pragma mark - Infinitive scroll && PullToRefresh
- (void)pullToRefreshSetup {
    
    [self.tableView ins_addPullToRefreshWithHeight:60.0 handler:^(UIScrollView *scrollView) {
        
        if ([self isInternetActive]) {
            if ([[TWRTwitterAPIManager sharedInstance] isSessionLoginDone]) {
                [self loadPortionFromTweetID:nil withCompletion:^(NSError *error) {
                    [scrollView ins_endPullToRefresh];
                }];
            }
            else {
                [[TWRTwitterAPIManager sharedInstance] reloginWithCompletion:^(NSError *error) {
                    if (!error) {
                        [self loadPortionFromTweetID:nil withCompletion:^(NSError *error) {
                            [scrollView ins_endPullToRefresh];
                        }];
                    }
                    else {
                        [self showInfoAlertWithTitle:NSLocalizedString(@"Error", @"Error title") text:error.localizedDescription];
                    }
                }];
            }
        }
        else {
            [self showInfoAlertWithTitle:NSLocalizedString(@"Connection Failed", @"Connection Failed") text:NSLocalizedString(@"Please check your internet connection", @"Please check your internet connection")];
        }
    }];
    
    UIView <INSPullToRefreshBackgroundViewDelegate> *pullToRefresh = [self pullToRefreshViewFromCurrentStyle];
    self.tableView.ins_pullToRefreshBackgroundView.delegate = pullToRefresh;
    [self.tableView.ins_pullToRefreshBackgroundView addSubview:pullToRefresh];
}

- (void)loadPortionFromTweetID:(NSString *)tweetID withCompletion:(void (^)(NSError *error))loadingCompletion {
    
    [[TWRTwitterAPIManager sharedInstance] getFeedOlderThatTwitID:tweetID count:kTweetsLoadingPortion completion:^(NSError *error, NSArray *items) {
        if (!error) {
            [self parseTweetsArray:items];
            [TWRCoreDataManager saveContext:[TWRCoreDataManager mainContext]];
        }
        else {
            NSLog(@"Loading error");
        }
        
        loadingCompletion(error);
    }];
}

- (void)infinitiveScrollSetup {
    [self.tableView ins_addInfinityScrollWithHeight:60 handler:^(UIScrollView *scrollView) {
        
        if ([self isInternetActive]) {
            
            if ([[TWRTwitterAPIManager sharedInstance] isSessionLoginDone]) {
                TWRTweet *lastTweet = [self.fetchedResultsController objectAtIndexPath:[[self.tableView indexPathsForVisibleRows] lastObject]];
                NSString *lastTweetID = lastTweet.tweetId;
                
                [[TWRTwitterAPIManager sharedInstance] getFeedOlderThatTwitID:lastTweetID count:kTweetsLoadingPortion completion:^(NSError *error, NSArray *items) {
                    if (!error) {
                        [self parseTweetsArray:items];
                        [TWRCoreDataManager saveContext:[TWRCoreDataManager mainContext]];
                    }
                    else {
                        NSLog(@"Loading error");
                    }
                    [scrollView ins_endInfinityScrollWithStoppingContentOffset:YES];
                }];
            }
            else {
                [[TWRTwitterAPIManager sharedInstance] reloginWithCompletion:^(NSError *error) {
                    if (!error) {
                        TWRTweet *lastTweet = [self.fetchedResultsController objectAtIndexPath:[[self.tableView indexPathsForVisibleRows] lastObject]];
                        NSString *lastTweetID = lastTweet.tweetId;
                        
                        [[TWRTwitterAPIManager sharedInstance] getFeedOlderThatTwitID:lastTweetID count:kTweetsLoadingPortion completion:^(NSError *error, NSArray *items) {
                            if (!error) {
                                [self parseTweetsArray:items];
                                [TWRCoreDataManager saveContext:[TWRCoreDataManager mainContext]];
                            }
                            else {
                                NSLog(@"Loading error");
                            }
                            [scrollView ins_endInfinityScrollWithStoppingContentOffset:YES];
                        }];
                    }
                    else {
                        [self showInfoAlertWithTitle:NSLocalizedString(@"Error", @"Error title") text:error.localizedDescription];
                    }
                }];
            }
        }
        else {
            [self showInfoAlertWithTitle:NSLocalizedString(@"Connection Failed", @"Connection Failed") text:NSLocalizedString(@"Please check your internet connection", @"Please check your internet connection")];
            [scrollView ins_endInfinityScrollWithStoppingContentOffset:NO];
        }
    }];
    
    UIView <INSAnimatable> *infinityIndicator = [self infinityIndicatorViewFromCurrentStyle];
    [self.tableView.ins_infiniteScrollBackgroundView addSubview:infinityIndicator];
    [infinityIndicator startAnimating];
}

- (UIView <INSAnimatable> *)infinityIndicatorViewFromCurrentStyle {
    return [[INSCircleInfiniteIndicator alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
}

- (UIView <INSPullToRefreshBackgroundViewDelegate> *)pullToRefreshViewFromCurrentStyle {
    return [[INSTwitterPullToRefresh alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
}

#pragma mark - UITableView Datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 85;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TWRTweet *tweet = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    return [TWRTwitCell cellHeightForTableViewWidth:CGRectGetWidth(tableView.frame) tweetText:tweet.text mediaPresent:NO];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [self.fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    TWRTwitCell* cell = [tableView dequeueReusableCellWithIdentifier:[TWRTwitCell identifier] forIndexPath:indexPath];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(TWRTwitCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    TWRTweet *tweet = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [cell setTwitText:tweet.text];
}

+ (NSString *)identifier {
    return @"TWRFeedVC";
}

@end
