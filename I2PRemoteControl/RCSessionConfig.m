//
//  RCSessionConfig.m
//  I2PRemoteControl
//
//  Created by miximka on 12/05/14.
//  Copyright (c) 2014 miximka. All rights reserved.
//

#import "RCSessionConfig.h"

#define DEFAULT_WEBUI_CONSOLE_PORT 7657

//=========================================================================
@implementation RCSessionConfig
//=========================================================================

- (instancetype)initWithHost:(NSString *)host port:(NSUInteger)port
{
    self = [super init];
    if (self)
    {
        _host = host;
        _port = port;
        _consolePort = DEFAULT_WEBUI_CONSOLE_PORT;
    }
    return self;
}

//=========================================================================
@end
//=========================================================================
