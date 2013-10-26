//
//  UserViewController.m
//  Qcue
//
//  Created by Alan Gorton on 27/10/2013.
//  Copyright (c) 2013 TeamKillScreen. All rights reserved.
//

#import "UserViewController.h"
#include <Firebase/Firebase.h>

@interface UserViewController ()

@property (nonatomic, readonly, strong) NSString *queueId;
@property (nonatomic, readonly, strong) NSString *userId;

@property (nonatomic, readonly, strong) Firebase *firebase;

@property (nonatomic, readonly, strong) NSMutableDictionary *users;
@property (nonatomic, readonly, strong) NSMutableArray *keys;

- (void)configureNavigationController;
- (void)observeFirebase;

@end

@implementation UserViewController

- (instancetype)initWithQueueId:(NSString *)queueId userId:(NSString *)userId
{
    self = [super init];
    
    if (self) {
        _userId = userId;
        _queueId = queueId;
        
        NSString *urlFormat = @"https://qcue-live.firebaseio.com/queues/%@/users";
        NSString *url = [NSString stringWithFormat:urlFormat, self.queueId];
        
        NSLog(@"url: %@", url);
        
        _firebase = [[Firebase alloc] initWithUrl:url];
        
        _users = [[NSMutableDictionary alloc] init];
        _keys = [[NSMutableArray alloc] init];
        
        [self configureNavigationController];
        [self observeFirebase];
    }
    
    return self;
}

#pragma mark - Private implementation

- (void)configureNavigationController
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationItem.title = self.userId;
}

- (void)observeFirebase
{
    [self.firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"%@ -> %@", snapshot.name, snapshot.value);
        
        [self.users setObject:snapshot.value forKey:snapshot.name];
        [self.keys addObject:snapshot.name];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // TODO: repaint.
        });
    }];
}

@end
