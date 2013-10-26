//
//  QueueViewController.m
//  Qcue
//
//  Created by Alan Gorton on 26/10/2013.
//  Copyright (c) 2013 TeamKillScreen. All rights reserved.
//

#import "QueueViewController.h"

#include <Firebase/Firebase.h>

@interface QueueViewController ()

@property (nonatomic, readonly, strong) NSString *queueName;
@property (nonatomic, readonly, strong) NSString *queueId;

@property (nonatomic, readonly, strong) Firebase *firebase;
@property (nonatomic, readonly, strong) NSMutableDictionary *users;
@property (nonatomic, readonly, strong) NSMutableArray *keys;

- (void)configureNavigationController;

@end

@implementation QueueViewController

#pragma mark - UITableViewController implementation

- (instancetype)initWithQueueId:(NSString *)queueId named:(NSString *)queueName
{
    self = [super init];

    if (self) {
        _queueId = queueId;
        _queueName = queueName;
        
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

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSString *key = [self.keys objectAtIndex:indexPath.row];
    NSDictionary *user = [self.users objectForKey:key];
    
    NSLog(@"key: %@", key);
    NSLog(@"user: %@", user);
    
    cell.textLabel.text = [user objectForKey:@"userId"];
    
    return cell;
}

#pragma mark - Private implementation

- (void)configureNavigationController
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationItem.title = self.queueName;
}

- (void)observeFirebase
{
    [self.firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"%@ -> %@", snapshot.name, snapshot.value);
        
        [self.users setObject:snapshot.value forKey:snapshot.name];
        [self.keys addObject:snapshot.name];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

@end
