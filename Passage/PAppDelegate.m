//
//  PAppDelegate.m
//  Passage
//
//  Created by Choong Ng on 6/2/13.
//  Copyright (c) 2013 Choong Ng. All rights reserved.
//

#import "PAppDelegate.h"

@implementation PAppDelegate

- (id)init
{
    self = [super init];
    return self;
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Hide dock icon
    [self hideDockIcon];
    
    // Place movie window over desktop, under icons, and in all spaces
    {
        NSWindow *w = self.window;
        w.level = kCGDesktopWindowLevel;
        w.styleMask = 0;
        w.canHide = NO;
        w.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    }

    // Set up movie area
    [self resizePlaybackArea];
    
    // Schedule periodic callback so we can advance the movie
    self.frameAdvanceTimer = [NSTimer
                              scheduledTimerWithTimeInterval:10
                              target:self
                              selector:@selector(advanceFrame)
                              userInfo:nil
                              repeats:YES];
    
    // Add status item
    {
        NSImage *statusImage = [PAppDelegate imageForResourceName:@"status-icon"];
        NSImage *statusImageHighlight = [PAppDelegate imageForResourceName:@"status-icon-highlight"];
        NSStatusItem *si = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        si.image = statusImage;
        si.alternateImage = statusImageHighlight;
        si.highlightMode = YES;
        si.menu = self.statusMenu;
        self.statusItem = si;
    }
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
    // set window to screen size
    NSRect frame = self.window.screen.frame;
    [self.window setFrame:frame display:YES];

    if (self.movieView.movie != nil) {
        // get underlying movie size
        NSSize movieSize;
        [[self.movieView.movie attributeForKey:QTMovieNaturalSizeAttribute] getValue:&movieSize];
        
        // get screen size
        NSRect screenFrame = self.window.screen.frame;
        
        // find smallest dimension of movie wrt screen
        float heightRatio = 1.0f * movieSize.height / screenFrame.size.height;
        float widthRatio = 1.0f * movieSize.width / screenFrame.size.width;
        
        // calculate scaled movie size
        int scaledWidth, scaledHeight, scaledOffsetX, scaledOffsetY;
        if (heightRatio > widthRatio) {
            scaledWidth = screenFrame.size.width;
            scaledHeight = 1.0f * scaledWidth / movieSize.width * movieSize.height;
        } else {
            scaledHeight = screenFrame.size.height;
            scaledWidth = 1.0f * scaledHeight / movieSize.height * movieSize.width;
        }
        
        scaledOffsetX = (scaledWidth - screenFrame.size.width) / 2;
        scaledOffsetY = (scaledHeight - screenFrame.size.height) / 2;
        
        // place view within window to crop horiz or vert
        NSRect movieFrame = {
            -scaledOffsetX,
            -scaledOffsetY,
            scaledWidth,
            scaledHeight
        };
        NSLog(@"%f, %f, %f, %f", movieFrame.origin.x, movieFrame.origin.y, movieFrame.size.width, movieFrame.size.height);
        self.movieView.frame = movieFrame;
    } else {
        self.movieView.frame = frame;
    }
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
    [self resizePlaybackArea];
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

#pragma mark - helpers

+ (NSImage *)imageForResourceName:(NSString *)resourceName
{
    NSBundle *bundle = [NSBundle mainBundle];
    return [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:resourceName]];
}

@end
