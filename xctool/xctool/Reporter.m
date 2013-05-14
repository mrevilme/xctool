//
// Copyright 2013 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Reporter.h"

#import <sys/stat.h>

#import "Options.h"
#import "JSONStreamReporter.h"
#import "JUnitReporter.h"
#import "PhabricatorReporter.h"
#import "TextReporter.h"

#import <objc/runtime.h>

NSString *ReporterMessageLevelToString(ReporterMessageLevel level) {
  switch (level) {
    case REPORTER_MESSAGE_DEBUG:
      return @"Debug";
    case REPORTER_MESSAGE_VERBOSE:
      return @"Verbose";
    case REPORTER_MESSAGE_INFO:
      return @"Info";
    case REPORTER_MESSAGE_WARNING:
      return @"Warning";
    case REPORTER_MESSAGE_ERROR:
      return @"Error";
  }
}

static NSArray *RegisteredReporters = nil;
static NSDictionary *systemReporters = nil;

void RegisterReporters(NSArray *reporters) {
  NSCAssert(RegisteredReporters == nil, @"Cannot register reporters twice.");
  NSCAssert(reporters != nil, @"Must have array of reporters to register.");
  RegisteredReporters = [reporters retain];
}

void UnregisterReporters(NSArray *reporters) {
  NSCAssert(reporters == RegisteredReporters, @"Cannot unregister reporters without first registering.");
  [RegisteredReporters release];
  RegisteredReporters = nil;
}

void ReportMessage(ReporterMessageLevel level, NSString *format, ...) {
  va_list args;
  va_start(args, format);

  NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];

  NSDate *now = [NSDate date];
  NSDictionary *event = @{
    @"event": kReporter_Events_Message,
    kReporter_Message_MessageKey: message,
    kReporter_Message_TimestampKey: [NSNumber numberWithDouble:[now timeIntervalSince1970]],
    kReporter_Message_LevelKey: ReporterMessageLevelToString(level),
  };

  for (Reporter *reporter in RegisteredReporters) {
    [reporter message:event];
  }
  va_end(args);
}

@implementation Reporter

+ (void)initialize {
  [super initialize];
  int classCount = objc_getClassList(NULL, 0);
  if ( classCount > 0 ) {
    NSMutableDictionary *m_systemReporters = [NSMutableDictionary dictionaryWithCapacity:classCount];
    Class *classes = (Class*)malloc(sizeof(Class)*classCount);;
    
    objc_getClassList(classes, classCount);
    for (int i=0; i<classCount; i++) {
      Class cls = classes[i];
      
      if ( !class_conformsToProtocol(cls, @protocol(ExportedReporter)) ) {
        continue;
      }
      NSString *reporterName = nil;
      if ( [cls respondsToSelector:@selector(reporterName)]) {
        reporterName = [[cls performSelector:@selector(reporterName)] lowercaseString];
      } else {
        reporterName =  [[NSStringFromClass(cls) lowercaseString] stringByReplacingOccurrencesOfString:@"reporter" withString:@""];
      }
      
      [m_systemReporters setObject:cls forKey:reporterName];
    }
    free(classes);
    
    systemReporters = [m_systemReporters copy];
  }
}

+ (NSArray *) availableReporters {
  return [systemReporters allKeys];
}

+ (Reporter *)reporterWithName:(NSString *)name outputPath:(NSString *)outputPath options:(Options *)options
{
  Class reporterClass = systemReporters[name];

  Reporter *reporter = [[[reporterClass alloc] init] autorelease];
  reporter.outputPath = outputPath;
  reporter.options = options;
  return reporter;
}

- (id)init
{
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc
{
  [_outputHandle release];
  [_outputPath release];
  [_options release];
  [super dealloc];
}

- (BOOL)openWithStandardOutput:(NSFileHandle *)standardOutput error:(NSString **)error
{
  if ([self.outputPath isEqualToString:@"-"]) {
    _outputHandle = [standardOutput retain];
    return YES;
  } else {
    NSFileManager *fileManager = [NSFileManager defaultManager];
      
    NSString *basePath = [self.outputPath stringByDeletingLastPathComponent];

    if ([basePath length] > 0) {
      BOOL isDirectory;
      BOOL exists = [fileManager fileExistsAtPath:basePath isDirectory:&isDirectory];
      if (!exists) {
        if (![fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil]) {
          *error = [NSString stringWithFormat:@"Failed to create folder at '%@'.", basePath];
          return NO;
        }
        exists = isDirectory = YES;
      }
    }
    
    if (![fileManager createFileAtPath:self.outputPath contents:nil attributes:nil]) {
      *error = [NSString stringWithFormat:@"Failed to create file at '%@'.", self.outputPath];
      return NO;
    }

    _outputHandle = [[NSFileHandle fileHandleForWritingAtPath:self.outputPath] retain];

    return YES;
  }
}

- (void)handleEvent:(NSDictionary *)eventDict
{
  NSAssert(([eventDict count] > 0), @"Event was empty.");

  NSString *event = eventDict[@"event"];
  NSAssert(event != nil && [event length] > 0, @"Event name was empty for event: %@", eventDict);

  NSMutableString *selectorName = [NSMutableString string];

  int i = 0;
  for (NSString *part in [event componentsSeparatedByString:@"-"]) {
    if (i++ == 0) {
      [selectorName appendString:[part lowercaseString]];
    } else {
      [selectorName appendString:[[part lowercaseString] capitalizedString]];
    }
  }
  [selectorName appendString:@":"];

  SEL sel = sel_registerName([selectorName UTF8String]);
  [self performSelector:sel withObject:eventDict];
}

- (void)beginAction:(NSDictionary *)event {}
- (void)endAction:(NSDictionary *)event {}
- (void)beginBuildTarget:(NSDictionary *)event {}
- (void)endBuildTarget:(NSDictionary *)event {}
- (void)beginBuildCommand:(NSDictionary *)event {}
- (void)endBuildCommand:(NSDictionary *)event {}
- (void)beginXcodebuild:(NSDictionary *)event {}
- (void)endXcodebuild:(NSDictionary *)event {}
- (void)beginOcunit:(NSDictionary *)event {}
- (void)endOcunit:(NSDictionary *)event {}
- (void)beginTestSuite:(NSDictionary *)event {}
- (void)endTestSuite:(NSDictionary *)event {}
- (void)beginTest:(NSDictionary *)event {}
- (void)endTest:(NSDictionary *)event {}
- (void)testOutput:(NSDictionary *)event {}
- (void)message:(NSDictionary *)event {}

- (void)close
{
  // Be sure everything gets flushed.
  struct stat fdstat = {0};
  NSAssert(fstat([_outputHandle fileDescriptor], &fdstat) == 0, @"fstat() failed: %s", strerror(errno));

  // Don't call synchronizeFile for pipes - it's not supported.  All of the automated
  // tests pass around pipes, so it's important to have this check.
  if (!S_ISFIFO(fdstat.st_mode)) {
    [_outputHandle synchronizeFile];
  }
}

@end
