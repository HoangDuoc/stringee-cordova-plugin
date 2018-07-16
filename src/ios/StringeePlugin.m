#import "StringeePlugin.h"

// Events
static NSString *clientEvents = @"clientEvents";
static NSString *callEvents = @"callEvents";

// Client
static NSString *didConnect               = @"didConnect";
static NSString *didDisConnect            = @"didDisConnect";
static NSString *didFailWithError         = @"didFailWithError";
static NSString *requestAccessToken       = @"requestAccessToken";

static NSString *incomingCall               = @"incomingCall";

// Call
static NSString *didChangeSignalingState    = @"didChangeSignalingState";
static NSString *didChangeMediaState        = @"didChangeMediaState";
static NSString *didReceiveLocalStream      = @"didReceiveLocalStream";
static NSString *didReceiveRemoteStream     = @"didReceiveRemoteStream";
static NSString *didReceiveDtmfDigit        = @"didReceiveDtmfDigit";
static NSString *didReceiveCallInfo         = @"didReceiveCallInfo";
static NSString *didHandleOnAnotherDevice   = @"didHandleOnAnotherDevice";

@implementation StringeePlugin {
    StringeeClient *_client;
    NSMutableDictionary *callbackList;
    NSMutableDictionary *callList;
}

#pragma mark Common

-(void) pluginInitialize{
    // Make the web view transparent.
    [self.webView setOpaque:false];
    [self.webView setBackgroundColor:UIColor.clearColor];

    callbackList = [[NSMutableDictionary alloc] init];
    callList = [[NSMutableDictionary alloc] init];
}

- (void)addEvent:(CDVInvokedUrlCommand*)command {
    NSString* event = [command.arguments objectAtIndex:0];
    [callbackList setObject:command.callbackId forKey:event];
}

#pragma mark Client

- (void)initClient:(CDVInvokedUrlCommand *)command {
    // Khởi tạo client nếu chưa có
    if (!_client) {
        _client = [[StringeeClient alloc] initWithConnectionDelegate:self];
        _client.incomingCallDelegate = self;
    }
}

- (void)connect:(CDVInvokedUrlCommand*)command {
    NSString *token = [[command arguments] objectAtIndex:0];
    [_client connectWithAccessToken:token];
}

#pragma mark Connection Delegate

- (void)didConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didConnect %@", stringeeClient.userId);

    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeClient.userId forKey:@"userId"];
    [eventData setObject:stringeeClient.projectId forKey:@"projectId"];
    [eventData setObject:@(isReconnecting) forKey:@"isReconnecting"];

    [self triggerJSEvent: clientEvents withType: didConnect withData: eventData];
}

- (void)didDisConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didDisConnect");

    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeClient.userId forKey:@"userId"];
    [eventData setObject:stringeeClient.projectId forKey:@"projectId"];
    [eventData setObject:@(isReconnecting) forKey:@"isReconnecting"];

    [self triggerJSEvent: clientEvents withType: didDisConnect withData: eventData];
}

- (void)didFailWithError:(StringeeClient *)stringeeClient code:(int)code message:(NSString *)message {
    NSLog(@"didFailWithError - %@", message);

    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeClient.userId forKey:@"userId"];
    [eventData setObject:@(code) forKey:@"code"];
    [eventData setObject:message forKey:@"message"];

    [self triggerJSEvent: clientEvents withType: didFailWithError withData: eventData];
}

- (void)requestAccessToken:(StringeeClient *)stringeeClient {
    NSLog(@"requestAccessToken");

    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeClient.userId forKey:@"userId"];

    [self triggerJSEvent: clientEvents withType: requestAccessToken withData: eventData];
}

#pragma mark Helper

- (void)triggerJSEvent:(NSString*)event withType:(NSString*)type withData:(id) data{
    NSMutableDictionary* message = [[NSMutableDictionary alloc] init];
    [message setObject:type forKey:@"eventType"];
    if (data) {
        [message setObject:data forKey:@"data"];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
    [pluginResult setKeepCallbackAsBool:YES];

    NSString* callbackId = [callbackList objectForKey:event];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)incomingCallWithStringeeClient:(StringeeClient *)stringeeClient stringeeCall:(StringeeCall *)stringeeCall {
    [callList setObject:stringeeCall forKey:stringeeCall.callId];

    int index = 0;

    if (stringeeCall.callType == CallTypeCallIn) {
        // Phone-to-app
        index = 3;
    } else if (stringeeCall.callType == CallTypeCallOut) {
        // App-to-phone
        index = 2;
    } else if (stringeeCall.callType == CallTypeInternalIncomingCall) {
        // App-to-app-incoming-call
        index = 1;
    } else {
        // App-to-app-outgoing-call
        index = 0;
    }

    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeClient.userId forKey:@"userId"];
    [eventData setObject:stringeeCall.callId forKey:@"callId"];
    [eventData setObject:stringeeCall.from forKey:@"from"];
    [eventData setObject:stringeeCall.to forKey:@"to"];
    [eventData setObject:stringeeCall.fromAlias forKey:@"fromAlias"];
    [eventData setObject:stringeeCall.toAlias forKey:@"toAlias"];
    [eventData setObject:@(index) forKey:@"callType"];
    [eventData setObject:@(stringeeCall.isVideoCall) forKey:@"isVideoCall"];
    [eventData setObject:stringeeCall.customDataFromYourServer forKey:@"customDataFromYourServer"];

    [self triggerJSEvent: clientEvents withType: incomingCall withData: eventData];    
}


@end
