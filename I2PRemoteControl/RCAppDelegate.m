//
//  RCAppDelegate.m
//  I2PRemoteControl
//
//  Created by miximka on 11/05/14.
//  Copyright (c) 2014 miximka. All rights reserved.
//

#import "RCAppDelegate.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "RCLogFormatter.h"
#import "RCRouter.h"
#import "RCRouterInfo.h"
#import "RCPreferencesWindowController.h"
#import "RCRouterManager.h"

//=========================================================================

#define TIME_INTERVAL_MINUTE    60
#define TIME_INTERVAL_HOUR      (TIME_INTERVAL_MINUTE * 60)
#define TIME_INTERVAL_DAY       (TIME_INTERVAL_HOUR * 24)
#define TIME_INTERVAL_HALF_YEAR (TIME_INTERVAL_DAY * 182)
#define TIME_INTERVAL_YEAR      (TIME_INTERVAL_DAY * 365)

//Should correspond to the statusBarMenu tags in MainMenu.xib
typedef NS_ENUM(NSUInteger, RCMenuItemTag)
{
    kRouterVersionMenuTag   = 0,
    kRouterUptimeMenuTag    = 1,
    kRouterStatusMenuTag    = 2,
};

@interface RCAppDelegate ()
@property (nonatomic) NSStatusItem *statusBarItem;
@property (nonatomic) NSTimer *updateUITimer;
@property (nonatomic) RCRouterManager *routerManager;
@property (nonatomic) RCRouter *currentRouter;
@property (nonatomic) RCPreferencesWindowController *prefsWindowController;
@end

//=========================================================================
@implementation RCAppDelegate
//=========================================================================

- (void)dealloc
{
    [self unregisterForNotifications];
}

//=========================================================================

- (void)setUpdateUITimer:(NSTimer *)updateUITimer
{
    if (_updateUITimer != nil)
    {
        [_updateUITimer invalidate];
    }

    _updateUITimer = updateUITimer;
}

//=========================================================================

- (BOOL)isRunningUnitTests
{
	return NSClassFromString(@"XCTestRun") != nil;
}

//=========================================================================

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(routerDidUpdateRouterInfo:)
                                                 name:RCRouterDidUpdateRouterInfoNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managerDidSetRouter:)
                                                 name:RCManagerDidSetRouterNotification
                                               object:nil];
}

//=========================================================================

- (void)unregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//=========================================================================

- (void)initializeLogging
{
    RCLogFormatter *logFormatter = [[RCLogFormatter alloc] init];
    
    [[DDASLLogger sharedInstance] setLogFormatter:logFormatter];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    
    [[DDTTYLogger sharedInstance] setLogFormatter:logFormatter];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; //24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [fileLogger setLogFormatter:logFormatter];
    [DDLog addLogger:fileLogger];
    
    //Log application version
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    DDLogInfo(@"===");
    DDLogInfo(@"App version: %@ (%@)", [infoDict objectForKey:@"CFBundleShortVersionString"], [infoDict objectForKey:@"CFBundleVersion"]);
}

//=========================================================================

- (void)addStatusBarItem
{
    //Create status bar item
	NSStatusItem *item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *image = [NSImage imageNamed:@"StatusBarIcon_Inactive"];
    [item setImage:image];
    [item setHighlightMode:YES];
    [item setMenu:self.statusBarMenu];
    
    self.statusBarItem = item;
}

//=========================================================================

- (void)menuItem:(NSMenuItem *)menuItem setTitleWithFormat:(NSString *)format value:(id)value
{
    if (value == nil)
        value = @"-";
    
    NSString *title = [NSString stringWithFormat:format, value];
    [menuItem setTitle:title];
}

//=========================================================================

- (NSString *)uptimeStringForInterval:(NSTimeInterval)interval
{
    NSString *str = @"";

	if (interval < TIME_INTERVAL_MINUTE)
	{
        int secs = interval;
        str = [NSString stringWithFormat:@"%i %@", secs, MyLocalStr(@"kSecondsShortAbbr")];
	}
	else if (interval >= TIME_INTERVAL_MINUTE && interval < TIME_INTERVAL_HOUR)
	{
        int mins = interval / TIME_INTERVAL_MINUTE;
        str = [NSString stringWithFormat:@"%i %@", mins, MyLocalStr(@"kMinutesShortAbbr")];
	}
	else if (interval >= TIME_INTERVAL_HOUR && interval < TIME_INTERVAL_DAY)
	{
        int hours = interval / TIME_INTERVAL_HOUR;
        str = [NSString stringWithFormat:@"%i %@", hours, MyLocalStr(@"kHoursShortAbbr")];
	}
	else
	{
        int days = interval / TIME_INTERVAL_DAY;
        str = [NSString stringWithFormat:@"%i %@", days, MyLocalStr(@"kDaysShortAbbr")];
	}
    
	return str;
}

