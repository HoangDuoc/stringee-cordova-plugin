#import <Cordova/CDV.h>
#import <Stringee/Stringee.h>

@interface StringeePlugin : CDVPlugin <StringeeConnectionDelegate, StringeeIncomingCallDelegate>

// Common
- (void)addEvent:(CDVInvokedUrlCommand *)command;

// Client
- (void)initClient:(CDVInvokedUrlCommand *)command;
- (void)connect:(CDVInvokedUrlCommand *)command;

// Call

@end