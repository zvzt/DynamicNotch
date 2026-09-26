function pickMedia(){
  const all=[...document.querySelectorAll("video,audio")];
  return all.find(e=>!e.paused&&!e.ended)||all.find(e=>Number.isFinite(e.duration)&&e.duration>0)||all[0]||null;
}
function clean(v){return String(v||"").replace(/\s+/g," ").trim();}
function meta(name){
  const a=document.querySelector(`meta[property="${name}"]`);
  const b=document.querySelector(`meta[name="${name}"]`);
  return clean((a||b)?.content||"");
}
function titleFor(){
  return clean(meta("og:title")||meta("twitter:title")||meta("title")||document.title.replace(/\s*[-–]\s*YouTube\s*$/i,""));
}
function artistFor(){
  const yt=document.querySelector("ytd-video-owner-renderer #channel-name a,#owner #channel-name a,ytd-channel-name a");
  return clean(yt?.textContent||meta("author")||document.querySelector('meta[itemprop="author"]')?.content||"Firefox");
}
function artworkFor(){return clean(meta("og:image")||meta("twitter:image")||document.querySelector('link[rel="image_src"]')?.href||"");}
function report(){
  const e=pickMedia();
  if(!e)return;
  browser.runtime.sendMessage({
    type:"mediaState",
    title:titleFor(),
    artist:artistFor(),
    url:location.href,
    artworkURL:artworkFor(),
    duration:Number.isFinite(e.duration)?e.duration:1,
    currentTime:Number.isFinite(e.currentTime)?e.currentTime:0,
    volume:Math.round(e.volume*100),
    playing:!e.paused&&!e.ended
  }).catch(()=>{});
}
browser.runtime.onMessage.addListener(m=>{
  if(!m||m.type!=="action")return;
  const e=pickMedia();
  if(!e)return;
  if(m.action==="setVolume"){
    e.volume=Math.max(0,Math.min(1,Number(m.value)/100));
    e.dispatchEvent(new Event("volumechange",{bubbles:true}));
  }else if(m.action==="playPause"){
    if(e.paused)e.play().catch(()=>{});else e.pause();
  }else if(m.action==="seek"){
    const v=Math.max(0,Math.min(Number(m.value)||0,Number.isFinite(e.duration)?e.duration:Number(m.value)||0));
    try{e.currentTime=v;}catch(_){}
  }else if(m.action==="next"){
    const b=document.querySelector(".ytp-next-button,a.ytp-next-button");
    if(b)b.click();
  }else if(m.action==="previous"){
    const b=document.querySelector(".ytp-prev-button,a.ytp-prev-button");
    if(b)b.click();
  }
  setTimeout(report,60);
});
setInterval(report,300);
document.addEventListener("play",report,true);
document.addEventListener("pause",report,true);
document.addEventListener("loadedmetadata",report,true);
document.addEventListener("durationchange",report,true);
document.addEventListener("timeupdate",report,true);
document.addEventListener("volumechange",report,true);