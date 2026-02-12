//
//  DesignatedRecorder.swift
//  Squirrel
//
//  Created by YourMemory Agent on 2/12/26.
//

import AppKit
import Carbon

final class DesignatedRecorder {
    static let shared = DesignatedRecorder()
    
    // For simplicity in this agent environment, we'll use a local event monitor.
    // In a real application, Carbon HotKeys or addGlobalMonitorForEvents would be used.
    private var eventMonitor: Any?
    
    func start() {
        // Monitor for Command+Shift+S
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.charactersIgnoringModifiers == "S" {
                self?.performCapture()
            }
        }
    }
    
    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func performCapture() {
        // Preferred: Accessibility API (AX)
        if let selectedText = getSelectedTextViaAX() {
            LocalRecorder.shared.record(text: selectedText, source: "designate")
        } else {
            // Fallback: Clipboard simulation
            captureViaClipboard()
        }
    }
    
    private func getSelectedTextViaAX() -> String? {
        // This is a simplified AX extraction. Requires Accessibility permissions.
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if result == .success, let element = focusedElement as! AXUIElement? {
            var selectedText: AnyObject?
            let textResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
            if textResult == .success, let text = selectedText as? String {
                return text
            }
        }
        return nil
    }
    
    private func captureViaClipboard() {
        let oldPasteboardCount = NSPasteboard.general.changeCount
        
        // Simulate Cmd+C
        let source = CGEventSource(stateID: .combinedSessionState)
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // 'c' key is 0x08
        cDown?.flags = .maskCommand
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cUp?.flags = .maskCommand
        
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        
        // Wait a bit and check for changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if NSPasteboard.general.changeCount != oldPasteboardCount {
                if let content = NSPasteboard.general.string(forType: .string) {
                    LocalRecorder.shared.record(text: content, source: "designate")
                }
            }
        }
    }
}
