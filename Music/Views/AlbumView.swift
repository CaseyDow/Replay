//
//  AlbumView.swift
//  Music
//
//  Created by Casey Dow on 9/5/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct AlbumView: View {
    @EnvironmentObject var model: PlayerModel
    @EnvironmentObject var audio: AudioModel
    var artist: String

    var body: some View {
        List {
            NavigationLink(destination: SongsView(artist, artist: artist, album: nil), label: {
                Text("All")
            })

            ForEach(Array(audio.data[artist]!.keys).sorted(), id: \.self) { album in
                if audio.data[artist]![album] != [:] {
                    NavigationLink(destination: SongsView(album, artist: artist, album: album), label: {
                        Text(album)
                    })
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(artist)
    }
}
