//
//  AudioManager.swift
//  Music
//
//  Created by Casey Dow on 8/31/24.
//

import Foundation
import AVFoundation
import SwiftUI

class AudioModel: ObservableObject {
    
    @Published public private(set) var data: [String: [String: [String: RxMusicPlayerItem]]] = [:]
    @Published public private(set) var playlists: [String : [RxMusicPlayerItem]] = [:]

    init() {
        var playlistCodes: [String:[String]] = [:]
        
        if let data = try? Data(contentsOf: getDocumentsDirectory().appendingPathComponent("playlists.json")) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([String:[String]].self, from: data) {
                playlistCodes = decoded
                decoded[""]?.forEach{playlists[$0] = []}
            }
        }

        if let data = try? Data(contentsOf: getDocumentsDirectory().appendingPathComponent("songs.json")) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([String].self, from: data) {
                decoded
                    .map{ getDocumentsDirectory().appendingPathComponent("Audio/\($0)") }
                    .forEach { saveSong($0, codes: playlistCodes) }
            }
        }
    }
    
    public func saveSong(_ url: URL, upload copy: Bool = false, playlist: String? = nil, codes playlistCodes: [String: [String]] = [:]) {
        Task {
            var newUrl = url
            if copy {
                newUrl = uploadSong(url)
            }
            let item = await RxMusicPlayerItem(url: newUrl)
            await MainActor.run {
                data[item.getArtist(), default: [:]][item.getAlbum(), default: [:]][item.url.lastPathComponent] = item
                if copy {
                    saveSongs()
                }
                if let playlist = playlist {
                    addToPlaylist(playlist, item: item)
                }
                playlistCodes[item.url.lastPathComponent]?.forEach { addToPlaylist($0, item: item) }
            }
        }
    }
    
    private func uploadSong(_ url: URL) -> URL {
        let fileManager = FileManager.default
        var newURL: URL = url
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        do {
            var counter = 0
            while fileManager.fileExists(atPath: newURL.path) {
                newURL = getDocumentsDirectory().appendingPathComponent("Audio/\(name)_\(counter).\(ext)")
                counter += 1
            }
            try fileManager.createDirectory(at: newURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileManager.copyItem(at: url, to: newURL)
        } catch {
            print("Error uploading music: \(error)")
        }
        return newURL
    }
    
    public func delete(item: RxMusicPlayerItem) {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: item.url)
        data[item.getArtist()]?[item.getAlbum()]?.removeValue(forKey: item.url.lastPathComponent)
        saveSongs()
        playlists.forEach { playlists[$0.key] = $0.value.filter { $0.url != item.url } }
        savePlaylists()
    }
    
    private func saveSongs() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(data.flatMap{$0.value}.flatMap{$0.value}.compactMap{$0.value}.map{$0.url.lastPathComponent}) {
            let url = getDocumentsDirectory().appendingPathComponent("songs.json")
            try? encodedData.write(to: url)
        }
    }
    
    private func sort(_ songs: [RxMusicPlayerItem]) -> [RxMusicPlayerItem] {
        return songs.sorted {
            if $0.getArtist() != $1.getArtist() {
                return $0.getArtist() < $1.getArtist()
            } else if $0.getAlbum() != $1.getAlbum() {
                return $0.getAlbum() < $1.getAlbum()
            } else {
                return $0.getTitle() < $1.getTitle()
            }
        }
    }
    
    public func getSongs(artist: String? = nil, album: String? = nil, playlist: String? = nil) -> [RxMusicPlayerItem] {
        if let playlist = playlist {
            return sort(playlists[playlist]?.filter {
                (artist == nil || $0.getArtist() == artist) &&
                (album == nil || $0.getAlbum() == album)
            } ?? [])
        }
        if let artist = artist {
            if let album = album {
                return sort(data[artist]?[album]?.compactMap { $0.value } ?? [])
            }
            return sort(data[artist]?.flatMap { $0.value }.compactMap { $0.value } ?? [])
        }

        return sort(data.flatMap { $0.value }.flatMap { $0.value }.compactMap { $0.value })
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
        
    public func createPlaylist(_ name: String) {
        playlists[name + UUID().uuidString + ".playlist"] = []
        savePlaylists()
    }
    
    public func createFolder(_ name: String) {
        playlists[name + UUID().uuidString] = []
        savePlaylists()
    }
    
    public func getPlaylists(path: String) -> [[String]] {
        var out: [[String]] = [[], []]
        playlists.keys.forEach {
            if $0.hasPrefix(path) {
                let remainder = String($0.dropFirst(path.count))
                if remainder.hasSuffix(".playlist") && !remainder.contains("/") {
                    out[1].append(String(remainder.dropLast(9)))
                } else {
                    let range = remainder.firstIndex(of: "/") ?? remainder.endIndex
                    let name = "\(String(remainder[..<range]))/"
                    if !out[0].contains(name) {
                        out[0].append(name)
                    }
                }
            }
        }
        
        return out
    }
        
    public func takeOut(_ name: String, path: String) {
        if name.hasSuffix("/"), let value = playlists.removeValue(forKey: path + name.dropLast()) {
            playlists[path.split(separator: "/").dropLast().joined(separator: "/") + name.dropLast()] = value
        }
        for (key, value) in playlists where key.hasPrefix(path + name) {
            if let range = key.range(of: path + name) {
                playlists[key.replacingCharacters(in: range, with: path.split(separator: "/").dropLast().joined(separator: "/") + name)] = value
                playlists.removeValue(forKey: key)
            }
        }
        savePlaylists()
    }
    
    public func deleteFolder(_ name: String, path: String) {
        for (key, value) in playlists where key.hasPrefix(path + name) {
            if let range = key.range(of: path + name) {
                playlists[key.replacingCharacters(in: range, with: path)] = value
                playlists.removeValue(forKey: key)
            }
        }
        playlists.removeValue(forKey: String(name.dropLast()))
        savePlaylists()
    }
    
    public func deletePlaylist(_ name: String, path: String) {
        playlists.removeValue(forKey: path + name + ".playlist")
        savePlaylists()
    }
    
    public func addToPlaylist(_ name: String, item: RxMusicPlayerItem) {
        if !playlists[name, default: []].contains(item) {
            playlists[name, default: []].append(item)
            savePlaylists()
        }
    }
    
    public func removeFromPlaylist(_ name: String, item: RxMusicPlayerItem) {
        if let index = playlists[name]?.firstIndex(of: item) {
            playlists[name]!.remove(at: index)
        }
        savePlaylists()
    }
    
    public func renameFolder(from name: String, to newName: String, path: String) {
        let uuid = UUID().uuidString
        for (key, value) in playlists {
            if let range = key.range(of: path + name) {
                playlists[key.replacingCharacters(in: range, with: path + newName + uuid + "/")] = value
                playlists.removeValue(forKey: key)
            }
        }
        if let entry = playlists.removeValue(forKey: path + name.dropLast()) {
            playlists[path + newName + uuid] = entry
            savePlaylists()
        }
    }
    
    public func renamePlaylist(from name: String, to newName: String) {
        if let entry = playlists.removeValue(forKey: name + ".playlist") {
            playlists[newName + UUID().uuidString + ".playlist"] = entry
            savePlaylists()
        }
    }
    
    private func savePlaylists() {
        let transformedDict = playlists.reduce(into: [String: [String]]()) { result, entry in
            let (name, items) = entry
            if items.count == 0 {
                result["", default: []].append(name)
            }
            items.forEach{ result[$0.url.lastPathComponent, default: []].append(name) }
        }

        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(transformedDict) {
            let url = getDocumentsDirectory().appendingPathComponent("playlists.json")
            try? encodedData.write(to: url)
        }
    }

}
