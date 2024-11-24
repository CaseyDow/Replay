//
//  SongView.swift
//  Music
//
//  Created by Casey Dow on 9/5/24.
//

import Foundation
import SwiftUI

struct SongView: View {
    @EnvironmentObject var model: PlayerModel
    @EnvironmentObject var audio: AudioModel

    let song: RxMusicPlayerItem
    @Binding var isEditing: Bool
    let playlist: String?

    var body: some View {
        HStack {
            song.getArtwork()
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.trailing, 3)
            VStack(alignment: .listRowSeparatorLeading) {
                Text(song.getTitle())
                    .font(.headline)
                Text(song.getArtist())
                    .font(.subheadline)
                    .foregroundStyle(Color("App.Color.darkgray"))
            }
            .frame(height: 35)
            Spacer()
        }
        .contentShape(Rectangle())
        .allowsHitTesting(!isEditing)
        .onTapGesture {
            model.start(items: [song])
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive, action: {
                if let playlist = playlist {
                    audio.removeFromPlaylist(playlist, item: song)
                } else {
                    audio.delete(item: song)
                    model.remove(item: song)
                }
            }) {
                Label("Delete Songs", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            HStack {
                Button(action: {
                    model.frontQueue(items: [song])
                }) {
                    Label("Play Next", systemImage: "text.insert")
                }
                .tint(.blue)
                Button(action: {
                    model.queue(items: [song])
                }) {
                    Label("Play Last", systemImage: "text.append")
                }
                .tint(.red)
            }
        }
    }
}
