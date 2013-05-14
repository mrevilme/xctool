//
//  RedisPubSubReporter.m
//  xctool
//
//  Created by Emil Palm on 5/14/13.
//  Copyright (c) 2013 Fred Potter. All rights reserved.
//

#import "RedisPubReporter.h"
static NSString *kRedisChannelKey = @"channel";
static NSString *kRedisHostKey = @"redis-host";
static NSString *kRedisPortKey = @"redis-port";
static NSString *kRedisUsernameKey = @"redis-username";
static NSString *kRedisPasswordKey = @"redis-password";
static NSString *kRedisDatabaseKey = @"redis-database";

@implementation RedisPubReporter
+ (NSString *) reporterName {
    return @"redis-pub";
}

- (void)setReporterOptions: (NSDictionary *) data {
    NSArray *keys = [data allKeys];
    if ( [keys containsObject:kRedisChannelKey] ) {
        [self setChannel:[data objectForKey:kRedisChannelKey]];
    }
    
    if ( [keys containsObject:kRedisHostKey] ) {
        [self setRedisHost:[data objectForKey: kRedisHostKey]];
    }
    
    if ( [keys containsObject:kRedisPortKey] ) {
        [self setRedisPort:[NSNumber numberWithInteger:[[data objectForKey:kRedisPortKey] integerValue]]];
    }
    
    if ( [keys containsObject:kRedisDatabaseKey] ) {
        [self setRedisDatabase:[NSNumber numberWithInteger:[[data objectForKey:kRedisDatabaseKey] integerValue]]];
    }

    if ( [keys containsObject:kRedisUsernameKey]) {
        [self setRedisUsername:[data objectForKey:kRedisUsernameKey]];
    }
    
    if ( [keys containsObject:kRedisPasswordKey]) {
        [self setRedisPassword:[data objectForKey:kRedisPasswordKey]];
    }
}

- (id)init {
    self = [super init];
    if ( self ) {
        self.redisHost = @"localhost";
        self.redisPort = @6379;
    }
    return self;
}

- (void) connectRedisClient {
    if ( [self redisClient] ) {
        [self.redisClient close];
        self.redisClient = nil;
    }

    if (  [self redisDatabase] ) {
        self.redisClient = [ObjCHiredis redis:self.redisHost
                                           on:self.redisPort
                                           db:self.redisDatabase];
    } else {
        self.redisClient = [ObjCHiredis redis:self.redisHost
                                           on:self.redisPort];
    }

    if ( [self redisClient] && [self redisUsername] && [self redisPassword] ) {
        [self.redisClient commandArgv:@[@"AUTH",self.redisUsername,self.redisPassword]];
    }

}

- (void)passThrough:(NSDictionary *)event
{
    
    if ( ![self redisClient] ) {
        [self connectRedisClient];
    }
    
    NSError *error = nil;
    NSData *eventData = [NSJSONSerialization dataWithJSONObject:event
                                                        options:0
                                                          error:&error];
    NSAssert(eventData != nil,
             @"Failed to encode event with error: %@ for event: %@",
             [error localizedFailureReason], event);
    
    NSAssert(self.channel != nil, @"Channel is not configured for redis pub");
    [self.redisClient commandArgv:@[@"PUBLISH",self.channel, [[NSString alloc] initWithData:eventData encoding:NSUTF8StringEncoding]]];
    
}

- (void)beginAction:(NSDictionary *)event { [self passThrough:event]; }
- (void)endAction:(NSDictionary *)event { [self passThrough:event]; }
- (void)beginBuildTarget:(NSDictionary *)event { [self passThrough:event]; }
- (void)endBuildTarget:(NSDictionary *)event { [self passThrough:event]; }
- (void)beginBuildCommand:(NSDictionary *)event { [self passThrough:event]; }
- (void)endBuildCommand:(NSDictionary *)event { [self passThrough:event]; }
- (void)beginXcodebuild:(NSDictionary *)event { [self passThrough:event]; }
- (void)endXcodebuild:(NSDictionary *)event { [self passThrough:event]; }
- (void)beginOcunit:(NSDictionary *)event { [self passThrough:event]; }
- (void)endOcunit:(NSDictionary *)event { [self passThrough:event]; }
- (void)beginTestSuite:(NSDictionary *)event { [self passThrough:event]; }
- (void)endTestSuite:(NSDictionary *)event { [self passThrough:event]; }
- (void)beginTest:(NSDictionary *)event { [self passThrough:event]; }
- (void)endTest:(NSDictionary *)event { [self passThrough:event]; }
- (void)testOutput:(NSDictionary *)event { [self passThrough:event]; }
- (void)message:(NSDictionary *)event { [self passThrough:event]; }


@end
