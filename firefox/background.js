let nativePort=null,lastTab=null,retryTimer=null;
function connect(){
  try{
    nativePort=browser.runtime.connectNative("lol.zxt.dynamicnotch");
    nativePort.onMessage.addListener(async m=>{
      if(!m||m.type!=="action"||lastTab===null)return;
      try{await browser.tabs.sendMessage(lastTab,m);}catch(e){}
    });
    nativePort.onDisconnect.addListener(()=>{nativePort=null;clearTimeout(retryTimer);retryTimer=setTimeout(connect,700);});
  }catch(e){clearTimeout(retryTimer);retryTimer=setTimeout(connect,700);}
}
browser.runtime.onMessage.addListener((m,sender)=>{
  if(!m||m.type!=="mediaState"||!sender.tab)return;
  if(m.playing)lastTab=sender.tab.id;
  if(lastTab===null)lastTab=sender.tab.id;
  if(sender.tab.id!==lastTab&&!m.playing)return;
  if(nativePort){
    try{nativePort.postMessage(Object.assign({type:"media"},m));}catch(e){}
  }
});
browser.tabs.onRemoved.addListener(id=>{if(id===lastTab)lastTab=null;});
connect();