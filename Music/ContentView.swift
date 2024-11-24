//
//  ContentView.swift
//  Music
//
//  Created by Casey Dow on 8/31/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var model = PlayerModel()
    @StateObject private var audio = AudioModel()

    @State private var isExpanded: Bool = false
    @State private var isPlaying: Bool = false
    @State private var player: AVPlayer?
        
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    NavigationLink(destination: SongsView("Songs"), label: {
                        Label("All Songs", systemImage: "music.note")
                            .font(.title3)
                    }).padding(20)
                    NavigationLink(destination: ArtistView(), label: {
                        Label("Artists", systemImage: "music.mic")
                            .font(.title3)
                    }).padding(20)
                    NavigationLink(destination: PlaylistView(), label: {
                        Label("Playlists", systemImage: "music.note.list")
                            .font(.title3)
                    }).padding(20)
                }
                .listStyle(.plain)
                .navigationTitle("Music")
            }

            FloatingMusicPlayer()
        }
        .environmentObject(model)
        .environmentObject(audio)
    }
    
}
