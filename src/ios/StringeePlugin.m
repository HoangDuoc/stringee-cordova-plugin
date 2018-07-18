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

#pragma mark StringeeClient

- (void)initStringeeClient:(CDVInvokedUrlCommand *)command {
    // Khởi tạo client nếu chưa có
    NSLog(@"initClient");
    if (!_client) {
        _client = [[StringeeClient alloc] initWithConnectionDelegate:self];
        _client.incomingCallDelegate = self;
    }
}

- (void)connect:(CDVInvokedUrlCommand*)command {
    NSLog(@"connect");
    NSString *token = [[command arguments] objectAtIndex:0];
    [_client connectWithAccessToken:token];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command {
    NSLog(@"disconnect");
    if (_client) {
        [_client disconnect];
    }
}

- (void)registerPush:(CDVInvokedUrlCommand*)command {
    NSLog(@"registerPush");

    if (!_client || !_client.hasConnected) {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"StringeeClient is not initialized or connected." forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
        return;
    }

    NSString *deviceToken = [[command arguments] objectAtIndex:0];
    NSNumber *isProduction = [[command arguments] objectAtIndex:1];
    NSNumber *isVoip = [[command arguments] objectAtIndex:2];

    [_client registerPushForDeviceToken:deviceToken isProduction:[isProduction boolValue] isVoip:[isVoip boolValue] completionHandler:^(BOOL status, int code, NSString *message) {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:message forKey:@"message"];
        [self triggerCallbackWithStatus:status withData:eventData withCallbackId:command.callbackId];
    }];
}

- (void)unregisterPush:(CDVInvokedUrlCommand*)command {
    NSLog(@"unregisterPush");

    if (!_client || !_client.hasConnected) {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"StringeeClient is not initialized or connected." forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
        return;
    }

    NSString *deviceToken = [[command arguments] objectAtIndex:0];

    [_client unregisterPushForDeviceToken:deviceToken completionHandler:^(BOOL status, int code, NSString *message) {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:message forKey:@"message"];
        [self triggerCallbackWithStatus:status withData:eventData withCallbackId:command.callbackId];
    }];
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

#pragma mark IncomingCall Delegate

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

#pragma mark StringeeCall

- (void)initStringeeCall:(CDVInvokedUrlCommand *)command {
    NSLog(@"initStringeeCall");

    NSString *iden = [[command arguments] objectAtIndex:0];
    NSString *from = [[command arguments] objectAtIndex:1];
    NSString *to = [[command arguments] objectAtIndex:2];
    NSNumber *isVideoCall = [[command arguments] objectAtIndex:3];
    NSString *videoResolution = [[command arguments] objectAtIndex:4];
    NSString *customData = [[command arguments] objectAtIndex:5];

    StringeeCall *outgoingCall = [[StringeeCall alloc] initWithStringeeClient:_client from:from to:to];
    outgoingCall.delegate = self;
    outgoingCall.isVideoCall = [isVideoCall boolValue];

    if (customData.length) {
        outgoingCall.customData = customData;
    }

    if ([videoResolution isEqualToString:@"HD"]) {
        outgoingCall.videoResolution = VideoResolution_HD;
    }

    [callList setObject:outgoingCall forKey:iden];
}

