//
//  PAppDelegate.h
//  Passage
//
//  Created by Choong Ng on 6/2/13.
//  Copyright (c) 2013 Choong Ng. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface PAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet QTMovieView *movieView;
@property (weak) IBOutlet NSMenu *statusMenu;
@property NSTimer *frameAdvanceTimer;
@property NSStatusItem *statusItem;

- (void)advanceFrame;
- (IBAction)selectMovieFile:(id)sender;

@end
