//
//  PAppDelegate.m
//  Passage
//
//  Created by Choong Ng on 6/2/13.
//  Copyright (c) 2013 Choong Ng. All rights reserved.
//

#import "PAppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

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
    
    if (self.moviePlayer.rate != 0 && self.moviePlayer.error == nil) {
        // set playerLayer frame to match movieView
        [self.playerLayer setFrame:self.movieView.bounds];
        [self.movieView.layer addSublayer:self.playerLayer];
        
        // get underlying movie size
        AVAssetTrack *track = [[self.moviePlayer.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        NSSize movieSize;
        if (track != nil)
        {
            movieSize = [track naturalSize];
            movieSize = CGSizeApplyAffineTransform(movieSize, track.preferredTransform);
        }
        
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
    
    // required to have view accept a new layer
    [self.movieView setWantsLayer:YES];
    // create a layer, add it to movieView
    AVPlayerLayer *newPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.moviePlayer];
    newPlayerLayer.frame = self.movieView.layer.bounds;
    newPlayerLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    [self.movieView.layer addSublayer:newPlayerLayer];
    self.playerLayer = newPlayerLayer;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.moviePlayer];
}

- (void)hideDockIcon
{
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToBackgroundApplication);
}

- (IBAction)showAboutDialog:(id)sender
{
    //show about window
    NSArray *aboutWindowObjects = NULL;
    [[NSBundle mainBundle] loadNibNamed:@"AboutWindow"
                                  owner:self
                        topLevelObjects:&aboutWindowObjects];
    self.aboutWindowObjects = aboutWindowObjects;
    
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    
    for (int i=0; i<self.aboutWindowObjects.count; i++) {
        NSWindow *wind = (NSWindow *)(self.aboutWindowObjects[i]);
        if ([wind.title isEqualToString:@"About Passage"])
            [wind setLevel:kCGPopUpMenuWindowLevel];
        [wind makeKeyAndOrderFront:self];
    }
    
    [NSApp activateIgnoringOtherApps:YES];
}

#pragma mark - movie management

- (void)loadMovie:(NSURL *)movieURL
{
    
    if (self.moviePlayer.rate>0 && !self.moviePlayer.error)
    {
        // already have a player
        [self.moviePlayer setRate:0.0];
        AVPlayerItem *moviePlayerItem = [AVPlayerItem playerItemWithURL:movieURL];
        [self.moviePlayer replaceCurrentItemWithPlayerItem:moviePlayerItem];
        // dereference old playerLayer or else memory leak?
        //self.playerLayer = nil;
    } else {
        // no player already
        self.moviePlayer = [AVPlayer playerWithURL:movieURL];
    }
    
    // set video to correct frame
    [self.moviePlayer seekToTime:[self getCurrentPlaybackTime]];
    
    [self resizePlaybackArea];
}

- (IBAction)selectMovieFile:(id)sender {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.delegate = self;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (openPanel.URL != nil) {
            NSLog(@"%@", openPanel.URL);
            [self loadMovie:openPanel.URL];
        }
        TransformProcessType(&psn, kProcessTransformToBackgroundApplication);
    }];
    [openPanel setLevel:kCGPopUpMenuWindowLevel];
    [openPanel makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}


- (CMTime)getCurrentPlaybackTime
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
    CMTime startTime = self.moviePlayer.currentItem.asset.duration;
    NSLog(@"Duration:%lld", startTime.value);
    NSLog(@"dayElapsed:%f", dayElapsed);
    startTime = CMTimeMultiplyByFloat64(startTime, dayElapsed);
    NSLog(@"%lld - StartTIME", startTime.value);
    
    return startTime;
}

- (void)advanceFrame
{
    // The implementation inside QT seems to be efficient when seeking to the
    // same frame repeatedly.
    //TODO: Check that it's okay for AVPlayer as well....
    [self.moviePlayer seekToTime:[self getCurrentPlaybackTime]];
}

#pragma mark - helpers

+ (NSImage *)imageForResourceName:(NSString *)resourceName
{
    NSBundle *bundle = [NSBundle mainBundle];
    return [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:resourceName]];
}

@end
