//
//  ArtistView.swift
//  Music
//
//  Created by Casey Dow on 9/5/24.
//

import SwiftUI

struct ArtistView: View {
    @EnvironmentObject var model: PlayerModel
    @EnvironmentObject var audio: AudioModel

    var body: some View {
        List(Array(audio.data.keys).sorted(), id: \.self) { artist in
            if audio.data[artist] != [:] {
                NavigationLink(destination: AlbumView(artist: artist), label: {
                    Text(artist)
                })
            }
        }
        .listStyle(.plain)
        .navigationTitle("Artists")
    }
}
