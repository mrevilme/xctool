//
//  BuildOutputReporter.m
//  xctool
//
//  Created by Emil Palm on 5/14/13.
//  Copyright (c) 2013 Fred Potter. All rights reserved.
//

#import "JSONReporter.h"

@implementation JSONReporter
- (void)passThrough:(NSDictionary *)event {
    @synchronized(self.events) {
        [self.events addObject:event];
    }
}


- (void)beginAction:(NSDictionary *)event { [self passThrough:event]; }
- (void)endAction:(NSDictionary *)event { [self passThrough:event]; }
- (void)beginBuildTarget:(NSDictionary *)event { [self passThrough:event]; }
- (void)endBuildTarget:(NSDictionary *)event { [self passThrough:event]; }
- (void)beginBuildCommand:(NSDictionary *)event { [self passThrough:event]; }
- (void)endBuildCommand:(NSDictionary *)event { [self passThrough:event]; }

- (void)beginXcodebuild:(NSDictionary *)event {
    self.events = [NSMutableArray arrayWithCapacity:100];
    [self passThrough:event];
}
- (void)endXcodebuild:(NSDictionary *)event {
    
    [self passThrough:event];
    
    NSError *error = nil;
    NSData *eventData = [NSJSONSerialization dataWithJSONObject:[self rootObject]
                                                        options:0
                                                          error:&error];
    NSAssert(eventData != nil,
             @"Failed to encode event with error: %@ for event: %@",
             [error localizedFailureReason], [self rootObject]);
    
    [self.outputHandle writeData:eventData];
    [self.outputHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (id) rootObject {
    return self.events;
}

- (void)beginOcunit:(NSDictionary *)event { [self passThrough:event]; }
- (void)endOcunit:(NSDictionary *)event { [self passThrough:event]; }
- (void)beginTestSuite:(NSDictionary *)event { [self passThrough:event]; }
- (void)endTestSuite:(NSDictionary *)event { [self passThrough:event]; }
- (void)beginTest:(NSDictionary *)event { [self passThrough:event]; }
- (void)endTest:(NSDictionary *)event { [self passThrough:event]; }
- (void)testOutput:(NSDictionary *)event { [self passThrough:event]; }
- (void)message:(NSDictionary *)event { [self passThrough:event]; }

@end
