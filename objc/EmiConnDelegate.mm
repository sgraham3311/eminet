//
//  EmiConnDelegate.mm
//  roshambo
//
//  Created by Per Eckerdal on 2012-04-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EmiConnDelegate.h"

#import "EmiSocketInternal.h"
#import "EmiConnectionInternal.h"

EmiConnDelegate::EmiConnDelegate(EmiConnection *conn) :
_conn(conn) {}

void EmiConnDelegate::invalidate() {
    if (!_conn) {
        // invalidate has already been called
        return;
    }
    
    if (EMI_CONNECTION_TYPE_SERVER == _conn.conn->getType()) {
        // TODO Invoke this from the EmiSock queue
        _conn.emiSocket.sock->deregisterServerConnection(_conn.conn);
    }
    
    // Just to be sure, since the ivar is __unsafe_unretained
    // Note that this code would be incorrect if connections supported reconnecting; It's correct only because after a forceClose, the delegate will never be called again.
    _conn.delegate = nil;
    
    // Because this is a strong reference, we need to nil it out to let ARC deallocate this connection for us
    _conn = nil;
}

void EmiConnDelegate::emiConnMessage(EmiChannelQualifier channelQualifier, NSData *data, NSUInteger offset, NSUInteger size) {
    [_conn.delegate emiConnectionMessage:_conn
                        channelQualifier:channelQualifier 
                                    data:[data subdataWithRange:NSMakeRange(offset, size)]];
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

void EmiConnDelegate::emiNatPunchthroughFinished(bool success) {
    if (success) {
        if ([_conn.delegate respondsToSelector:@selector(emiP2PConnectionEstablished:)]) {
            [_conn.delegate emiP2PConnectionEstablished:_conn];
        }
    }
    else {
        if ([_conn.delegate respondsToSelector:@selector(emiP2PConnectionNotEstablished:)]) {
            [_conn.delegate emiP2PConnectionNotEstablished:_conn];
        }
    }
}
