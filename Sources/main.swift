import AppKit
import ScreenSaver
import ServiceManagement

final class DesktopWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class DesktopController: NSObject, NSApplicationDelegate {
    var windows: [DesktopWindow] = []
    var views: [CodeRainSaverView] = []
    var frameTimer: Timer?
    var status: NSStatusItem!
    var paused = false
    var sleeping = false
    var locked = false
    var efficient = true
    var observers: [NSObjectProtocol] = []
    var preview: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if NSRunningApplication.runningApplications(withBundleIdentifier: "com.djred.CodeRainDesktop").count > 1 {
            NSApp.terminate(nil); return
        }
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "雨"
        status.button?.toolTip = "CodeRainDesktop 1.0.0 • djred"
        rebuildMenu()
        rebuildDisplays()
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in self?.sleeping = true; self?.updateTimer() })
        observers.append(center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in self?.sleeping = true; self?.updateTimer() })
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in self?.sleeping = false; self?.updateTimer() })
        observers.append(center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in self?.sleeping = false; self?.updateTimer() })
        observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in self?.rebuildDisplays() })
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(lock), name: Notification.Name("com.apple.screenIsLocked"), object: nil)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(unlock), name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)
        if CommandLine.arguments.contains("--preview") { showPreview() }
    }

    func rebuildDisplays() {
        frameTimer?.invalidate()
        for v in views { v.stopAnimation() }
        for w in windows { w.orderOut(nil); w.close() }
        windows.removeAll(); views.removeAll()
        for screen in NSScreen.screens {
            let w = DesktopWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
            w.isReleasedWhenClosed = false
            w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            w.ignoresMouseEvents = true
            w.backgroundColor = .black
            w.isOpaque = true
            w.hasShadow = false
            guard let v = CodeRainSaverView(frame: NSRect(origin: .zero, size: screen.frame.size), isPreview: false) else { continue }
            w.contentView = v
            w.orderFrontRegardless()
            v.startAnimation()
            windows.append(w); views.append(v)
        }
        updateTimer()
    }

    func updateTimer() {
        frameTimer?.invalidate(); frameTimer = nil
        guard !paused && !sleeping && !locked else { return }
        let interval = efficient || ProcessInfo.processInfo.isLowPowerModeEnabled || ProcessInfo.processInfo.thermalState.rawValue >= 2 ? 1.0 / 30.0 : 1.0 / 60.0
        for v in views { v.desktopFrameInterval = interval }
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            for v in self.views { v.animateOneFrame() }
            if let v = self.preview?.contentView as? CodeRainSaverView { v.desktopFrameInterval = interval; v.animateOneFrame() }
        }
        timer.tolerance = interval * 0.15
        RunLoop.main.add(timer, forMode: .common)
        frameTimer = timer
    }

    func rebuildMenu() {
        let menu = NSMenu()
        let title = NSMenuItem(title: "CodeRainDesktop 1.0.0", action: nil, keyEquivalent: "")
        menu.addItem(title); menu.addItem(.separator())
        add(menu, paused ? "Resume Animation" : "Pause Animation", #selector(togglePause))
        add(menu, efficient ? "✓ Efficient • 30 fps" : "Smooth • 60 fps", #selector(toggleQuality))
        add(menu, "Rain Appearance…", #selector(appearance))
        add(menu, "Show Preview", #selector(showPreview))
        add(menu, SMAppService.mainApp.status == .enabled ? "✓ Launch at Login" : "Launch at Login", #selector(toggleLogin))
        menu.addItem(.separator())
        add(menu, "Quit and Restore Wallpaper", #selector(quit), "q")
        status.menu = menu
    }
    func add(_ menu: NSMenu, _ title: String, _ selector: Selector, _ key: String = "") {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: key); item.target = self; menu.addItem(item)
    }
    @objc func togglePause() { paused.toggle(); updateTimer(); rebuildMenu() }
    @objc func toggleQuality() { efficient.toggle(); updateTimer(); rebuildMenu() }
    @objc func lock() { locked = true; updateTimer() }
    @objc func unlock() { locked = false; updateTimer() }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func appearance() {
        guard let sheet = views.first?.configureSheet else { return }
        sheet.center(); sheet.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch { let alert = NSAlert(); alert.messageText = "Login startup could not be changed"; alert.informativeText = error.localizedDescription; alert.runModal() }
        rebuildMenu()
    }
    @objc func showPreview() {
        if preview == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            w.title = "CodeRainDesktop • Original 1.1.21 Rain • djred"
            w.isReleasedWhenClosed = false
            if let v = CodeRainSaverView(frame: NSRect(x: 0, y: 0, width: 1000, height: 600), isPreview: false) { w.contentView = v; v.startAnimation() }
            preview = w
        }
        preview?.center(); preview?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    func applicationWillTerminate(_ notification: Notification) { frameTimer?.invalidate(); for v in views { v.stopAnimation() } }
}
let app = NSApplication.shared
let controller = DesktopController()
app.delegate = controller
app.run()
