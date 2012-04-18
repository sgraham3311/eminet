//
//  EmiConnDelegate.mm
//  roshambo
//
//  Created by Per Eckerdal on 2012-04-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EmiConnDelegate.h"

EmiConnDelegate::EmiConnDelegate(EmiConnection *conn) :
_conn(conn),
_tickTimer(nil),
_heartbeatTimer(nil),
_rtoTimer(nil),
_connectionTimer(nil) {}

void EmiConnDelegate::invalidate() {
    [_tickTimer invalidate];
    _tickTimer = nil;
    
    [_heartbeatTimer invalidate];
    _heartbeatTimer = nil;
    
    [_rtoTimer invalidate];
    _rtoTimer = nil;
    
    [_connectionTimer invalidate];
    _connectionTimer = nil;
    
    // Just to be sure, since the ivar is __unsafe_unretained
    // Note that this code would be incorrect if connections supported reconnecting; It's correct only because after a forceClose, the delegate will never be called again.
    _conn.delegate = nil;
    
    // Because this is a strong reference, we need to nil it out to let ARC deallocate this connection for us
    _conn = nil;
}

void EmiConnDelegate::emiConnMessage(EmiChannelQualifier channelQualifier, NSData *data, NSUInteger offset, NSUInteger size) {
    [_conn.delegate emiConnectionMessage:_conn
                        channelQualifier:channelQualifier 
                                    data:data
                                  offset:offset
                                    size:size];
}

void EmiConnDelegate::scheduleConnectionWarning(EmiTimeInterval warningTimeout) {
    [_connectionTimer invalidate];
    _connectionTimer = [NSTimer scheduledTimerWithTimeInterval:warningTimeout
                                                        target:_conn
                                                      selector:@selector(_connectionWarningCallback:)
                                                      userInfo:[NSNumber numberWithDouble:warningTimeout]
                                                       repeats:NO];
}

void EmiConnDelegate::scheduleConnectionTimeout(EmiTimeInterval interval) {
    [_connectionTimer invalidate];
    _connectionTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                        target:_conn
                                                      selector:@selector(_connectionTimeoutCallback:) 
                                                      userInfo:nil 
                                                       repeats:NO];
}

void EmiConnDelegate::ensureTickTimeout(EmiTimeInterval interval) {
    if (!_tickTimer || ![_tickTimer isValid]) {
        _tickTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:_conn
                                                    selector:@selector(_tickTimeoutCallback:)
                                                    userInfo:nil 
                                                     repeats:NO];
    }
}

void EmiConnDelegate::scheduleHeartbeatTimeout(EmiTimeInterval interval) {
    [_heartbeatTimer invalidate];
    _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                       target:_conn
                                                     selector:@selector(_heartbeatTimeoutCallback:)
                                                     userInfo:nil 
                                                      repeats:NO];
}

void EmiConnDelegate::ensureRtoTimeout(EmiTimeInterval rto) {
    if (!_rtoTimer || ![_rtoTimer isValid]) {
        // this._rto will likely change before the timeout fires. When
        // the timeout fires we want the value of _rto at the time
        // the timeout was set, not when it fires. That's why we store
        // rto with the NSTimer.
        _rtoTimer = [NSTimer scheduledTimerWithTimeInterval:rto
                                                     target:_conn
                                                   selector:@selector(_rtoTimeoutCallback:)
                                                   userInfo:[NSNumber numberWithDouble:rto]
                                                    repeats:NO];
    }
}

void EmiConnDelegate::invalidateRtoTimeout() {
    [_rtoTimer invalidate];
    _rtoTimer = nil;
}

void EmiConnDelegate::emiConnLost() {
    [_conn.delegate emiConnectionLost:_conn];
}

void EmiConnDelegate::emiConnRegained() {
    [_conn.delegate emiConnectionRegained:_conn];
}

void EmiConnDelegate::emiConnDisconnect(EmiDisconnectReason reason) {
    [_conn.delegate emiConnectionDisconnect:_conn forReason:reason];
}