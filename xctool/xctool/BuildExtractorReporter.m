//
//  BuildExtractorReporter.m
//  xctool
//
//  Created by Emil Palm on 5/14/13.
//  Copyright (c) 2013 Fred Potter. All rights reserved.
//

#import "BuildExtractorReporter.h"

static NSString *kBuildExtractorBuildKey = @"build";
static NSString *kBuildExtractorAppKey = @"appFile";
static NSString *kBuildExtractorDSYMKey = @"dSYMFile";
static NSString *kBuildExtractorEventsKey = @"events";

@implementation BuildExtractorReporter

- (void)endBuildCommand:(NSDictionary *)event {
    [super endBuildCommand:event];
    NSString *title = [event objectForKey:kReporter_EndBuildCommand_TitleKey];
    BOOL success = [[event objectForKey:kReporter_EndBuildCommand_SucceededKey] boolValue];
    if ( [title hasPrefix:@"CodeSign"] && success) {
      NSMutableString *output = [title mutableCopy];
      [output replaceOccurrencesOfString:@"CodeSign "
                              withString:@""
                                 options:NSLiteralSearch
                                   range:NSMakeRange(0, [output length])];
      
      [output replaceOccurrencesOfString:@"\""
                              withString:@""
                                 options:NSLiteralSearch
                                   range:NSMakeRange(0, [output length])];
      if ( [output length] > 0 ) {
          [self.build setObject:output forKey:kBuildExtractorAppKey];
      }
    }
    
    if ( [title hasPrefix:@"Generate"] && [title hasSuffix:@".dSYM"] && success ) {
        NSMutableString *output = [title mutableCopy];
        [output replaceOccurrencesOfString:@"Generate "
                                withString:@""
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0, [output length])];
        if ( [output length] > 0 ) {
            [self.build setObject:output forKey:kBuildExtractorDSYMKey];
        }
    }
}

- (void)beginXcodebuild:(NSDictionary *)event {
    [super beginXcodebuild:event];
    self.build = [[NSMutableDictionary alloc] initWithCapacity:10];
    self.rootObject = @{kBuildExtractorBuildKey:self.build,kBuildExtractorEventsKey:self.events};
}


@end
