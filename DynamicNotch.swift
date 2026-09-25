// DynamicNotch
// Created by ZXT
// Copyright (c) 2026 ZXT
// Licensed under the MIT License.
// Contact: contact@zxt.lol | Discord: 1531412914005606513

import Cocoa
import SwiftUI

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

final class IslandState: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published var selectedProvider: String = UserDefaults.standard.string(forKey: "dyn_provider") ?? "Music"
    
    @Published var trackTitle: String = "Not Playing"
    @Published var trackArtist: String = "Apple Music"
    @Published var isPlaying: Bool = false
    @Published var trackPos: Double = 0.0
    @Published var trackDur: Double = 1.0
    @Published var appVolume: Double = 75.0
    @Published var artwork: NSImage? = nil
    
    @Published var compactW: CGFloat = 224
    @Published var compactH: CGFloat = 32
    @Published var expandedW: CGFloat = 430
    @Published var expandedH: CGFloat = 145
    
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
    
    var syncToken: Int = 0
    var activeArtTask: URLSessionDataTask?
    var pendingDebounceWork: DispatchWorkItem?
    let mediaQueue = DispatchQueue(label: "com.notch.mediaQueue", qos: .userInitiated)
    
    var lastArtKey: String = ""
    var isSeeking: Bool = false
    var isChangingVol: Bool = false
    var isChangingOpacity: Bool = false
    var lastSyncDate: Date = Date()
    var artCache: [String: NSImage] = [:]
    var panel: NSPanel?
    
    init() {
        startNotificationObservers()
        startClockTicker()
        syncPlayer()
    }
    
    func startNotificationObservers() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(forName: NSNotification.Name("com.apple.Music.playerInfo"), object: nil, queue: .main) { [weak self] n in
            guard let self = self, self.selectedProvider == "Music" else { return }
            self.handleMusicNotif(n)
        }
        dnc.addObserver(forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"), object: nil, queue: .main) { [weak self] n in
            guard let self = self, self.selectedProvider == "Spotify" else { return }
            self.handleSpotifyNotif(n)
        }
    }
    
    func handleMusicNotif(_ n: Notification) {
        guard let info = n.userInfo else { return }
        let st = info["Player State"] as? String ?? ""
        isPlaying = (st == "Playing")
        let title = info["Name"] as? String ?? trackTitle
        let artist = info["Artist"] as? String ?? trackArtist
        if let d = info["Total Time"] as? Double { trackDur = max(d / 1000.0, 1.0) }
        updateMetadata(title: title, artist: artist, forceRescan: true)
    }
    
    func handleSpotifyNotif(_ n: Notification) {
        guard let info = n.userInfo else { return }
        let st = info["Player State"] as? String ?? ""
        isPlaying = (st == "Playing")
        let title = info["Name"] as? String ?? trackTitle
        let artist = info["Artist"] as? String ?? trackArtist
        if let d = info["Duration"] as? Double { trackDur = max(d / 1000.0, 1.0) }
        updateMetadata(title: title, artist: artist, forceRescan: true)
    }
    
    func updateMetadata(title: String, artist: String, forceRescan: Bool = false) {
        guard !title.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            trackTitle = title
            trackArtist = artist
        }
        let key = title + "|" + artist
        if key != lastArtKey || forceRescan {
            lastArtKey = key
            activeArtTask?.cancel()
            pendingDebounceWork?.cancel()
            
            if let cached = artCache[key] {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.artwork = cached
                }
            } else {
                rescanArtworkDirect(title: title, artist: artist)
            }
        }
    }
    
    func rescanArtworkDirect(title: String, artist: String) {
        let key = title + "|" + artist
        syncToken += 1
        let currentId = syncToken
        
        mediaQueue.async { [weak self] in
            guard let self = self else { return }
            let app = self.selectedProvider
            let sc: String
            if app == "Music" {
                let uniqueFile = "/tmp/dyn_art_\(arc4random()).jpg"
                sc = """
                if application "Music" is running then
                    tell application "Music"
                        try
                            if (count of artworks of current track) > 0 then
                                set d to raw data of artwork 1 of current track
                                set fp to open for access (POSIX file "\(uniqueFile)") with write permission
                                set eof fp to 0
                                write d to fp
                                close access fp
                                return "\(uniqueFile)"
                            end if
                        end try
                    end tell
                end if
                return ""
                """
            } else {
                sc = "if application \"Spotify\" is running then tell application \"Spotify\" to return artwork url of current track\nreturn \"\""
            }
            
            var err: NSDictionary?
            if let script = NSAppleScript(source: sc) {
                let res = script.executeAndReturnError(&err).stringValue ?? ""
                if !res.isEmpty {
                    if res.hasPrefix("/tmp/"), let data = try? Data(contentsOf: URL(fileURLWithPath: res)), let img = NSImage(data: data) {
                        try? FileManager.default.removeItem(atPath: res)
                        DispatchQueue.main.async {
                            guard currentId == self.syncToken else { return }
                            self.artCache[key] = img
                            withAnimation(.easeInOut(duration: 0.32)) { self.artwork = img }
                        }
                        return
                    } else if res.hasPrefix("http"), let u = URL(string: res) {
                        let task = URLSession.shared.dataTask(with: u) { [weak self] d, _, _ in
                            if let d = d, let img = NSImage(data: d) {
                                DispatchQueue.main.async {
                                    guard let self = self, currentId == self.syncToken else { return }
                                    self.artCache[key] = img
                                    withAnimation(.easeInOut(duration: 0.32)) { self.artwork = img }
                                }
                            }
                        }
                        self.activeArtTask = task
                        task.resume()
                        return
                    }
                }
            }
            self.fetchFallbackArtwork(title: title, artist: artist, token: currentId, key: key)
        }
    }
    
    func fetchFallbackArtwork(title: String, artist: String, token: Int, key: String) {
        let q = "\(title) \(artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let reqUrl = URL(string: "https://itunes.apple.com/search?term=\(q)&media=music&entity=song&limit=1") else { return }
        
        let task = URLSession.shared.dataTask(with: reqUrl) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first,
                  let rawUrl = first["artworkUrl100"] as? String else { return }
            let hdUrl = rawUrl.replacingOccurrences(of: "100x100bb", with: "600x600bb")
            if let u = URL(string: hdUrl) {
                let imgTask = URLSession.shared.dataTask(with: u) { [weak self] imgData, _, _ in
                    if let imgData = imgData, let img = NSImage(data: imgData) {
                        DispatchQueue.main.async {
                            guard let self = self, token == self.syncToken else { return }
                            self.artCache[key] = img
                            if self.lastArtKey == key {
                                withAnimation(.easeInOut(duration: 0.32)) { self.artwork = img }
                            }
                        }
                    }
                }
                self.activeArtTask = imgTask
                imgTask.resume()
            }
        }
        self.activeArtTask = task
        task.resume()
    }
    
    func startClockTicker() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isPlaying && !self.isSeeking {
                let el = Date().timeIntervalSince(self.lastSyncDate)
                self.trackPos = min(self.trackDur, self.trackPos + el)
                self.lastSyncDate = Date()
            }
        }
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying, !self.isSeeking else { return }
            self.syncPlayer()
        }
    }
    
    func syncPlayer() {
        syncToken += 1
        let currentId = syncToken
        mediaQueue.async { [weak self] in
            guard let self = self else { return }
            let app = self.selectedProvider
            let sc: String
            if app == "Spotify" {
                sc = """
                if application "Spotify" is running then
                    tell application "Spotify"
                        return (player state as string) & "|" & (name of current track) & "|" & (artist of current track) & "|" & (player position) & "|" & ((duration of current track) / 1000) & "|" & (sound volume)
                    end tell
                end if
                return "stopped|||0|1|0"
                """
            } else {
                sc = """
                if application "Music" is running then
                    tell application "Music"
                        return (player state as string) & "|" & (name of current track) & "|" & (artist of current track) & "|" & (player position) & "|" & (duration of current track) & "|" & (sound volume)
                    end tell
                end if
                return "stopped|||0|1|0"
                """
            }
            var err: NSDictionary?
            if let script = NSAppleScript(source: sc) {
                let out = script.executeAndReturnError(&err).stringValue ?? ""
                let p = out.components(separatedBy: "|")
                if p.count >= 6 {
                    let playing = (p[0] == "playing" || p[0] == "kPSP")
                    let title = p[1].isEmpty ? "Not Playing" : p[1]
                    let artist = p[2].isEmpty ? (self.selectedProvider == "Music" ? "Apple Music" : "Spotify") : p[2]
                    let pos = Double(p[3]) ?? 0.0
                    let dur = max(Double(p[4]) ?? 1.0, 1.0)
                    let vol = Double(p[5]) ?? self.appVolume
                    
                    DispatchQueue.main.async {
                        guard currentId == self.syncToken else { return }
                        self.isPlaying = playing
                        self.trackDur = dur
                        if !self.isSeeking {
                            self.trackPos = pos
                            self.lastSyncDate = Date()
                        }
                        if !self.isChangingVol { self.appVolume = vol }
                        self.updateMetadata(title: title, artist: artist, forceRescan: false)
                    }
                }
            }
        }
    }
    
    func mediaCmd(_ cmd: String) {
        syncToken += 1
        activeArtTask?.cancel()
        pendingDebounceWork?.cancel()
        lastSyncDate = Date()
        mediaQueue.async { [weak self] in
            guard let self = self else { return }
            let app = self.selectedProvider
            let sc = "if application \"\(app)\" is running then tell application \"\(app)\" to \(cmd)"
            var err: NSDictionary?
            NSAppleScript(source: sc)?.executeAndReturnError(&err)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.syncPlayer()
            }
        }
    }
    
    func seek(to s: Double) {
        let app = self.selectedProvider
        mediaQueue.async {
            let sc = "if application \"\(app)\" is running then tell application \"\(app)\" to set player position to \(s)"
            var err: NSDictionary?
            NSAppleScript(source: sc)?.executeAndReturnError(&err)
        }
    }
    
    func setVolume(to v: Double) {
        let app = self.selectedProvider
        mediaQueue.async {
            let sc = "if application \"\(app)\" is running then tell application \"\(app)\" to set sound volume to \(Int(v))"
            var err: NSDictionary?
            NSAppleScript(source: sc)?.executeAndReturnError(&err)
        }
    }
}

