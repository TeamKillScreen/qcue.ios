//
//  QueuesViewController.m
//  Qcue
//
//  Created by Alan Gorton on 26/10/2013.
//  Copyright (c) 2013 TeamKillScreen. All rights reserved.
//

#import "QueuesViewController.h"
#import "QueueViewController.h"

#import <Firebase/Firebase.h>

@interface QueuesViewController ()

@property (nonatomic, readonly, strong) Firebase *firebase;
@property (nonatomic, readonly, strong) NSMutableDictionary *queues;
@property (nonatomic, readonly, strong) NSMutableArray *keys;

- (void)configureNavigationController;
- (void)refreshTableView;

@end

@implementation QueuesViewController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _firebase = [[Firebase alloc] initWithUrl:@"https://qcue-live.firebaseio.com/queues/"];

        _queues = [[NSMutableDictionary alloc] init];
        _keys = [[NSMutableArray alloc] init];
        
        [self configureNavigationController];
        [self observeFirebase];
    }
    
    return self;
}

#pragma mark - UITableViewController implementation

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.queues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"QueueCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSString *key = [self.keys objectAtIndex:indexPath.row];
    NSDictionary *queue = [self.queues objectForKey:key];
    
    NSLog(@"key: %@", key);
    NSLog(@"queue: %@", queue);
    
    cell.textLabel.text = [queue objectForKey:@"name"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [self.keys objectAtIndex:indexPath.row];
    NSDictionary *queue = [self.queues objectForKey:key];
    
    NSString *queueName = [queue objectForKey:@"name"];
    
    NSLog(@"key: %@", key);
    NSLog(@"queueName: %@", queueName);

    QueueViewController *viewController = [[QueueViewController alloc] initWithQueueId:key named:queueName];
    
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Private implementation

- (void)observeFirebase
{
    [self.firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"Name: %@", snapshot.name);
        NSLog(@"Value: %@", snapshot.value);
        
        [self.queues setObject:snapshot.value forKey:snapshot.name];
        [self.keys addObject:snapshot.name];
        
        [self refreshTableView];
    }];
    
    [self.firebase observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"Name: %@", snapshot.name);
        NSLog(@"Value: %@", snapshot.value);
        
        [self.queues removeObjectForKey:snapshot.name];
        [self.keys removeObject:snapshot.name];

        [self refreshTableView];
    }];
}

- (void)configureNavigationController
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationItem.title = @"Queues";
}

- (void)refreshTableView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end
