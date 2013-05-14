//
//  BuildOutputReporter.h
//  xctool
//
//  Created by Emil Palm on 5/14/13.
//  Copyright (c) 2013 Fred Potter. All rights reserved.
//

#import "Reporter.h"

@interface JSONReporter : Reporter<ExportedReporter>
@property(nonatomic, strong) NSMutableArray *root;
@end