func calcMarquee(time: Double, overflow: CGFloat) -> (shift: CGFloat, alpha: Double) {
    let speed: Double = 26.0
    let scrollDur = Double(overflow) / speed
    let startHold = 2.4
    let endHold = 1.8
    let rewindDur = 0.35
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
        let ghost = 0.35 + 0.65 * (r < 0.5 ? (1.0 - r * 2.0) : ((r - 0.5) * 2.0))
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
                        state.lastSyncDate = Date()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
                        state.isChangingVol = true
                        let pct = Double(max(0, min(val.location.x / 58.0, 1.0)))
                        state.appVolume = pct * 100.0
                        state.setVolume(to: state.appVolume)
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
                        state.isChangingOpacity = true
                        let pct = Double(max(0, min(val.location.x / w, 1.0)))
                        state.bgOpacity = 0.2 + (pct * 0.8)
                    }
                    .onEnded { _ in
                        state.isChangingOpacity = false
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
                        .id(state.lastArtKey)
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
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
            
            Group {
                if state.selectedProvider == "Spotify" {
                    SpotifyBrandLogo(size: 14)
                } else {
                    Image(systemName: "applelogo")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(state.accentColor.opacity(0.85))
                }
            }
            .frame(width: 18, height: 18)
        }
        .padding(.horizontal, 10)
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
                        .id(state.lastArtKey)
                        .transition(.opacity.animation(.easeInOut(duration: 0.32)))
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
                            text: state.trackArtist,
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
                    Button(action: { state.mediaCmd("previous track") }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(state.accentColor.opacity(0.9))
                    }.buttonStyle(.plain)
                    
                    Button(action: { state.mediaCmd("playpause") }) {
                        ZStack {
                            Circle()
                                .fill(state.accentColor.opacity(0.16))
                                .frame(width: 34, height: 34)
                            Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(state.accentColor)
                        }
                    }.buttonStyle(.plain)
                    
                    Button(action: { state.mediaCmd("next track") }) {
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
                Text("Settings")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(state.accentColor)
                Spacer()
                Circle()
                    .fill(state.accentColor.opacity(0.2))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(state.accentColor)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Music Provider")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.gray.opacity(0.85))
                
                HStack(spacing: 8) {
                    providerButton("Apple Music", "Music", isSpotify: false)
                    providerButton("Spotify", "Spotify", isSpotify: true)
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
    
    func providerButton(_ label: String, _ prov: String, isSpotify: Bool) -> some View {
        let isSel = state.selectedProvider == prov
        return Button(action: {
            state.selectedProvider = prov
            UserDefaults.standard.set(prov, forKey: "dyn_provider")
            state.syncPlayer()
        }) {
            HStack(spacing: 6) {
                if isSpotify {
                    SpotifyBrandLogo(size: 12)
                } else {
                    Image(systemName: "applelogo")
                        .font(.system(size: 9.5, weight: .bold))
                }
                Text(label)
                    .font(.system(size: 9.5, weight: isSel ? .bold : .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(isSel ? state.accentColor.opacity(0.2) : Color.white.opacity(0.05))
            .foregroundColor(isSel ? state.accentColor : Color.gray)
            .cornerRadius(7)
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(isSel ? state.accentColor.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
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
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel!
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var state = IslandState()
    
    func applicationDidFinishLaunching(_ a: Notification) {
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
            btn.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "Notch Settings")
            btn.action = #selector(togglePopover)
            btn.target = self
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 240, height: 260)
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