- (void)makeCall:(CDVInvokedUrlCommand *)command {
    NSLog(@"makeCall");
    NSString *iden = [[command arguments] objectAtIndex:0];
    // [callbackList setObject:command.callbackId forKey:iden];

    StringeeCall *outgoingCall = [callList objectForKey:iden];
    if (outgoingCall) {
        [outgoingCall makeCallWithCompletionHandler:^(BOOL status, int code, NSString *message, NSString *data) {
            NSLog(@"%@", message);
            NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
            [eventData setObject:message forKey:@"message"];
            [eventData setObject:data forKey:@"customDataFromYourServer"];
            [self triggerCallbackWithStatus:status withData:eventData withCallbackId:command.callbackId];
            if (!status) {
                [callbackList removeObjectForKey:iden];
            }
        }];
    } else {
        [callbackList removeObjectForKey:iden];

        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Make call failed. The call is not found." forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)initAnswer:(CDVInvokedUrlCommand *)command {
    NSLog(@"initAnswer");
    NSString *iden = [[command arguments] objectAtIndex:0];
    // [callbackList setObject:command.callbackId forKey:iden];
 
    StringeeCall *incomingCall = [callList objectForKey:iden];

    if (incomingCall) {
        incomingCall.delegate = self;
        [incomingCall initAnswerCall];

        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Init answer call successful" forKey:@"message"];
        [self triggerCallbackWithStatus:true withData:eventData withCallbackId:command.callbackId];
    } else {
        // Khong tim duoc cuoc goi thi xoa luon callbackId
        [callbackList removeObjectForKey:iden];
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Init answer call failed. The call is not found." forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)answer:(CDVInvokedUrlCommand *)command {
    NSLog(@"answer");
    NSString *iden = [[command arguments] objectAtIndex:0];
 
    StringeeCall *incomingCall = [callList objectForKey:iden];

    if (incomingCall) {
        [incomingCall answerCallWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"%@", message);
            NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
            [eventData setObject:message forKey:@"message"];
            [self triggerCallbackWithStatus:status withData:eventData withCallbackId:command.callbackId];
        }];
    } else {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Answer call failed. The call is not found." forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)hangup:(CDVInvokedUrlCommand *)command {
    NSLog(@"hangup");
    NSString *iden = [[command arguments] objectAtIndex:0];
 
    StringeeCall *call = [callList objectForKey:iden];

    if (call) {
        [call hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"%@", message);
            NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
            [eventData setObject:message forKey:@"message"];
            [self triggerCallbackWithStatus:status withData:eventData withCallbackId:command.callbackId];
        }];
    } else {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Hangup call failed. The call is not found." forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)reject:(CDVInvokedUrlCommand *)command {
    NSLog(@"reject");
    NSString *iden = [[command arguments] objectAtIndex:0];
 
    StringeeCall *call = [callList objectForKey:iden];

    if (call) {
        [call rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"%@", message);
            NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
            [eventData setObject:message forKey:@"message"];
            [self triggerCallbackWithStatus:status withData:eventData withCallbackId:command.callbackId];
        }];
    } else {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Reject call failed. The call is not found." forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)sendDTMF:(CDVInvokedUrlCommand *)command {
    NSLog(@"sendDTMF");
    NSString *iden = [[command arguments] objectAtIndex:0];
    NSString *dtmf = [[command arguments] objectAtIndex:1];

    StringeeCall *call = [callList objectForKey:iden];

    if (call) {
            NSArray *DTMF = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"*", @"#"];
            if ([DTMF containsObject:dtmf]) {

                CallDTMF dtmfParam;
        
                if ([dtmf isEqualToString:@"0"]) {
                    dtmfParam = CallDTMFZero;
                }
                else if ([dtmf isEqualToString:@"1"]) {
                    dtmfParam = CallDTMFOne;
                }
                else if ([dtmf isEqualToString:@"2"]) {
                    dtmfParam = CallDTMFTwo;
                }
                else if ([dtmf isEqualToString:@"3"]) {
                    dtmfParam = CallDTMFThree;
                }
                else if ([dtmf isEqualToString:@"4"]) {
                    dtmfParam = CallDTMFFour;
                }
                else if ([dtmf isEqualToString:@"5"]) {
                    dtmfParam = CallDTMFFive;
                }
                else if ([dtmf isEqualToString:@"6"]) {
                    dtmfParam = CallDTMFSix;
                }
                else if ([dtmf isEqualToString:@"7"]) {
                    dtmfParam = CallDTMFSeven;
                }
                else if ([dtmf isEqualToString:@"8"]) {
                    dtmfParam = CallDTMFEight;
                }
                else if ([dtmf isEqualToString:@"9"]) {
                    dtmfParam = CallDTMFNine;
                }
                else if ([dtmf isEqualToString:@"*"]) {
                    dtmfParam = CallDTMFStar;
                }
                else {
                    dtmfParam = CallDTMFPound;
                }

                [call sendDTMF:dtmfParam completionHandler:^(BOOL status, int code, NSString *message) {
                    NSString *msgParam;
                    if (status) {
                        msgParam = @"Send DTMF successfully";
                    } else {
                        msgParam = @"Send DTMF failed. The client is not connected to Stringee Server.";
                    }

                    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
                    [eventData setObject:msgParam forKey:@"message"];
                    [self triggerCallbackWithStatus:status withData:eventData withCallbackId:command.callbackId];
                }];
            } else {
                NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
                [eventData setObject:@"Send DTMF failed. The dtmf is invalid." forKey:@"message"];
                [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
            }
    } else {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Send DTMF failed. The call is not found." forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)sendCallInfo:(CDVInvokedUrlCommand *)command {
    NSLog(@"sendCallInfo");
    NSString *iden = [[command arguments] objectAtIndex:0];
    NSString *callInfo = [[command arguments] objectAtIndex:1];

    StringeeCall *call = [callList objectForKey:iden];

    if (call) {
        NSError *jsonError;
        NSData *objectData = [callInfo dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:objectData
                                                        options:NSJSONReadingMutableContainers 
                                                        error:&jsonError];

        if (jsonError) {
            NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
            [eventData setObject:@"Send call info failed. The call info format is invalid." forKey:@"message"];
            [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
        } else {
            [call sendCallInfo:data completionHandler:^(BOOL status, int code, NSString *message) {
                NSString *msgParam;
                if (status) {
                    msgParam = @"Send call info successfully";
                } else {
                    msgParam = @"Send call info failed. The client is not connected to Stringee Server.";
                }

                NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
                [eventData setObject:msgParam forKey:@"message"];
                [self triggerCallbackWithStatus:status withData:eventData withCallbackId:command.callbackId];
            }];
        }
    } else {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Send call info failed. The call is not found." forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)getCallStats:(CDVInvokedUrlCommand *)command {
    NSLog(@"getCallStats");
    NSString *iden = [[command arguments] objectAtIndex:0];
 
    StringeeCall *call = [callList objectForKey:iden];

    if (call) {
        [call statsWithCompletionHandler:^(NSDictionary<NSString *,NSString *> *values) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:values
                                            options:NSJSONWritingPrettyPrinted
                                            error:nil];
            NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
            [eventData setObject:jsonString forKey:@"stats"];
            [self triggerCallbackWithStatus:true withData:eventData withCallbackId:command.callbackId];
        }];
    } else {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Can not get call stats. The call is not found." forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)mute:(CDVInvokedUrlCommand *)command {
    NSLog(@"mute");
    NSString *iden = [[command arguments] objectAtIndex:0];
    NSNumber *mute = [[command arguments] objectAtIndex:1];

    StringeeCall *call = [callList objectForKey:iden];
    if (call) {
        [call mute:[mute boolValue]];
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Success" forKey:@"message"];
        [self triggerCallbackWithStatus:true withData:eventData withCallbackId:command.callbackId];
    } else {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Fail" forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)setSpeakerphoneOn:(CDVInvokedUrlCommand *)command {
    NSLog(@"setSpeakerphoneOn");
    NSString *iden = [[command arguments] objectAtIndex:0];
    NSNumber *speaker = [[command arguments] objectAtIndex:1];

    StringeeCall *call = [callList objectForKey:iden];
    if (call) {
        [[StringeeAudioManager instance] setLoudspeaker:[speaker boolValue]];
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Success" forKey:@"message"];
        [self triggerCallbackWithStatus:true withData:eventData withCallbackId:command.callbackId];
    } else {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Fail" forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)switchCamera:(CDVInvokedUrlCommand *)command {
    NSLog(@"switchCamera");
    NSString *iden = [[command arguments] objectAtIndex:0];
 
    StringeeCall *call = [callList objectForKey:iden];
    if (call) {
        [call switchCamera];
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Success" forKey:@"message"];
        [self triggerCallbackWithStatus:true withData:eventData withCallbackId:command.callbackId];
    } else {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Fail" forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}

- (void)enableVideo:(CDVInvokedUrlCommand *)command {
    NSLog(@"enableVideo");
    NSString *iden = [[command arguments] objectAtIndex:0];
    NSNumber *enableVideo = [[command arguments] objectAtIndex:1];

    StringeeCall *call = [callList objectForKey:iden];
    if (call) {
        [call enableLocalVideo:[enableVideo boolValue]];
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Success" forKey:@"message"];
        [self triggerCallbackWithStatus:true withData:eventData withCallbackId:command.callbackId];
    } else {
        NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
        [eventData setObject:@"Fail" forKey:@"message"];
        [self triggerCallbackWithStatus:false withData:eventData withCallbackId:command.callbackId];
    }
}



#pragma mark Call Delegate
- (void)didChangeSignalingState:(StringeeCall *)stringeeCall signalingState:(SignalingState)signalingState reason:(NSString *)reason sipCode:(int)sipCode sipReason:(NSString *)sipReason {
    
    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeCall.callId forKey:@"callId"];
    [eventData setObject:@(signalingState) forKey:@"code"];
    [eventData setObject:reason forKey:@"reason"];
    [eventData setObject:@(sipCode) forKey:@"sipCode"];
    [eventData setObject:sipReason forKey:@"sipReason"];

    [self triggerEventForCall:stringeeCall withType:didChangeSignalingState withData:eventData];
}

- (void)didChangeMediaState:(StringeeCall *)stringeeCall mediaState:(MediaState)mediaState {

    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeCall.callId forKey:@"callId"];
    switch (mediaState) {
        case MediaStateConnected:
            [eventData setObject:@(0) forKey:@"code"];
            [eventData setObject:@"Connected" forKey:@"description"];
            break;
        case MediaStateDisconnected:
            [eventData setObject:@(1) forKey:@"code"];
            [eventData setObject:@"Disconnected" forKey:@"description"];
            break;
        default:
            break;
    }

    [self triggerEventForCall:stringeeCall withType:didChangeMediaState withData:eventData];

}

- (void)didReceiveLocalStream:(StringeeCall *)stringeeCall {
    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeCall.callId forKey:@"callId"];
    [self triggerEventForCall:stringeeCall withType:didReceiveLocalStream withData:eventData];
}

- (void)didReceiveRemoteStream:(StringeeCall *)stringeeCall {
    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeCall.callId forKey:@"callId"];
    [self triggerEventForCall:stringeeCall withType:didReceiveRemoteStream withData:eventData];
}

- (void)didReceiveDtmfDigit:(StringeeCall *)stringeeCall callDTMF:(CallDTMF)callDTMF {
    NSString * digit = @"";
    if ((long)callDTMF <= 9) {
        digit = [NSString stringWithFormat:@"%ld", (long)callDTMF];
    } else if (callDTMF == 10) {
        digit = @"*";
    } else if (callDTMF == 11) {
        digit = @"#";
    }

    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeCall.callId forKey:@"callId"];
    [eventData setObject:digit forKey:@"dtmf"];
    [self triggerEventForCall:stringeeCall withType:didReceiveDtmfDigit withData:eventData];

}

- (void)didReceiveCallInfo:(StringeeCall *)stringeeCall info:(NSDictionary *)info {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:info
                                            options:NSJSONWritingPrettyPrinted
                                            error:nil];
    NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeCall.callId forKey:@"callId"];
    [eventData setObject:jsonString forKey:@"data"];
    [self triggerEventForCall:stringeeCall withType:didReceiveCallInfo withData:eventData];
}

