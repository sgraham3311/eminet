#define BUILDING_NODE_EXTENSION
#ifndef emilir_EmiSocket_h
#define emilir_EmiSocket_h

#include "EmiSockDelegate.h"
#include "EmiConnDelegate.h"
#include "EmiAddressCmp.h"

#include "../core/EmiSock.h"
#include "../core/EmiConn.h"
#include <node.h>

class EmiSocket : public node::ObjectWrap {
 private:
  
  typedef EmiSock<EmiSockDelegate, EmiConnDelegate> ES;
  
  ES _sock;
  double counter_;
  
  // Private copy constructor and assignment operator
  inline EmiSocket(const EmiSocket& other);
  inline EmiSocket& operator=(const EmiSocket& other);
  
  EmiSocket(const EmiSockConfig<EmiSockDelegate::Address>& sc);
  virtual ~EmiSocket();

  static v8::Handle<v8::Value> New(const v8::Arguments& args);
  static v8::Handle<v8::Value> PlusOne(const v8::Arguments& args);
 public:
  static void Init(v8::Handle<v8::Object> target);
  
  static v8::Persistent<v8::Function> gotConnection;
  static v8::Persistent<v8::Function> connectionMessage;
  static v8::Persistent<v8::Function> connectionLost;
  static v8::Persistent<v8::Function> connectionRegained;
  static v8::Persistent<v8::Function> connectionDisconnect;
  
  inline ES& getSock() { return _sock; }
  inline const ES& getSock() const { return _sock; }
};

#endif