//=========================================================================

- (void)updateStatusBarIcon
{
    NSString *imageName = @"StatusBarIcon_Inactive";
    if ([self.currentRouter active])
    {
        imageName = @"StatusBarIcon";
    }
    
    NSImage *image = [NSImage imageNamed:imageName];
    
    if (self.statusBarItem.image != image)
    {
        //Update image
        self.statusBarItem.image = image;
    }
}

//=========================================================================

- (void)updateGUI
{
    //Update status bar icon
    [self updateStatusBarIcon];
    
    //Update router version
    NSMenuItem *item = [self.statusBarItem.menu itemWithTag:kRouterVersionMenuTag];
    NSString *strValue = self.currentRouter.routerInfo.routerVersion;
    [self menuItem:item setTitleWithFormat:MyLocalStr(@"VersionTitle") value:strValue];
    
    //Update router uptime
    item = [self.statusBarItem.menu itemWithTag:kRouterUptimeMenuTag];
    NSTimeInterval uptime = self.currentRouter.routerInfo.estimatedRouterUptime;
    
    strValue = nil;
    if (uptime > 0)
    {
        strValue = [self uptimeStringForInterval:uptime];
    }
    [self menuItem:item setTitleWithFormat:MyLocalStr(@"UptimeTitle") value:strValue];

    //Update router status
    item = [self.statusBarItem.menu itemWithTag:kRouterStatusMenuTag];
    strValue = self.currentRouter.routerInfo.routerStatus;
    [self menuItem:item setTitleWithFormat:MyLocalStr(@"StatusTitle") value:strValue];
}

//=========================================================================

- (IBAction)shutdown:(id)sender
{
    DDLogInfo(@"Shutdown");
}

//=========================================================================

- (IBAction)restart:(id)sender
{
    DDLogInfo(@"Restart");
}

//=========================================================================

- (IBAction)openPreferences:(id)sender
{
	if (!self.prefsWindowController)
	{
		RCPreferencesWindowController *ctrl = [[RCPreferencesWindowController alloc] initWithWindowNibName:@"Preferences"];
        [ctrl setRouterManager:self.routerManager];
        self.prefsWindowController = ctrl;
	}
	
	[self.prefsWindowController showWindow:self];
}

//=========================================================================

- (IBAction)quit:(id)sender
{
    [NSApp terminate:self];
}

//=========================================================================
#pragma mark NSApplicationDelegate
//=========================================================================

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([self isRunningUnitTests])
        return;
    
    [self initializeLogging];
    
    [self addStatusBarItem];
    [self registerForNotifications];
    
    //Initialize router manager
    RCRouterManager *routerManager = [[RCRouterManager alloc] init];
    self.routerManager = routerManager;
    
    //Obtain router instance immediately
    self.currentRouter = self.routerManager.router;
    [self updateGUI];
    
    //Add login item if required but missing
//    [self addLoginItemIfNeeded];
}

//=========================================================================
#pragma mark NSMenuDelegate
//=========================================================================

- (void)menuWillOpen:(NSMenu *)menu
{
    if (menu != self.statusBarMenu)
        return;
    
    self.updateUITimer = [NSTimer timerWithTimeInterval:1.0
                                                 target:self
                                               selector:@selector(updateTimerFired:)
                                               userInfo:nil
                                                repeats:YES];
    
    //Add timer manually with NSRunLoopCommonModes to update UI even when menu is opened
    [[NSRunLoop currentRunLoop] addTimer:self.updateUITimer
                                 forMode:NSRunLoopCommonModes];
    
    //Trigger router info update immediately
    [self.currentRouter updateRouterInfo];
}

//=========================================================================

- (void)menuDidClose:(NSMenu *)menu
{
    if (menu != self.statusBarMenu)
        return;
    
    //Stop updating UI
    self.updateUITimer = nil;
}

//=========================================================================

- (void)updateTimerFired:(NSTimer *)timer
{
    [self updateGUI];
}

//=========================================================================
#pragma mark Notifications
//=========================================================================

- (void)routerDidUpdateRouterInfo:(NSNotification *)notification
{
    [self updateGUI];
}

//=========================================================================

- (void)managerDidSetRouter:(NSNotification *)notification
{
    //Update current router instance
    self.currentRouter = self.routerManager.router;
    [self updateGUI];
}

//=========================================================================
@end
//=========================================================================

