#define BUILDING_NODE_EXTENSION

#include "EmiSockDelegate.h"

#include "EmiNodeUtil.h"
#include "EmiSocket.h"
#include "EmiConnection.h"

#include <node.h>
#include <netinet/in.h>

using namespace v8;

EmiSockDelegate::EmiSockDelegate(EmiSocket& es) : _es(es) {}

EmiSockDelegate::EC *EmiSockDelegate::makeConnection(const EmiConnParams<EmiBinding>& params) {
    HandleScope scope;
    
    // TODO I think the HandleScope will dispose of EmiConnection after
    // this function, which is not what we want... Exactly what will
    // happen?
    
    Handle<Object> obj(EmiConnection::NewInstance(_es, params));
    EmiConnection *ec = node::ObjectWrap::Unwrap<EmiConnection>(obj);
    return &ec->getConn();
}

void EmiSockDelegate::gotServerConnection(EC& conn) {
    HandleScope scope;
    
    EmiConnection& ec(conn.getDelegate().getConnection());
    
    Handle<Value> jsHandle(ec._es._jsHandle);
    
    const unsigned argc = 3;
    Handle<Value> argv[argc] = {
        jsHandle.IsEmpty() ? Handle<Value>(Undefined()) : jsHandle,
        ec._es.handle_,
        ec.handle_
    };
    Local<Value> ret = EmiSocket::gotConnection->Call(Context::GetCurrent()->Global(), argc, argv);
    
    if (!ret.IsEmpty() && ret->IsObject()) {
        conn.getDelegate().getConnection().setJsHandle(ret->ToObject());
    }
}

void EmiSockDelegate::connectionOpened(ConnectionOpenedCallbackCookie& cookie,
                                       bool error,
                                       EmiDisconnectReason reason,
                                       EC& conn) {
    HandleScope scope;
    
    const unsigned argc = 2;
    Handle<Value> argv[argc];
    
    // TODO Give the error as something better than just the error code
    argv[0] = error ? Number::New(reason) : Null();
    
    if (error) {
        argv[1] = Null();
    }
    else {
        argv[1] = conn.getDelegate().getConnection().handle_;
    }
    
    Local<Value> ret = cookie->CallAsFunction(Context::GetCurrent()->Global(), argc, argv);
    
    if (!ret.IsEmpty() && ret->IsObject()) {
        conn.getDelegate().getConnection().setJsHandle(ret->ToObject());
    }
    
    cookie.Dispose();
}

void EmiSockDelegate::connectionGotMessage(EC *conn,
                                           EmiUdpSocket<EmiBinding> *socket,
                                           EmiTimeInterval now,
                                           const sockaddr_storage& inboundAddress,
                                           const sockaddr_storage& remoteAddress,
                                           const EmiBinding::TemporaryData& data,
                                           size_t offset,
                                           size_t len) {
    conn->onMessage(now, socket,
                    inboundAddress, remoteAddress,
                    data, offset, len);
}
