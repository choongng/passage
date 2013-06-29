//
//  PAboutWindow.m
//  Passage
//
//  Created by Choong Ng on 6/28/13.
//  Copyright (c) 2013 Choong Ng. All rights reserved.
//

#import "PAboutWindow.h"

@implementation PAboutWindow

- (void)close
{
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToBackgroundApplication);

    [super close];
}

@end