- (void)didHandleOnAnotherDevice:(StringeeCall *)stringeeCall signalingState:(SignalingState)signalingState reason:(NSString *)reason sipCode:(int)sipCode sipReason:(NSString *)sipReason {
    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    [eventData setObject:stringeeCall.callId forKey:@"callId"];
    [eventData setObject:@(signalingState) forKey:@"code"];
    [eventData setObject:reason forKey:@"description"];
    [self triggerEventForCall:stringeeCall withType:didHandleOnAnotherDevice withData:eventData];
}

#pragma mark Helper

- (void)triggerJSEvent:(NSString*)event withType:(NSString*)type withData:(id)data {
    NSMutableDictionary* message = [[NSMutableDictionary alloc] init];
    [message setObject:type forKey:@"eventType"];
    if (data) {
        [message setObject:data forKey:@"data"];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
    [pluginResult setKeepCallbackAsBool:YES];

    NSString* callbackId = [callbackList objectForKey:event];

    if (!callbackId.length) {
        return;
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)triggerEventForCall:(StringeeCall *)stringeeCall withType:(NSString*)type withData:(id)data {
    // Tìm identifier của JSCall
    NSString *iden = [[callList allKeysForObject:stringeeCall] firstObject];
    
    if (!iden.length) {
        return;
    }

    [self triggerJSEvent: iden withType: type withData: data];
}

- (void)triggerCallbackWithStatus:(BOOL)status withData:(id)data withCallbackId:(NSString *)callbackId {
    CDVPluginResult *pluginResult;
    if (status) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:data];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}





@end
