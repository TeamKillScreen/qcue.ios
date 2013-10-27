//
//  UserViewController.m
//  Qcue
//
//  Created by Alan Gorton on 27/10/2013.
//  Copyright (c) 2013 TeamKillScreen. All rights reserved.
//

#import "UserViewController.h"

#import <AudioToolbox/AudioToolbox.h>
#include <Firebase/Firebase.h>

@interface UserViewController ()

@property (nonatomic, readonly, strong) NSString *queueId;
@property (nonatomic, readonly, strong) NSString *userId;

@property (nonatomic, readonly, strong) Firebase *firebase;

@property (nonatomic, readonly, strong) NSMutableDictionary *users;
@property (nonatomic, readonly, strong) NSMutableArray *keys;

@property (nonatomic, strong) UILabel *label;

@property (nonatomic) NSInteger vibrationCount;

- (void)configureNavigationController;
- (void)observeFirebase;
- (void)configureView;

- (void)updatePosition;
- (UIColor *)colorForPosition:(NSInteger)position;
- (void)vibrateForPosition:(NSInteger)position;
- (void)vibrate:(NSTimer *)timer;

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
    UIFont *font = [UIFont boldSystemFontOfSize:128];
    
    self.label.font = font;
    
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor blackColor];
    self.label.text = @"?";
    
    [self.view addSubview:self.label];
}

- (void)updatePosition
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL foundUser = NO;
        
        for (NSString *key in self.users) {
            NSDictionary *user = [self.users objectForKey:key];
            NSString *userId = [user objectForKey:@"userId"];
            
            if ([userId isEqualToString:self.userId]) {
                NSInteger position = [self.keys indexOfObject:key] + 1;
                
                NSLog(@"updatePosition: %d", position);
                
                self.label.textColor = [self colorForPosition:position];
                self.label.text = [NSString stringWithFormat:@"%d", position];
                
                [self vibrateForPosition:position];
                
                foundUser = YES;
            }
        }
        
        if (!foundUser) {
            self.label.textColor = [UIColor blackColor];
            self.label.text = @"Bye!";
        }
    });
}

- (UIColor *)colorForPosition:(NSInteger)position
{
    if (position > 3) {
        return [UIColor blackColor];
        
    } else if (position == 3) {
        return [UIColor redColor];
        
    } else if (position == 2) {
        return [UIColor yellowColor];
        
    }
    
    return [UIColor greenColor];
}

- (void)vibrateForPosition:(NSInteger)position
{
    if (position > 3) {
        return;
    }
    
    NSTimeInterval interval = 1;
    
    self.vibrationCount = 4 - position;
    [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(vibrate:) userInfo:nil repeats:YES];
}

- (void)vibrate:(NSTimer *)timer
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    NSLog(@"self.vibrationCount: %d", self.vibrationCount);
    
    self.vibrationCount--;
    
    if (self.vibrationCount <= 0) {
        [timer invalidate];
        timer = nil;
    }
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
