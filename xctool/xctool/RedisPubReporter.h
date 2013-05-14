//
//  RedisPubSubReporter.h
//  xctool
//
//  Created by Emil Palm on 5/14/13.
//  Copyright (c) 2013 Fred Potter. All rights reserved.
//

#import "Reporter.h"
#import <ObjCHiredis.h>

@interface RedisPubReporter : Reporter<ExportedReporter>
@property(nonatomic,strong) NSString *channel;
@property(nonatomic,strong) NSNumber *redisPort;
@property(nonatomic,strong) NSString *redisHost;
@property(nonatomic,strong) NSNumber *redisDatabase;
@property(nonatomic,strong) NSString *redisUsername;
@property(nonatomic,strong) NSString *redisPassword;
@property(nonatomic,strong) ObjCHiredis *redisClient;
@end
