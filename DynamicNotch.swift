// DynamicNotch
// Created by ZXT
// Copyright (c) 2026 ZXT
// Licensed under the MIT License.
// Contact: contact@zxt.lol | Discord: 1531412914005606513

import Cocoa
import SwiftUI
import ServiceManagement

struct ShortcutItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var icon: String
    var path: String
}

struct SpotifyBrandLogo: View {
    var bg: Color = Color(red: 0.11, green: 0.84, blue: 0.38)
    var fg: Color = .black
    var size: CGFloat = 14
    
    var body: some View {
        ZStack {
            Circle()
                .fill(bg)
                .frame(width: size, height: size)
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                Path { p in
                    p.move(to: CGPoint(x: w * 0.23, y: h * 0.40))
                    p.addQuadCurve(to: CGPoint(x: w * 0.77, y: h * 0.34), control: CGPoint(x: w * 0.50, y: h * 0.25))
                    p.move(to: CGPoint(x: w * 0.27, y: h * 0.56))
                    p.addQuadCurve(to: CGPoint(x: w * 0.73, y: h * 0.51), control: CGPoint(x: w * 0.50, y: h * 0.44))
                    p.move(to: CGPoint(x: w * 0.32, y: h * 0.72))
                    p.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.68), control: CGPoint(x: w * 0.50, y: h * 0.62))
                }
                .stroke(fg, style: StrokeStyle(lineWidth: w * 0.088, lineCap: .round))
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}


enum DynamicNotchStorage {
    static let fm = FileManager.default

    static var rootURL: URL {
        fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DynamicNotch", isDirectory: true)
    }

