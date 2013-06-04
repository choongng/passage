//
//  PAppDelegate.m
//  Passage
//
//  Created by Choong Ng on 6/2/13.
//  Copyright (c) 2013 Choong Ng. All rights reserved.
//

#import "PAppDelegate.h"

@implementation PAppDelegate

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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Hide dock icon
    [self hideDockIcon];
    
    // Place movie window over desktop
    [self.window setLevel:kCGDesktopWindowLevel];
    [self.window setStyleMask:0];
    self.window.canHide = NO;
    
    // Load the movie
    NSRect frame = self.window.screen.frame;
    [self.window setFrame:frame display:YES];
    self.movieView.frame = frame;
    self.movieView.movie = [QTMovie movieWithFile:@"/Users/choong/Desktop/24 hours in Tokyo on July, 24th 2010 - Japan time lapse.mp4"
                                            error:NULL];
    self.movieView.preservesAspectRatio = YES;
    self.movieView.movie.muted = YES;

    [self.movieView.movie setCurrentTime:[self getCurrentPlaybackTime]];
    
    // Schedule periodic callback so we can advance the movie
    self.frameAdvanceTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                     target:self
                                   selector:@selector(advanceFrame)
                                   userInfo:nil
                                    repeats:YES];
    
    //
    NSBundle *bundle = [NSBundle mainBundle];
    NSImage *statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"smiley"]];
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [self.statusItem setImage:statusImage];
    [self.statusItem setMenu:self.statusMenu];
    
}

- (void)hideDockIcon
{
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToBackgroundApplication);
}

- (void)advanceFrame
{
    // The implementation inside QT seems to be efficient when seeking to the
    // same frame repeatedly.
    self.movieView.movie.currentTime = [self getCurrentPlaybackTime];
}

- (IBAction)selectMovieFile:(id)sender {
    NSLog(@"hi");
}

@end
