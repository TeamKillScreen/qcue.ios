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
#import <PebbleKit/PebbleKit.h>

@interface UserViewController () <PBPebbleCentralDelegate>

@property (nonatomic, readonly, strong) NSString *queueId;
@property (nonatomic, readonly, strong) NSString *userId;
@property (nonatomic, readonly, strong) NSString *userName;

@property (nonatomic, readonly, strong) Firebase *firebase;

@property (nonatomic, readonly, strong) NSMutableDictionary *users;
@property (nonatomic, readonly, strong) NSMutableArray *keys;

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) PBWatch *watch;

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

- (instancetype)initWithQueueId:(NSString *)queueId userId:(NSString *)userId userName:(NSString *)userName
{
    self = [super init];
    
    if (self) {
        _queueId = queueId;
        _userId = userId;
        _userName = userName;
        
        NSString *urlFormat = @"https://qcue-live.firebaseio.com/queues/%@/users";
        NSString *url = [NSString stringWithFormat:urlFormat, self.queueId];
        
        // NSLog(@"url: %@", url);
        
        _firebase = [[Firebase alloc] initWithUrl:url];
        
        _users = [[NSMutableDictionary alloc] init];
        _keys = [[NSMutableArray alloc] init];
        
        [self configureNavigationController];
        [self configureView];
        
        [self observeFirebase];
        
        // Pebble!
        self.watch = [[PBPebbleCentral defaultCentral] lastConnectedWatch];
    }
    
    return self;
}

#pragma mark - Private implementation

- (void)configureNavigationController
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationItem.title = self.userName;
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
        NSString *positionText;
        
        for (NSString *key in self.users) {
            NSDictionary *user = [self.users objectForKey:key];
            NSString *userId = [user objectForKey:@"userId"];
            
            if ([userId isEqualToString:self.userId]) {
                NSInteger position = [self.keys indexOfObject:key] + 1;
                
                // NSLog(@"updatePosition: %ld", (long)position);
                
                positionText = [NSString stringWithFormat:@"%ld", (long)position];
                
                self.label.textColor = [self colorForPosition:position];
                self.label.text = positionText;
                
                [self vibrateForPosition:position];
                
                foundUser = YES;
            }
        }

        NSNumber *positionKey = @(0);

        if (foundUser) {
            NSDictionary *update = @{ positionKey: positionText };
            
            [self.watch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
                if (error) {
                    NSLog(@"Pebble error: \"%@\".", error.description);
                    
                } else {
                    NSLog(@"Pebble sent: %@.", positionText);
                    
                }
            }];
            // });
            
        } else {
            self.label.textColor = [UIColor blackColor];
            self.label.text = @"Bye!";

            NSDictionary *update = @{ positionKey: @"bye" };
            
            [self.watch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
                if (error) {
                    NSLog(@"Pebble error: \"%@\".", error.description);
                    
                } else {
                    NSLog(@"Pebble sent: %@.", positionText);
                    
                }
            }];
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
    
    // NSLog(@"self.vibrationCount: %ld", (long)self.vibrationCount);
    
    self.vibrationCount--;
    
    if (self.vibrationCount <= 0) {
        [timer invalidate];
        timer = nil;
    }
}

- (void)observeFirebase
{
    [self.firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        // NSLog(@"Name: %@", snapshot.name);
        // NSLog(@"Value: %@", snapshot.value);
        
        [self.users setObject:snapshot.value forKey:snapshot.name];
        [self.keys addObject:snapshot.name];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updatePosition];
        });
    }];
    
    [self.firebase observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        // NSLog(@"Name: %@", snapshot.name);
        // NSLog(@"Value: %@", snapshot.value);
        
        [self.users removeObjectForKey:snapshot.name];
        [self.keys removeObject:snapshot.name];
        
        [self updatePosition];
    }];
}

#pragma mark - Pebble implementation

- (void)setWatch:(PBWatch *)watch
{
    _watch = watch;
    
    uint8_t bytes[] = { 0x1D, 0x86, 0x6D, 0xDA, 0xE8, 0x22, 0x43, 0x28, 0xA9, 0x00, 0x5F, 0x4E, 0x4B, 0x31, 0x16, 0xDA };
    NSData *uuid = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    [self.watch appMessagesSetUUID:uuid];
    
    NSLog(@"Pebble: Connected");
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew
{
    self.watch = watch;
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch
{
    [[[UIAlertView alloc] initWithTitle:@"Pebble Disconnected." message:[watch name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    
    if (self.watch == watch || [watch isEqual:self.watch]) {
        self.watch = nil;
    }
}

@end
