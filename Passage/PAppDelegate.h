//
//  PAppDelegate.h
//  Passage
//
//  Created by Choong Ng on 6/2/13.
//  Copyright (c) 2013 Choong Ng. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>


@class AVPlayer, AVPlayerLayer;

@interface PAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSOpenSavePanelDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *movieView;
@property AVPlayerLayer *playerLayer;
@property (weak) IBOutlet NSMenu *statusMenu;
@property NSTimer *frameAdvanceTimer;
@property NSStatusItem *statusItem;
@property NSArray *aboutWindowObjects;
@property NSWindow *aboutWindow;
@property AVPlayer *moviePlayer;

- (void)advanceFrame;
- (IBAction)showAboutDialog:(id)sender;
- (IBAction)selectMovieFile:(id)sender;

@end
