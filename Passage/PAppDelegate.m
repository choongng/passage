//
//  PAppDelegate.m
//  Passage
//
//  Created by Choong Ng on 6/2/13.
//  Copyright (c) 2013 Choong Ng. All rights reserved.
//

#import "PAppDelegate.h"

@implementation PAppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Hide dock icon
    [self hideDockIcon];
    
    // Place movie window over desktop, under icons, and in all spaces
    [self.window setLevel:kCGDesktopWindowLevel];
    [self.window setStyleMask:0];
    self.window.canHide = NO;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    
    // Set up movie area
    [self resizePlaybackArea];
    
    // Schedule periodic callback so we can advance the movie
    self.frameAdvanceTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                     target:self
                                   selector:@selector(advanceFrame)
                                   userInfo:nil
                                    repeats:YES];
    
    // Add status item
    NSBundle *bundle = [NSBundle mainBundle];
    NSImage *statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"smiley"]];
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.image = statusImage;
    self.statusItem.highlightMode = YES;
    [self.statusItem setMenu:self.statusMenu];
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)notification
{
    [self resizePlaybackArea];
}

#pragma mark - NSWindowDelegate

- (void)windowDidResize:(NSNotification *)notification
{
    [self resizePlaybackArea];
}

#pragma mark - window management

- (void)resizePlaybackArea
{
    NSRect frame = self.window.screen.frame;
    [self.window setFrame:frame display:YES];
    self.movieView.frame = frame;
}

- (void)hideDockIcon
{
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToBackgroundApplication);
}


#pragma mark - movie management

- (void)loadMovie:(NSURL *)movieURL
{
    self.movieView.movie = [QTMovie movieWithURL:movieURL error:NULL];
    self.movieView.preservesAspectRatio = YES;
    self.movieView.movie.muted = YES;
    [self.movieView.movie setCurrentTime:[self getCurrentPlaybackTime]];
}

- (IBAction)selectMovieFile:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.delegate = self;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (openPanel.URL != nil) {
            NSLog(@"%@", openPanel.URL);
            [self loadMovie:openPanel.URL];
        }
    }];
    [openPanel setLevel:kCGPopUpMenuWindowLevel];
    [openPanel makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (QTTime)getCurrentPlaybackTime
{
    // Get progress through the day
    NSDate *now = [NSDate date];
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar]
                                        components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                        fromDate:now];
    NSDate *beginningOfDay = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
    NSTimeInterval dayElapsedInterval = [now timeIntervalSinceDate:beginningOfDay];
    float dayElapsed = dayElapsedInterval / (24 * 60 * 60);
    
    // Set progress through the movie
    QTTime startTime = self.movieView.movie.duration;
    startTime.timeValue = startTime.timeValue * dayElapsed;
    return startTime;
}

- (void)advanceFrame
{
    // The implementation inside QT seems to be efficient when seeking to the
    // same frame repeatedly.
    self.movieView.movie.currentTime = [self getCurrentPlaybackTime];
}


@end
