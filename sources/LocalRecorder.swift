//
//  LocalRecorder.swift
//  Squirrel
//
//  Created by YourMemory Agent on 2/12/26.
//

import Foundation

final class LocalRecorder {
    static let shared = LocalRecorder()
    
    private let queue = DispatchQueue(label: "org.rime.squirrel.LocalRecorder", qos: .background)
    private var logFileURL: URL?
    
    private init() {
        let baseDir = SquirrelApp.userDir.appendingPathComponent("input_log", isDirectory: true)
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: baseDir.path) {
            do {
                try fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true)
            } catch {
                print("LocalRecorder: Error creating directory: \(error)")
            }
        }
        
        logFileURL = baseDir.appendingPathComponent("records.jsonl")
    }
    
    func record(text: String, source: String) {
        guard !text.isEmpty else { return }
        
        queue.async { [weak self] in
            guard let self = self, let url = self.logFileURL else { return }
            
            let timestamp = Int(Date().timeIntervalSince1970)
            let entry: [String: Any] = [
                "ts": timestamp,
                "source": source,
                "text": text
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: entry, options: [])
                guard var jsonString = String(data: jsonData, encoding: .utf8) else { return }
                jsonString += "\n"
                
                if let data = jsonString.data(using: .utf8) {
                    if FileManager.default.fileExists(atPath: url.path) {
                        if let fileHandle = try? FileHandle(forWritingTo: url) {
                            fileHandle.seekToEndOfFile()
                            fileHandle.write(data)
                            fileHandle.closeFile()
                        }
                    } else {
                        try data.write(to: url, options: .atomic)
                    }
                }
            } catch {
                print("LocalRecorder: Error writing to log: \(error)")
            }
        }
    }
}
