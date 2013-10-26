//
//  UserViewController.h
//  Qcue
//
//  Created by Alan Gorton on 27/10/2013.
//  Copyright (c) 2013 TeamKillScreen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserViewController : UIViewController

- (instancetype)initWithQueueId:(NSString *)queueId userId:(NSString *)userId;

@end
