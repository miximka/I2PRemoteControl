//
//  RCStatusBarView.m
//  I2PRemoteControl
//
//  Created by miximka on 16/05/14.
//  Copyright (c) 2014 miximka. All rights reserved.
//

#import "RCStatusBarView.h"

//=========================================================================

@interface RCStatusBarView ()
@end

//=========================================================================
@implementation RCStatusBarView
//=========================================================================

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
		[self setImageAlignment:NSImageAlignCenter];
		[self setImageScaling:NSImageScaleProportionallyDown];
		[self setImageFrameStyle:NSImageFrameNone];

        [self setIconType:RCIconTypeInactive];
    }
    return self;
}

//=========================================================================

- (void)setHighlighted:(BOOL)highlighted
{
    if (_highlighted != highlighted)
    {
        _highlighted = highlighted;
        [self setNeedsDisplay];
    }
}

//=========================================================================

- (void)setIconType:(RCStatusBarIconType)iconType
{
    if (_iconType != iconType)
    {
        _iconType = iconType;
        [self setIconForIconType:iconType];
    }
}

//=========================================================================

- (void)setIconForIconType:(RCStatusBarIconType)iconType
{
    NSString *imageName = @"StatusBarIcon_Inactive";
    if (iconType == RCIconTypeActive)
    {
        imageName = @"StatusBarIcon";
    }
    
    NSImage *image = [NSImage imageNamed:imageName];
    [self setImage:image];
}

//=========================================================================
#pragma mark Overriden methods
//=========================================================================

- (void)drawRect:(NSRect)dirtyRect
{
	//Draw background (probably highlighted)
	[self.statusItem drawStatusBarBackgroundInRect:dirtyRect withHighlight:self.isHighlighted];
	
	//Draw image
	[super drawRect:dirtyRect];
}

//=========================================================================

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    [self.statusItem popUpStatusItemMenu:self.statusItem.menu];
}

//=========================================================================

- (void)rightMouseDown:(NSEvent *)theEvent
{
    [super rightMouseDown:theEvent];
    [self.statusItem popUpStatusItemMenu:self.statusItem.menu];
}

//=========================================================================
@end
//=========================================================================