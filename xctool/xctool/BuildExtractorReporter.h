//
//  BuildExtractorReporter.h
//  xctool
//
//  Created by Emil Palm on 5/14/13.
//  Copyright (c) 2013 Fred Potter. All rights reserved.
//

#import "JSONReporter.h"

@interface BuildExtractorReporter : JSONReporter<ExportedReporter>
@property(nonatomic,retain) NSMutableDictionary *build;
@property(nonatomic,retain) NSDictionary *rootObject;
@end
