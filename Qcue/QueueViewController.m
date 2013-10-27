//
//  QueueViewController.m
//  Qcue
//
//  Created by Alan Gorton on 26/10/2013.
//  Copyright (c) 2013 TeamKillScreen. All rights reserved.
//

#import "QueueViewController.h"
#import "UserViewController.h"

#include <Firebase/Firebase.h>

@interface QueueViewController ()

@property (nonatomic, readonly, strong) NSString *queueName;
@property (nonatomic, readonly, strong) NSString *queueId;

@property (nonatomic, readonly, strong) Firebase *queueFirebase;
@property (nonatomic, readonly, strong) Firebase *usersFirebase;

@property (nonatomic, readonly, strong) NSMutableDictionary *queueUsers;
@property (nonatomic, readonly, strong) NSMutableArray *queueUserKeys;

@property (nonatomic, readonly, strong) NSMutableDictionary *users;
@property (nonatomic, readonly, strong) NSMutableArray *userKeys;

- (void)configureNavigationController;
- (void)refreshTableView;
- (void)observeQueueFirebase;

@end

@implementation QueueViewController

#pragma mark - UITableViewController implementation

- (instancetype)initWithQueueId:(NSString *)queueId named:(NSString *)queueName
{
    self = [super init];

    if (self) {
        _queueId = queueId;
        _queueName = queueName;
        
        NSString *queueUrlFormat = @"https://qcue-live.firebaseio.com/queues/%@/users";
        NSString *queueUrl = [NSString stringWithFormat:queueUrlFormat, self.queueId];

        NSString *usersUrlFormat = @"https://qcue-live.firebaseio.com/users";
        NSString *usersUrl = [NSString stringWithFormat:usersUrlFormat, self.queueId];
        
        // NSLog(@"usersUrl: %@", usersUrl);
        
        _queueFirebase = [[Firebase alloc] initWithUrl:queueUrl];
        _queueUsers = [[NSMutableDictionary alloc] init];
        _queueUserKeys = [[NSMutableArray alloc] init];

        _usersFirebase = [[Firebase alloc] initWithUrl:usersUrl];
        _users = [[NSMutableDictionary alloc] init];
        _userKeys = [[NSMutableArray alloc] init];

        [self configureNavigationController];
        [self observeUsersFirebase];
        [self observeQueueFirebase];
    }
    
    return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.queueUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSString *queueUserKey = [self.queueUserKeys objectAtIndex:indexPath.row];
    NSDictionary *queueUser = [self.queueUsers objectForKey:queueUserKey];
    NSString *userId = [queueUser objectForKey:@"userId"];
    
    NSDictionary *user = [self.users objectForKey:userId];
    
    NSString *text;
    
    if (user) {
        text = [user objectForKey:@"fullName"];
    } else {
        text = @"???";
    }
    
    // NSLog(@"key: %@", key);
    // NSLog(@"user: %@", user);
    
    cell.textLabel.text = text;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [self.queueUserKeys objectAtIndex:indexPath.row];
    NSDictionary *queueUser = [self.queueUsers objectForKey:key];
    NSString *userId = [queueUser objectForKey:@"userId"];
    
    NSDictionary *user = [self.users objectForKey:userId];
    
    NSString *userName;
    
    if (user) {
        userName = [user objectForKey:@"fullName"];
    } else {
        userName = @"???";
    }
    
    // NSLog(@"key: %@", key);
    // NSLog(@"userId: %@", userId);

    UserViewController *viewController = [[UserViewController alloc] initWithQueueId:self.queueId userId:userId userName:userName];
    
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Private implementation

- (void)configureNavigationController
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationItem.title = self.queueName;
}

- (void)observeQueueFirebase
{
    [self.queueFirebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        // NSLog(@"Name: %@", snapshot.name);
        // NSLog(@"Value: %@", snapshot.value);
        
        [self.queueUsers setObject:snapshot.value forKey:snapshot.name];
        [self.queueUserKeys addObject:snapshot.name];

        [self refreshTableView];
    }];

    [self.queueFirebase observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        // NSLog(@"Name: %@", snapshot.name);
        // NSLog(@"Value: %@", snapshot.value);
        
        [self.queueUsers removeObjectForKey:snapshot.name];
        [self.queueUserKeys removeObject:snapshot.name];
        
        [self refreshTableView];
    }];
}

- (void)observeUsersFirebase
{
    [self.usersFirebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        // NSLog(@"Name: %@", snapshot.name);
        // NSLog(@"Value: %@", snapshot.value);
        
        [self.users setObject:snapshot.value forKey:snapshot.name];
        [self.userKeys addObject:snapshot.name];
        
        [self refreshTableView];
    }];

    [self.usersFirebase observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        // NSLog(@"Name: %@", snapshot.name);
        // NSLog(@"Value: %@", snapshot.value);
        
        [self.users setObject:snapshot.value forKey:snapshot.name];
        [self.userKeys addObject:snapshot.name];
        
        [self refreshTableView];
    }];

    [self.usersFirebase observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        // NSLog(@"Name: %@", snapshot.name);
        // NSLog(@"Value: %@", snapshot.value);
        
        [self.users removeObjectForKey:snapshot.name];
        [self.userKeys removeObject:snapshot.name];
        
        [self refreshTableView];
    }];
}

- (void)refreshTableView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end
