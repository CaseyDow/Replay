//
//  RxMusicPlayerItem.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
import RxCocoa
import RxSwift
import SwiftUI

open class RxMusicPlayerItem: NSObject {
    /**
     Metadata for player item.
     */
    public struct Meta {
        var duration: CMTime?
        var lyrics: String?
        var title: String?
        var album: String?
        var artist: String?
        var artwork: UIImage?

        let didAllSetRelay = BehaviorRelay<Bool>(value: false)

        /**
         Initialize Metadata with a prefetched one.
         If skipDownloading is true, the player will use the given parameters, instead of downloading the metadata.
         Otherwise, the player will download the metadata, and then use the given parameters as default values.
         */
        public init(duration: CMTime? = nil,
                    lyrics: String? = nil,
                    title: String? = nil,
                    album: String? = nil,
                    artist: String? = nil,
                    artwork: UIImage? = nil,
                    skipDownloading: Bool = false) {
            self.duration = duration
            self.lyrics = lyrics
            self.title = title
            self.album = album
            self.artist = artist
            self.artwork = artwork

            if skipDownloading {
                didAllSetRelay.accept(true)
            }
        }

        fileprivate mutating func set(metaItem item: AVMetadataItem) async throws {
            guard let commonKey = item.commonKey else { return }
            
            switch commonKey.rawValue {
            case "title": title = try await item.load(.stringValue)
            case "albumName": album = try await item.load(.stringValue)
            case "artist": artist = try await item.load(.stringValue)
            case "artwork": try await processArtwork(fromMetadataItem: item)
            default: break
            }
        }

        private mutating func processArtwork(fromMetadataItem item: AVMetadataItem) async throws {
            guard let value = try await item.load(.value) else { return }
            let copiedValue: AnyObject = value.copy(with: nil) as AnyObject

            if let dict = copiedValue as? [AnyHashable: Any] {
                // AVMetadataKeySpaceID3
                if let imageData = dict["data"] as? Data {
                    artwork = UIImage(data: imageData)
                }
            } else if let data = copiedValue as? Data {
                // AVMetadataKeySpaceiTunes
                artwork = UIImage(data: data)
            }
        }
    }

    public let url: Foundation.URL

    var meta: Meta
    var playerItem: AVPlayerItem?
    private let asset: AVAsset

    /**
     Create an instance with an URL and local title

     - parameter url: local or remote URL of the audio file
     - parameter meta: prefetched metadata of the audio

     - returns: RxMusicPlayerItem instance
     */
    public required init(url: Foundation.URL, meta: Meta = Meta()) async {
        self.meta = meta
        self.url = url
        asset = AVAsset(url: url)

        super.init()

        do {
            try await loadMetadata()
        } catch {
            print("Failed to load Metadata: \(error)")
        }
    }

    private func loadMetadata() async throws {
        let metadataItems = try await asset.load(.commonMetadata)

        for item in metadataItems {
            try? await self.meta.set(metaItem: item)
        }

        // Load duration
        self.meta.duration = try? await asset.load(.duration)
        self.meta.lyrics = try? await asset.load(.lyrics)

        // Load lyrics
        self.meta.didAllSetRelay.accept(true)
    }

    func loadPlayerItem() -> Single<RxMusicPlayerItem?> {
        self.playerItem = AVPlayerItem(asset: asset)
        return .just(self)
    }
    
    public func getArtwork() -> Image {
        if meta.artwork != nil {
            return Image(uiImage: meta.artwork!)
        }
        return Image("unknown-song")
    }
    
    public func getArtist() -> String {
        return meta.artist ?? "Unknown Artist"
    }
    
    public func getAlbum() -> String {
        return meta.album ?? "Unknown Album"
    }
    
    public func getTitle() -> String {
        return meta.title ?? "Unknown Song"
    }
}
