//
//  FloatingPlayerView.swift
//  Music
//
//  Created by Casey Dow on 9/1/24.
//

import Foundation
import SwiftUI

struct FloatingMusicPlayer: View {
    @EnvironmentObject var model: PlayerModel

    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                model.artwork
                    .resizable()
                    .frame(width: 50, height: 50)
                    .cornerRadius(10)
                Text(model.title)
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.leading, 10)
                Spacer()
                HStack(spacing: 20) {
                    Button(action: model.playPrevious, label: {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .frame(width: 20, height: 15)
                            .foregroundStyle(Color("App.Color.black"))
                    })
                    Button(action: model.playPause, label: {
                        Image(systemName: model.canPlay ? "play.fill" : "pause.fill")
                            .resizable()
                            .frame(width: 17, height: 17)
                            .foregroundStyle(Color("App.Color.black"))
                    })
                    Button(action: model.playNext, label: {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .frame(width: 20, height: 15)
                            .foregroundStyle(Color("App.Color.black"))
                    })
                }
                .padding(.trailing, 20)
            }
            .padding(10)
            .background(Color("App.Color.white"))
            .contentShape(Rectangle())
            .cornerRadius(15)
            .shadow(radius: 10)
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
        .padding(10)
        .sheet(isPresented: $isExpanded) {
            PlayerView()
        }
    }
}