    static func prepare() {
        let root = rootURL
        try? fm.createDirectory(at: root, withIntermediateDirectories: true)

        guard let resources = Bundle.main.resourceURL else { return }
        let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "unknown"
        let marker = root.appendingPathComponent(".bundle-version")
        let installedVersion = (try? String(contentsOf: marker, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard installedVersion != version else { return }

        let managedItems = ["AppIcon.png", "FirefoxExtension", "firefox_host.pl", "media-control"]
        for name in managedItems {
            let source = resources.appendingPathComponent(name)
            let destination = root.appendingPathComponent(name)
            guard fm.fileExists(atPath: source.path) else { continue }
            if fm.fileExists(atPath: destination.path) {
                try? fm.removeItem(at: destination)
            }
            try? fm.copyItem(at: source, to: destination)
        }

        try? version.write(to: marker, atomically: true, encoding: .utf8)
    }

    static func logoImage() -> NSImage? {
        let supportLogo = rootURL.appendingPathComponent("AppIcon.png")
        if let image = NSImage(contentsOf: supportLogo) { return image }
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("AppIcon.png"),
           let image = NSImage(contentsOf: bundled) { return image }
        return nil
    }
}

final class MediaControlEngine {
    static let shared = MediaControlEngine()
    let toolPath: String
    private let queue = DispatchQueue(label: "lol.zxt.dynamicnotch.media", qos: .userInitiated)

    init() {
        DynamicNotchStorage.prepare()
        let support = DynamicNotchStorage.rootURL.appendingPathComponent("media-control/bin/media-control").path
        let bundled = Bundle.main.resourceURL?.appendingPathComponent("media-control/bin/media-control").path
        let candidates = [support, bundled, "/opt/homebrew/bin/media-control", "/usr/local/bin/media-control"].compactMap { $0 }
        toolPath = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) ?? "/opt/homebrew/bin/media-control"
    }

    func get(includeArtwork: Bool, completion: @escaping ([String: Any]?) -> Void) {
        queue.async {
            let p = Process()
            let out = Pipe()
            p.executableURL = URL(fileURLWithPath: self.toolPath)
            p.arguments = includeArtwork ? ["get", "--now"] : ["get", "--now", "--no-artwork"]
            p.standardOutput = out
            p.standardError = Pipe()
            do {
                try p.run()
                p.waitUntilExit()
                let data = out.fileHandleForReading.readDataToEndOfFile()
                guard p.terminationStatus == 0,
                      let obj = try? JSONSerialization.jsonObject(with: data),
                      let dict = obj as? [String: Any] else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                DispatchQueue.main.async { completion(dict) }
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    func command(_ args: [String]) {
        queue.async {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: self.toolPath)
            p.arguments = args
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try? p.run()
            p.waitUntilExit()
        }
    }
}

final class IslandState: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published var selectedProvider: String = UserDefaults.standard.string(forKey: "dyn_provider") ?? "System"
    @Published var trackTitle: String = "No Audio"
    @Published var trackArtist: String = "System Idle"
    @Published var appSource: String = "System"
    @Published var sourceBundle: String = ""
    @Published var isPlaying: Bool = false
    @Published var trackPos: Double = 0.0
    @Published var trackDur: Double = 1.0
    @Published var appVolume: Double = 50.0
    @Published var volumeAvailable: Bool = false
    @Published var artwork: NSImage? = nil
    @Published var compactW: CGFloat = 224
    @Published var compactH: CGFloat = 32
    @Published var expandedW: CGFloat = 430
    @Published var expandedH: CGFloat = 145
    @Published var launchAtLogin: Bool = false
    @Published var bgOpacity: Double = UserDefaults.standard.object(forKey: "dyn_bg_opacity") != nil ? UserDefaults.standard.double(forKey: "dyn_bg_opacity") : 1.0 {
        didSet { UserDefaults.standard.set(bgOpacity, forKey: "dyn_bg_opacity") }
    }
    @Published var accentName: String = UserDefaults.standard.string(forKey: "dyn_accent") ?? "White" {
        didSet { UserDefaults.standard.set(accentName, forKey: "dyn_accent") }
    }

    var accentColor: Color {
        switch accentName {
        case "Orange": return Color(red: 1.0, green: 0.58, blue: 0.0)
        case "Purple": return Color(red: 0.72, green: 0.35, blue: 0.98)
        case "Blue": return Color(red: 0.18, green: 0.56, blue: 0.98)
        case "Pink": return Color(red: 1.0, green: 0.22, blue: 0.48)
        case "Green": return Color(red: 0.22, green: 0.82, blue: 0.44)
        default: return Color.white
        }
    }

    var isSeeking: Bool = false
    var isChangingVol: Bool = false
    var lastSyncDate: Date = Date()
    var lastIdentifier: String = ""
    var panel: NSPanel?
    private var isQuerying = false
    private var missCount = 0
    private var artworkIsReal = false
    private var lastArtworkAttempt = Date.distantPast
    private var volumeWorkItem: DispatchWorkItem?
    private var currentAlbum = ""
    private var remoteArtworkURL = ""

    init() {
        DynamicNotchStorage.prepare()
        checkLoginStatus()
        setupListeners()
    }

    func checkLoginStatus() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    func toggleLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    launchAtLogin = false
                } else {
                    try SMAppService.mainApp.register()
                    launchAtLogin = true
                }
            } catch {}
        }
    }

    func setupListeners() {
        queryMedia()
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in self?.queryMedia() }
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isPlaying && !self.isSeeking {
                let elapsed = Date().timeIntervalSince(self.lastSyncDate)
                self.trackPos = min(self.trackDur, self.trackPos + elapsed)
                self.lastSyncDate = Date()
            }
        }
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isChangingVol else { return }
            self.readAppVolume()
        }
    }

    func queryAppleMusic(completion: @escaping ([String: Any]?) -> Void) {
        let script = #"""
        function run(){
          const m=Application('Music');
          if(!m.running()) return '';
          const safe=(f,d)=>{try{const v=f();return v===undefined||v===null?d:v}catch(e){return d}};
          const state=String(safe(()=>m.playerState(),'stopped'));
          if(state==='stopped') return '';
          const t=m.currentTrack;
          const title=String(safe(()=>t.name(),''));
          const artist=String(safe(()=>t.artist(),''));
          const album=String(safe(()=>t.album(),''));
          if(!title) return '';
          const o={
            title:title,
            artist:artist,
            album:album,
            duration:Number(safe(()=>t.duration(),1)),
            elapsedTimeNow:Number(safe(()=>m.playerPosition(),0)),
            playing:state==='playing',
            bundleIdentifier:'com.apple.Music',
            parentApplicationBundleIdentifier:'com.apple.Music',
            uniqueIdentifier:title+'|'+artist+'|'+album,
            volume:Number(safe(()=>m.soundVolume(),50))
          };
          return JSON.stringify(o);
        }
        """#
        runJXA(script) { out in
            guard !out.isEmpty, let data=out.data(using:.utf8), let obj=try? JSONSerialization.jsonObject(with:data), let dict=obj as? [String:Any], let title=dict["title"] as? String, !title.isEmpty else { completion(nil); return }
            completion(dict)
        }
    }

    func readFirefoxMedia() -> [String: Any]? {
        let path="/tmp/dynamicnotch_firefox_state.json"
        guard let attrs=try? FileManager.default.attributesOfItem(atPath:path),
              let modified=attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(modified) < 2.0,
              let data=try? Data(contentsOf:URL(fileURLWithPath:path)),
              let raw=try? JSONSerialization.jsonObject(with:data),
              let obj=raw as? [String:Any],
              (obj["playing"] as? Bool) == true,
              let title=obj["title"] as? String, !title.isEmpty else { return nil }
        let artist=(obj["artist"] as? String) ?? "Firefox"
        let url=(obj["url"] as? String) ?? ""
        var d:[String:Any]=[
            "title":title,
            "artist":artist,
            "duration":number(obj["duration"]) ?? 1.0,
            "elapsedTimeNow":number(obj["currentTime"]) ?? 0.0,
            "playing":true,
            "bundleIdentifier":"org.mozilla.firefox",
            "parentApplicationBundleIdentifier":"org.mozilla.firefox",
            "uniqueIdentifier":"firefox|"+url+"|"+title
        ]
        if let art=obj["artworkURL"] as? String,!art.isEmpty{d["artworkURL"]=art}
        return d
    }

    func queryMedia() {
        guard !isQuerying else { return }
        isQuerying = true
        if let firefox=readFirefoxMedia() {
            isQuerying=false
            missCount=0
            applyMedia(firefox)
            return
        }
        MediaControlEngine.shared.get(includeArtwork: false) { [weak self] dict in
            guard let self = self else { return }
            let finish: ([String:Any]?) -> Void = { finalDict in
                self.isQuerying = false
                if let firefox=self.readFirefoxMedia() {
                    self.missCount=0
                    self.applyMedia(firefox)
                    return
                }
                guard let finalDict=finalDict, !(finalDict["title"] is NSNull) else {
                    self.missCount += 1
                    if self.missCount >= 2 { self.clearMedia() }
                    return
                }
                self.missCount = 0
                self.applyMedia(finalDict)
            }
            if let dict=dict {
                let bundle=((dict["parentApplicationBundleIdentifier"] as? String)?.isEmpty==false ? dict["parentApplicationBundleIdentifier"] as? String : nil) ?? (dict["bundleIdentifier"] as? String) ?? ""
                if self.isAppleMusicSource(bundle) {
                    self.queryAppleMusic { music in
                        if let firefox=self.readFirefoxMedia(){finish(firefox)}
                        else{finish(music ?? dict)}
                    }
                } else { finish(dict) }
            } else {
                self.queryAppleMusic { music in finish(music) }
            }
        }
    }

    func applyMedia(_ dict: [String: Any]) {
        let title = (dict["title"] as? String) ?? ""
        guard !title.isEmpty else { return }
        let artist = (dict["artist"] as? String) ?? ""
        let album = (dict["album"] as? String) ?? ""
        let bundle = ((dict["parentApplicationBundleIdentifier"] as? String)?.isEmpty == false ? (dict["parentApplicationBundleIdentifier"] as? String) : nil) ?? (dict["bundleIdentifier"] as? String) ?? ""
        let playing = (dict["playing"] as? Bool) ?? false
        let duration = number(dict["duration"]) ?? 1.0
        let elapsed = number(dict["elapsedTimeNow"]) ?? number(dict["elapsedTime"]) ?? 0.0
        let identifier = ((dict["uniqueIdentifier"] as? String) ?? "") + "|" + title + "|" + artist + "|" + bundle
        let changed = identifier != lastIdentifier

        isPlaying = playing
        trackTitle = title
        trackArtist = artist.isEmpty ? (album.isEmpty ? displayName(for: bundle) : album) : artist
        currentAlbum = album
        remoteArtworkURL = (dict["artworkURL"] as? String) ?? ""
        trackDur = max(duration, 1.0)
        if !isSeeking {
            trackPos = max(0, min(elapsed, trackDur))
            lastSyncDate = Date()
        }
        if bundle != sourceBundle {
            sourceBundle = bundle
            appSource = displayName(for: bundle)
            artworkIsReal = false
            if let v=number(dict["volume"]), !isBrowserSource(bundle) {
                appVolume=max(0,min(v,100))
                volumeAvailable = isAppleMusicSource(bundle) || bundle.lowercased().contains("spotify")
            } else { readAppVolume() }
            if isMusicSource(bundle) || bundle.lowercased().contains("firefox") {
                withAnimation(.easeInOut(duration: 0.12)) { artwork = nil }
            } else { setFallbackArtwork(bundle: bundle) }
        }
        if changed {
            lastIdentifier = identifier
            artworkIsReal = false
            if isMusicSource(bundle) || bundle.lowercased().contains("firefox") {
                withAnimation(.easeInOut(duration: 0.12)) { artwork = nil }
            } else { setFallbackArtwork(bundle: bundle) }
            fetchArtwork(attempt: 0)
        } else if !artworkIsReal && Date().timeIntervalSince(lastArtworkAttempt) > 1.5 {
            fetchArtwork(attempt: 0)
        }
    }

    func fetchArtwork(attempt: Int = 0) {
        lastArtworkAttempt = Date()
        let b=sourceBundle.lowercased()
        if b.contains("firefox"), !remoteArtworkURL.isEmpty {
            fetchRemoteArtwork(remoteArtworkURL, expected:lastIdentifier) {
                if self.artwork == nil { self.setFallbackArtwork(bundle:self.sourceBundle) }
            }
            return
        }
        if isAppleMusicSource(sourceBundle) {
            fetchAppleMusicArtwork(attempt:attempt)
            return
        }
        let expected = lastIdentifier
        MediaControlEngine.shared.get(includeArtwork: true) { [weak self] dict in
            guard let self = self, self.lastIdentifier == expected else { return }
            if let dict = dict,
               let b64 = dict["artworkData"] as? String,
               let data = Data(base64Encoded: b64),
               let img = NSImage(data: data) {
                self.artworkIsReal = true
                withAnimation(.easeInOut(duration: 0.22)) { self.artwork = img }
                return
            }
            if attempt < 5 {
                let delay = 0.35 + (Double(attempt) * 0.45)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if self.lastIdentifier == expected && !self.artworkIsReal { self.fetchArtwork(attempt: attempt + 1) }
                }
            } else if self.artwork == nil {
                self.setFallbackArtwork(bundle: self.sourceBundle)
            }
        }
    }

    func isAppleMusicSource(_ bundle: String) -> Bool {
        let b=bundle.lowercased()
        return b == "com.apple.music" || b.contains("apple.music")
    }

    func isMusicSource(_ bundle: String) -> Bool {
        let b = bundle.lowercased()
        return b.contains("spotify") || isAppleMusicSource(bundle)
    }

    func fetchRemoteArtwork(_ urlString:String, expected:String, fallback:@escaping ()->Void) {
        guard let url=URL(string:urlString) else { fallback(); return }
        URLSession.shared.dataTask(with:url){ [weak self] data,_,_ in
            guard let self=self else{return}
            DispatchQueue.main.async {
                guard self.lastIdentifier==expected else{return}
                if let data=data,let img=NSImage(data:data){
                    self.artworkIsReal=true
                    withAnimation(.easeInOut(duration:0.22)){self.artwork=img}
                }else{fallback()}
            }
        }.resume()
    }

    func fetchAppleMusicArtwork(attempt:Int=0) {
        let expected=lastIdentifier
        let artPath="/tmp/dynamicnotch_music_artwork"
        let script=#"""
        set outPath to POSIX file "/tmp/dynamicnotch_music_artwork"
        set outFile to missing value
        try
            tell application id "com.apple.Music"
                if not running then return ""
                set srcBytes to raw data of artwork 1 of current track
            end tell
            set outFile to open for access outPath with write permission
            set eof outFile to 0
            write srcBytes to outFile
            close access outFile
            return "/tmp/dynamicnotch_music_artwork"
        on error
            try
                if outFile is not missing value then close access outFile
            end try
            return ""
        end try
        """#
        runAppleScript(script){ [weak self] out in
            guard let self=self,self.lastIdentifier==expected else{return}
            if !out.isEmpty,
               let data=try? Data(contentsOf:URL(fileURLWithPath:artPath)),
               let img=NSImage(data:data) {
                self.artworkIsReal=true
                withAnimation(.easeInOut(duration:0.22)){self.artwork=img}
                return
            }
            self.fetchAppleMusicSystemArtwork(expected:expected,attempt:attempt)
        }
    }

    func fetchAppleMusicSystemArtwork(expected:String,attempt:Int=0) {
        let expectedTitle=trackTitle
        MediaControlEngine.shared.get(includeArtwork:true){ [weak self] dict in
            guard let self=self,self.lastIdentifier==expected else{return}
            if let dict=dict {
                let bundle=((dict["parentApplicationBundleIdentifier"] as? String)?.isEmpty==false ? dict["parentApplicationBundleIdentifier"] as? String : nil) ?? (dict["bundleIdentifier"] as? String) ?? ""
                let title=(dict["title"] as? String) ?? ""
                if self.isAppleMusicSource(bundle),
                   title.caseInsensitiveCompare(expectedTitle) == .orderedSame,
                   let b64=dict["artworkData"] as? String,
                   let data=Data(base64Encoded:b64),
                   let img=NSImage(data:data) {
                    self.artworkIsReal=true
                    withAnimation(.easeInOut(duration:0.22)){self.artwork=img}
                    return
                }
            }
            self.fetchAppleCatalogArtwork(expected:expected)
        }
    }

    func fetchAppleCatalogArtwork(expected:String) {
        let title=trackTitle,artist=trackArtist,album=currentAlbum
        var c=URLComponents(string:"https://itunes.apple.com/search")!
        c.queryItems=[
            URLQueryItem(name:"term",value:[artist,title,album].filter{!$0.isEmpty}.joined(separator:" ")),
            URLQueryItem(name:"entity",value:"song"),
            URLQueryItem(name:"limit",value:"10")
        ]
        guard let url=c.url else { if artwork == nil { setFallbackArtwork(bundle:sourceBundle) }; return }
        URLSession.shared.dataTask(with:url){ [weak self] data,_,_ in
            guard let self=self else{return}
            var artURL:String?
            if let data=data,
               let obj=try? JSONSerialization.jsonObject(with:data),
               let raw=obj as? [String:Any],
               let results=raw["results"] as? [[String:Any]] {
                let exact=results.first{
                    (($0["trackName"] as? String) ?? "").caseInsensitiveCompare(title) == .orderedSame &&
                    (($0["artistName"] as? String) ?? "").caseInsensitiveCompare(artist) == .orderedSame
                }
                let choice=exact ?? results.first
                artURL=choice?["artworkUrl100"] as? String
            }
            guard let rawURL=artURL else{
                DispatchQueue.main.async{if self.lastIdentifier==expected && self.artwork == nil{self.setFallbackArtwork(bundle:self.sourceBundle)}}
                return
            }
            let hi=rawURL.replacingOccurrences(of:"100x100bb",with:"600x600bb").replacingOccurrences(of:"100x100",with:"600x600")
            guard let u=URL(string:hi) else{return}
            URLSession.shared.dataTask(with:u){ data,_,_ in
                DispatchQueue.main.async{
                    guard self.lastIdentifier==expected else{return}
                    if let data=data,let img=NSImage(data:data){
                        self.artworkIsReal=true
                        withAnimation(.easeInOut(duration:0.22)){self.artwork=img}
                    }else if self.artwork == nil{self.setFallbackArtwork(bundle:self.sourceBundle)}
                }
            }.resume()
        }.resume()
    }

    func setFallbackArtwork(bundle: String) {
        guard !bundle.isEmpty else {
            withAnimation(.easeInOut(duration: 0.18)) { artwork = nil }
            return
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            withAnimation(.easeInOut(duration: 0.18)) { artwork = icon }
        } else {
            withAnimation(.easeInOut(duration: 0.18)) { artwork = nil }
        }
    }

    func displayName(for bundle: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) {
            return url.deletingPathExtension().lastPathComponent
        }
        let b = bundle.lowercased()
        if b.contains("firefox") { return "Firefox" }
        if b.contains("chrome") { return "Chrome" }
        if b.contains("safari") { return "Safari" }
        if b.contains("spotify") { return "Spotify" }
        if b.contains("music") { return "Music" }
        return bundle.isEmpty ? "System" : bundle
    }

    func number(_ value: Any?) -> Double? {
        if let n = value as? NSNumber { return n.doubleValue }
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        return nil
    }

    func clearMedia() {
        isPlaying = false
        trackTitle = "No Audio"
        trackArtist = "System Idle"
        appSource = "System"
        sourceBundle = ""
        trackPos = 0
        trackDur = 1
        lastIdentifier = ""
        currentAlbum = ""
        remoteArtworkURL = ""
        artworkIsReal = false
        volumeAvailable = false
        withAnimation(.easeInOut(duration: 0.18)) { artwork = nil }
    }

    func sendFirefoxCommand(_ action:String, value:Any?=nil) {
        var payload:[String:Any]=["id":String(Int(Date().timeIntervalSince1970*1000)),"action":action]
        if let value=value{payload["value"]=value}
        if let d=try? JSONSerialization.data(withJSONObject:payload){try? d.write(to:URL(fileURLWithPath:"/tmp/dynamicnotch_firefox_cmd.json"),options:.atomic)}
    }

    func isBrowserSource(_ bundle: String) -> Bool {
        let b = bundle.lowercased()
        return b.contains("firefox") || b.contains("chrome") || b.contains("safari")
    }

    func mediaPlayPause() {
        let b=sourceBundle.lowercased()
        if isAppleMusicSource(sourceBundle) {
            runAppleScript("tell application id \"com.apple.Music\" to playpause") { _ in
                DispatchQueue.main.asyncAfter(deadline:.now()+0.12){self.queryMedia()}
            }
            return
        }
        if b.contains("spotify") {
            runAppleScript("tell application id \"com.spotify.client\" to playpause") { _ in
                DispatchQueue.main.asyncAfter(deadline:.now()+0.12){self.queryMedia()}
            }
            return
        }
        if b.contains("firefox") { sendFirefoxCommand("playPause") }
        MediaControlEngine.shared.command(["toggle-play-pause"])
        DispatchQueue.main.asyncAfter(deadline:.now()+0.15){self.queryMedia()}
    }

    func mediaNext() {
        let b=sourceBundle.lowercased()
        if isAppleMusicSource(sourceBundle) {
            runAppleScript("tell application id \"com.apple.Music\" to next track") { _ in
                DispatchQueue.main.asyncAfter(deadline:.now()+0.2){self.queryMedia()}
            }
            return
        }
        if b.contains("spotify") {
            runAppleScript("tell application id \"com.spotify.client\" to next track") { _ in
                DispatchQueue.main.asyncAfter(deadline:.now()+0.2){self.queryMedia()}
            }
            return
        }
        if b.contains("firefox") { sendFirefoxCommand("seek",value:min(trackDur,trackPos+15.0)) }
        MediaControlEngine.shared.command(["skip-fifteen-seconds"])
        DispatchQueue.main.asyncAfter(deadline:.now()+0.2){self.queryMedia()}
    }

    func mediaPrev() {
        let b=sourceBundle.lowercased()
        if isAppleMusicSource(sourceBundle) {
            runAppleScript("tell application id \"com.apple.Music\" to previous track") { _ in
                DispatchQueue.main.asyncAfter(deadline:.now()+0.2){self.queryMedia()}
            }
            return
        }
        if b.contains("spotify") {
            runAppleScript("tell application id \"com.spotify.client\" to previous track") { _ in
                DispatchQueue.main.asyncAfter(deadline:.now()+0.2){self.queryMedia()}
            }
            return
        }
        if b.contains("firefox") { sendFirefoxCommand("seek",value:max(0,trackPos-15.0)) }
        MediaControlEngine.shared.command(["go-back-fifteen-seconds"])
        DispatchQueue.main.asyncAfter(deadline:.now()+0.2){self.queryMedia()}
    }

    func seek(to seconds: Double) {
        let s=max(0,min(seconds,trackDur))
        trackPos=s
        lastSyncDate=Date()
        let b=sourceBundle.lowercased()
        if isAppleMusicSource(sourceBundle) {
            runAppleScript("tell application id \"com.apple.Music\" to set player position to \(s)") { _ in
                DispatchQueue.main.asyncAfter(deadline:.now()+0.2){self.queryMedia()}
            }
            return
        }
        if b.contains("spotify") {
            runAppleScript("tell application id \"com.spotify.client\" to set player position to \(s)") { _ in
                DispatchQueue.main.asyncAfter(deadline:.now()+0.2){self.queryMedia()}
            }
            return
        }
        if b.contains("firefox") { sendFirefoxCommand("seek",value:s) }
        MediaControlEngine.shared.command(["seek",String(format:"%.3f",s)])
        DispatchQueue.main.asyncAfter(deadline:.now()+0.25){self.queryMedia()}
    }

    func runAppleScript(_ source: String, completion: ((String) -> Void)? = nil) {
        DispatchQueue.global(qos: .utility).async {
            let p = Process()
            let out = Pipe()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            p.arguments = ["-e", source]
            p.standardOutput = out
            p.standardError = Pipe()
            do {
                try p.run(); p.waitUntilExit()
                let data = out.fileHandleForReading.readDataToEndOfFile()
                let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                DispatchQueue.main.async { completion?(str) }
            } catch {
                DispatchQueue.main.async { completion?("") }
            }
        }
    }

    func runJXA(_ source: String, completion: ((String) -> Void)? = nil) {
        DispatchQueue.global(qos:.utility).async {
            let p=Process(), out=Pipe()
            p.executableURL=URL(fileURLWithPath:"/usr/bin/osascript")
            p.arguments=["-l","JavaScript","-e",source]
            p.standardOutput=out
            p.standardError=Pipe()
            do {
                try p.run(); p.waitUntilExit()
                let data=out.fileHandleForReading.readDataToEndOfFile()
                let str=String(data:data,encoding:.utf8)?.trimmingCharacters(in:.whitespacesAndNewlines) ?? ""
                DispatchQueue.main.async{ completion?(str) }
            } catch { DispatchQueue.main.async{ completion?("") } }
        }
    }

    func readAppVolume() {
        let b=sourceBundle.lowercased()
        if isAppleMusicSource(sourceBundle) {
            runJXA("const m=Application('Music');m.running()?String(m.soundVolume()):''") { out in
                if let v=Double(out){ self.volumeAvailable=true; if !self.isChangingVol { self.appVolume=v } } else { self.volumeAvailable=false }
            }
            return
        }
        if b.contains("spotify") {
            runAppleScript("tell application id \"com.spotify.client\" to get sound volume") { out in
                if let v=Double(out){ self.volumeAvailable=true; if !self.isChangingVol { self.appVolume=v } } else { self.volumeAvailable=false }
            }
            return
        }
        if isBrowserSource(sourceBundle) {
            runAppleScript("output volume of (get volume settings)") { out in
                if let v=Double(out){ self.volumeAvailable=true; if !self.isChangingVol { self.appVolume=v } } else { self.volumeAvailable=false }
            }
            return
        }
        volumeAvailable=false
    }

    func adjustVolume(to v: Double) {
        appVolume=max(0,min(v,100))
        let value=Int(appVolume.rounded()), b=sourceBundle.lowercased()
        volumeWorkItem?.cancel()
        let work=DispatchWorkItem {
            if self.isBrowserSource(self.sourceBundle) {
                let p=Process();p.executableURL=URL(fileURLWithPath:"/usr/bin/osascript");p.arguments=["-e","set volume output volume \(value)"];p.standardOutput=Pipe();p.standardError=Pipe();try? p.run();p.waitUntilExit();return
            }
            if self.isAppleMusicSource(self.sourceBundle) {
                let src="const m=Application('Music');if(m.running())m.soundVolume=\(value);"
                let p=Process();p.executableURL=URL(fileURLWithPath:"/usr/bin/osascript");p.arguments=["-l","JavaScript","-e",src];p.standardOutput=Pipe();p.standardError=Pipe();try? p.run();p.waitUntilExit();return
            }
            if b.contains("spotify") {
                let source="tell application id \"com.spotify.client\" to set sound volume to \(value)"
                let p=Process();p.executableURL=URL(fileURLWithPath:"/usr/bin/osascript");p.arguments=["-e",source];p.standardOutput=Pipe();p.standardError=Pipe();try? p.run();p.waitUntilExit()
            }
        }
        volumeWorkItem=work
        if isBrowserSource(sourceBundle) || isAppleMusicSource(sourceBundle) || b.contains("spotify") {
            volumeAvailable=true
            DispatchQueue.global(qos:.userInitiated).asyncAfter(deadline:.now()+0.02,execute:work)
        } else { volumeAvailable=false }
    }


}

func calcMarquee(time: Double, overflow: CGFloat) -> (shift: CGFloat, alpha: Double) {
    let speed: Double = 24.0
    let scrollDur = Double(overflow) / speed
    let startHold = 2.4
    let endHold = 1.6
    let rewindDur = 0.32
    let total = startHold + scrollDur + endHold + rewindDur
    let phase = time.truncatingRemainder(dividingBy: total)
    
    if phase < startHold {
        return (0.0, 1.0)
    } else if phase < (startHold + scrollDur) {
        let p = (phase - startHold) / scrollDur
        let ease = 0.5 - 0.5 * cos(p * .pi)
        return (CGFloat(ease) * overflow, 1.0)
    } else if phase < (startHold + scrollDur + endHold) {
        return (overflow, 1.0)
    } else {
        let r = (phase - (startHold + scrollDur + endHold)) / rewindDur
        let retEase = 1.0 - (0.5 - 0.5 * cos(r * .pi))
        let ghost = 0.4 + 0.6 * (r < 0.5 ? (1.0 - r * 2.0) : ((r - 0.5) * 2.0))
        return (overflow * CGFloat(retEase), ghost)
    }
}

struct GhostMarqueeText: View {
    let text: String
    let font: Font
    let nsFont: NSFont
    let color: Color
    let width: CGFloat
    
    var body: some View {
        let textWidth = (text as NSString).size(withAttributes: [.font: nsFont]).width
        let overflow = max(0, textWidth - width)
        
        Group {
            if overflow > 0 {
                TimelineView(.animation(minimumInterval: 0.016)) { ctx in
                    let anim = calcMarquee(time: ctx.date.timeIntervalSinceReferenceDate, overflow: overflow)
                    HStack(spacing: 0) {
                        Text(text)
                            .font(font)
                            .foregroundColor(color)
                            .fixedSize()
                            .offset(x: -anim.shift)
                            .opacity(anim.alpha)
                    }
                    .frame(width: width, alignment: .leading)
                    .clipped()
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.88),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            } else {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .frame(width: width, alignment: .leading)
            }
        }
    }
}

struct DynamicScrubber: View {
    @ObservedObject var state: IslandState
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let prog = CGFloat(max(0, min(state.trackPos / state.trackDur, 1.0)))
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 3)
                
                Capsule()
                    .fill(state.accentColor)
                    .frame(width: max(0, w * prog), height: 3)
                
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 6, height: 6)
                    .overlay(Circle().stroke(state.accentColor.opacity(0.5), lineWidth: 1))
                    .offset(x: max(0, min(w * prog - 3, w - 6)))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        state.isSeeking = true
                        let pct = Double(max(0, min(val.location.x / w, 1.0)))
                        state.trackPos = pct * state.trackDur
                    }
                    .onEnded { val in
                        let pct = Double(max(0, min(val.location.x / w, 1.0)))
                        state.seek(to: pct * state.trackDur)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            state.isSeeking = false
                        }
                    }
            )
        }
        .frame(height: 10)
    }
}

struct DynamicVolumeSlider: View {
    @ObservedObject var state: IslandState
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 8))
                .foregroundColor(state.accentColor.opacity(0.65))
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 58, height: 3)
                
                Capsule()
                    .fill(state.accentColor)
                    .frame(width: max(0, min(58 * CGFloat(state.appVolume / 100.0), 58)), height: 3)
                
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 5, height: 5)
                    .offset(x: max(0, min(58 * CGFloat(state.appVolume / 100.0) - 2.5, 53)))
            }
            .frame(width: 58, height: 12)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        guard state.volumeAvailable else { return }
                        state.isChangingVol = true
                        let pct = Double(max(0, min(val.location.x / 58.0, 1.0)))
                        state.appVolume = pct * 100.0
                        state.adjustVolume(to: state.appVolume)
                    }
                    .onEnded { _ in
                        state.isChangingVol = false
                    }
            )
            
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 8))
                .foregroundColor(state.accentColor.opacity(0.85))
        }
        .frame(height: 14)
        .opacity(state.volumeAvailable ? 1.0 : 0.35)
        .help(state.volumeAvailable ? "App volume" : "This player does not expose in-app volume control")
    }
}

struct SettingsGlassSlider: View {
    @ObservedObject var state: IslandState
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let prog = CGFloat(max(0, min((state.bgOpacity - 0.2) / 0.8, 1.0)))
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 4)
                
                Capsule()
                    .fill(state.accentColor)
                    .frame(width: max(0, w * prog), height: 4)
                
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(state.accentColor.opacity(0.6), lineWidth: 1))
                    .offset(x: max(0, min(w * prog - 4, w - 8)))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let pct = Double(max(0, min(val.location.x / w, 1.0)))
                        state.bgOpacity = 0.2 + (pct * 0.8)
                    }
            )
        }
        .frame(height: 12)
    }
}

struct IslandRootView: View {
    @ObservedObject var state: IslandState
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: state.isExpanded ? 24 : 16, style: .continuous)
                    .fill(Color.black.opacity(state.bgOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: state.isExpanded ? 24 : 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [state.accentColor.opacity(0.25), Color.white.opacity(0.04)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.8
                            )
                    )
                    .shadow(color: Color.black.opacity(state.isExpanded ? 0.65 : 0.25), radius: state.isExpanded ? 18 : 6, y: 3)
                
                if state.isExpanded {
                    expandedView
                        .opacity(state.isExpanded ? 1 : 0)
                        .animation(.easeOut(duration: 0.06), value: state.isExpanded)
                } else {
                    compactView
                        .opacity(state.isExpanded ? 0 : 1)
                        .animation(.easeIn(duration: 0.08), value: state.isExpanded)
                }
            }
            .frame(
                width: state.isExpanded ? state.expandedW : state.compactW,
                height: state.isExpanded ? state.expandedH : state.compactH
            )
            .clipped()
            .animation(.spring(response: 0.32, dampingFraction: 0.76), value: state.isExpanded)
            .onHover { hover in
                state.isExpanded = hover
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    var compactView: some View {
        let roundedFont = NSFont.systemFont(ofSize: 11, weight: .medium)
        return HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 18, height: 18)
                
                if let art = state.artwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 18, height: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .id(state.lastIdentifier)
                        .transition(.opacity.animation(.easeInOut(duration: 0.18)))
                } else {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(state.accentColor.opacity(0.85))
                }
            }
            .frame(width: 18, height: 18)
            
            GhostMarqueeText(
                text: "\(state.trackTitle)  •  \(state.trackArtist)",
                font: .system(size: 11, weight: .medium, design: .rounded),
                nsFont: roundedFont,
                color: .white,
                width: 146
            )
            .id(state.trackTitle + state.trackArtist)
            .transition(.opacity.animation(.easeInOut(duration: 0.18)))
            
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(state.accentColor.opacity(0.85))
                .frame(width: 18, height: 18)
        }        .padding(.horizontal, 10)
    }
    
    var expandedView: some View {
        let boldFont = NSFont.systemFont(ofSize: 13, weight: .bold)
        let medFont = NSFont.systemFont(ofSize: 11, weight: .medium)
        
        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 92, height: 92)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                
                if let art = state.artwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 92, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 8, y: 4)
                        .id(state.lastIdentifier)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                } else {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(state.accentColor.opacity(0.8))
                }
            }
            .frame(width: 92, height: 92)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        GhostMarqueeText(
                            text: state.trackTitle,
                            font: .system(size: 13, weight: .bold, design: .rounded),
                            nsFont: boldFont,
                            color: .white,
                            width: 140
                        )
                        GhostMarqueeText(
                            text: state.trackArtist + (state.appSource == "System" ? "" : "  •  " + state.appSource),
                            font: .system(size: 11, weight: .medium, design: .rounded),
                            nsFont: medFont,
                            color: Color.gray.opacity(0.85),
                            width: 140
                        )
                    }
                    .id(state.trackTitle + state.trackArtist)
                    .transition(.opacity.animation(.easeInOut(duration: 0.18)))
                    
                    Spacer(minLength: 0)
                    DynamicVolumeSlider(state: state)
                }
                .padding(.top, 1)
                
                VStack(spacing: 2) {
                    DynamicScrubber(state: state)
                    
                    HStack {
                        Text(fmtTime(state.trackPos))
                            .font(.system(size: 8.5, weight: .medium, design: .rounded).monospacedDigit())
                            .foregroundColor(state.accentColor.opacity(0.6))
                        Spacer()
                        Text("-\(fmtTime(max(0, state.trackDur - state.trackPos)))")
                            .font(.system(size: 8.5, weight: .medium, design: .rounded).monospacedDigit())
                            .foregroundColor(Color.gray.opacity(0.8))
                    }
                }
                
                HStack(spacing: 42) {
                    Spacer()
                    Button(action: { state.mediaPrev() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(state.accentColor.opacity(0.9))
                    }.buttonStyle(.plain)
                    
                    Button(action: { state.mediaPlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(state.accentColor.opacity(0.16))
                                .frame(width: 34, height: 34)
                            Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(state.accentColor)
                        }
                    }.buttonStyle(.plain)
                    
                    Button(action: { state.mediaNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(state.accentColor.opacity(0.9))
                    }.buttonStyle(.plain)
                    Spacer()
                }
            }
        }
        .padding(14)
    }
    
    func fmtTime(_ s: Double) -> String {
        let sec = Int(s)
        return String(format: "%d:%02d", sec / 60, sec % 60)
    }
}

struct SettingsView: View {
    @ObservedObject var state: IslandState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(state.accentColor)
                Text("DynamicNotch")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(state.accentColor)
                Spacer()
                Text("Zot says hi")
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(state.accentColor.opacity(0.6))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Launch at Login")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.85))
                    Spacer()
                    Button(action: { state.toggleLogin() }) {
                        ZStack(alignment: state.launchAtLogin ? .trailing : .leading) {
                            Capsule()
                                .fill(state.launchAtLogin ? state.accentColor : Color.white.opacity(0.12))
                                .frame(width: 28, height: 16)
                            Circle()
                                .fill(state.launchAtLogin ? Color.black : Color.white)
                                .frame(width: 12, height: 12)
                                .padding(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Glass Opacity")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.85))
                    Spacer()
                    Text("\(Int(state.bgOpacity * 100))%")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundColor(state.accentColor)
                }
                SettingsGlassSlider(state: state)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Accent Tone")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.gray.opacity(0.85))
                
                HStack(spacing: 9) {
                    chip("White", .white)
                    chip("Orange", Color(red: 1.0, green: 0.58, blue: 0.0))
                    chip("Purple", Color(red: 0.72, green: 0.35, blue: 0.98))
                    chip("Blue", Color(red: 0.18, green: 0.56, blue: 0.98))
                    chip("Pink", Color(red: 1.0, green: 0.22, blue: 0.48))
                    chip("Green", Color(red: 0.22, green: 0.82, blue: 0.44))
                }
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack {
                    Spacer()
                    Image(systemName: "power")
                        .font(.system(size: 10, weight: .bold))
                    Text("Quit DynamicNotch")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    Spacer()
                }
                .foregroundColor(Color.red.opacity(0.9))
                .padding(.vertical, 7)
                .background(Color.red.opacity(0.12))
                .cornerRadius(7)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.red.opacity(0.24), lineWidth: 0.75)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 240)
        .background(
            ZStack {
                Color.black.opacity(0.96)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [state.accentColor.opacity(0.2), Color.white.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
            }
        )
    }
    
    func chip(_ name: String, _ c: Color) -> some View {
        let isSel = state.accentName == name
        return Circle()
            .fill(c)
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: isSel ? 1.6 : 0)
                    .padding(-2)
            )
            .onTapGesture { state.accentName = name }
    }
}

final class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: false)
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.hidesOnDeactivate = false
        self.isReleasedWhenClosed = false
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    var panel: FloatingPanel!
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var state = IslandState()
    
    func applicationDidFinishLaunching(_ a: Notification) {
        AppDelegate.shared = self
        DynamicNotchStorage.prepare()
        if let appIcon = DynamicNotchStorage.logoImage() {
            NSApplication.shared.applicationIconImage = appIcon
        }
        positionPanel()
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.positionPanel()
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            if let source = DynamicNotchStorage.logoImage(),
               let menuIcon = source.copy() as? NSImage {
                menuIcon.size = NSSize(width: 18, height: 18)
                menuIcon.isTemplate = false
                btn.image = menuIcon
            } else {
                btn.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "DynamicNotch Settings")
            }
            btn.imagePosition = .imageOnly
            btn.action = #selector(togglePopover)
            btn.target = self
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 240, height: 215)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: SettingsView(state: state))
    }
    
    func positionPanel() {
        guard let s = NSScreen.screens.first else { return }
        let winW: CGFloat = 460
        let winH: CGFloat = 170
        let x = s.frame.minX + (s.frame.width - winW) / 2
        let y = s.frame.maxY - winH
        
        if panel == nil {
            panel = FloatingPanel(contentRect: NSRect(x: x, y: y, width: winW, height: winH))
            state.panel = panel
            panel.contentView = NSHostingView(rootView: IslandRootView(state: state))
            panel.orderFrontRegardless()
        } else {
            panel.setFrame(NSRect(x: x, y: y, width: winW, height: winH), display: true)
        }
    }
    
    @objc func togglePopover() {
        if let btn = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: btn.bounds, of: btn, preferredEdge: .minY)
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()