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

@property (nonatomic, strong) UILabel *label;

- (void)configureNavigationController;
- (void)observeFirebase;
- (void)configureView;
- (void)updatePosition;

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
        [self configureView];
        
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

- (void)configureView
{
    self.label = [[UILabel alloc] initWithFrame:self.view.frame];
    UIFont *font = [UIFont boldSystemFontOfSize:96];
    
    self.label.font = font;
    
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor greenColor];
    self.label.text = @"2";
    
    [self.view addSubview:self.label];
}

- (void)updatePosition
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // for each user in self.users
        //     if user["userId"] == self.userId
        
        for (NSString *key in self.users) {
            NSDictionary *user = [self.users objectForKey:key];
            NSString *userId = [user objectForKey:@"userId"];
            
            if ([userId isEqualToString:self.userId]) {
                NSInteger index = [self.keys indexOfObject:key];
                NSNumber *position = [NSNumber numberWithInteger:index + 1];
                
                NSLog(@"updatePosition: %@", position);
                self.label.text = [position stringValue];
            }
        }
    });
}

- (void)observeFirebase
{
    [self.firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"Name: %@", snapshot.name);
        NSLog(@"Value: %@", snapshot.value);
        
        [self.users setObject:snapshot.value forKey:snapshot.name];
        [self.keys addObject:snapshot.name];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updatePosition];
        });
    }];
    
    [self.firebase observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"Name: %@", snapshot.name);
        NSLog(@"Value: %@", snapshot.value);
        
        [self.users removeObjectForKey:snapshot.name];
        [self.keys removeObject:snapshot.name];
        
        [self updatePosition];
    }];
}

@end
