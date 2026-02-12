//
//  PasteboardObserver.swift
//  Squirrel
//
//  Created by YourMemory Agent on 2/12/26.
//

import AppKit

final class PasteboardObserver {
    static let shared = PasteboardObserver()
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    
    func start() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkPasteboard() {
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            if let content = pasteboard.string(forType: .string) {
                LocalRecorder.shared.record(text: content, source: "paste")
            }
        }
    }
}
