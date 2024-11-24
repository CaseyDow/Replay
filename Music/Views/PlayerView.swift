//
//  PlayerView.swift
//  Music
//
//  Created by Casey Dow on 8/31/24.
//

import Foundation
import SwiftUI
import AVFoundation
import RxSwift

struct PlayerView: View {
    @EnvironmentObject var model: PlayerModel
    
    @State private var isDragging = false
    @State private var sliderValue: Double = 0.0
    @State private var animateTitle = false

    var body: some View {
        ZStack {
            model.artwork
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0)
                .ignoresSafeArea(.all)
            Blur(style: .dark)
                .scaledToFill()
                .frame(minWidth: 0)
                .ignoresSafeArea(.all)
            VStack {
                Spacer(minLength: 50)
                model.artwork
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200, alignment: .center)
                    .clipped().cornerRadius(20).shadow(radius: 10).padding(20)
                HStack {
                    VStack(alignment: .leading) {
                        TitleView(text: model.title)

                        Text(model.artist)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                ProgressSliderView(value: $model.sliderValue,
                                   maximumValue: $model.sliderMaximumValue,
                                   isUserInteractionEnabled: $model.sliderIsUserInteractionEnabled,
                                   playableProgress: $model.sliderPlayableProgress) {
                    model.sliderValueChanged.send($0)
                }
                .padding(.horizontal)

                HStack {
                    Text(model.duration)
                    Spacer()
                    Text(model.restDuration)
                }
                .foregroundStyle(.white)
                .padding(.horizontal)
                
                HStack {
                    Spacer()
                    Button(action: model.playPrevious, label: {
                        Image(systemName: "backward.fill").resizable()
                    })
                    .frame(width: 40, height: 30, alignment: .center)
                    .foregroundStyle(Color.white)
                    Spacer()
                    Button(action: model.playPause, label: {
                        Image(systemName: model.canPlay ? "play.fill" : "pause.fill").resizable()
                    })
                    .frame(width: 35, height: 35, alignment: .center)
                    .foregroundStyle(Color.white)
                    Spacer()
                    Button(action: model.playNext, label: {
                        Image(systemName: "forward.fill").resizable()
                    })
                    .frame(width: 40, height: 30, alignment: .center)
                    .foregroundStyle(Color.white)
                    Spacer()
                }
                .padding(20)

                HStack {
                    Text("Queue")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                    Spacer()
                    
                    Button(action: {
                        model.shuffle()
                    }) {
                        switch model.shuffleMode {
                        case .off:
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundStyle(.white.opacity(0))
                                    .frame(width: 30, height: 25, alignment: .center)
                                Image(systemName: "shuffle")
                                    .resizable()
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(width: 17, height: 17, alignment: .center)
                            }
                        case .songs:
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(width: 30, height: 25, alignment: .center)
                                Image(systemName: "shuffle")
                                    .resizable()
                                    .blendMode(.destinationOut)
                                    .frame(width: 17, height: 17, alignment: .center)
                            }
                        }
                    }


                    Button(action: {
                        model.doRepeat()
                    }) {
                        switch model.repeatMode {
                        case .none:
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundStyle(.white.opacity(0))
                                    .frame(width: 30, height: 25, alignment: .center)
                                Image(systemName: "repeat")
                                    .resizable()
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(width: 17, height: 17, alignment: .center)
                            }
                        case .all:
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(width: 30, height: 25, alignment: .center)
                                Image(systemName: "repeat")
                                    .resizable()
                                    .blendMode(.destinationOut)
                                    .frame(width: 17, height: 17, alignment: .center)
                            }
                        case .one:
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(width: 30, height: 25, alignment: .center)
                                Image(systemName: "repeat.1")
                                    .resizable()
                                    .blendMode(.destinationOut)
                                    .frame(width: 17, height: 17, alignment: .center)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                List(model.player.queuedItems.indices.suffix(from: min(model.player.playIndex + 1,model.player.queuedItems.count)), id: \.self) { index in
                    HStack {
                        model.player.queuedItems[index].getArtwork()
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        VStack(alignment: .leading) {
                            Text(model.player.queuedItems[index].meta.title ?? "Unknown Song")
                                .foregroundStyle(.white.opacity(0.8))
                                .font(.subheadline)
                                .lineLimit(1)
                                .bold()
                            Text(model.player.queuedItems[index].meta.artist ?? "Unknown Artist")
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                                .font(.caption)
                        }
                        Spacer()
                        Text(model.player.queuedItems[index].meta.duration?.displayTime ?? "0:0")
                            .foregroundStyle(.white)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.pause()
                        model.playAt(at: index)
                    }
                    .listRowBackground(Color.white.opacity(0))
                }
                .listStyle(.plain)
                .animation(.default, value: model.player.queuedItems)
                
            }
        }
    }
}

struct TitleView: View {
    let text: String
    let textWidth: CGFloat = 300
    let boldFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title1).pointSize, weight: .bold)

    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Text(text)
                    .font(.title)
                    .bold()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .fixedSize()
                    .offset(x: offset)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .onAppear {
                        let fullTextWidth = textWidthForString(text, font: boldFont)
                        if fullTextWidth > geometry.size.width {
                            withAnimation(Animation.linear(duration: Double(fullTextWidth - geometry.size.width) / 40).delay(5).repeatForever(autoreverses: true)) {
                                offset = -fullTextWidth + geometry.size.width
                            }
                        }
                    }
            }
            .clipped()
        }
        .frame(height: boldFont.lineHeight)
        
    }
    
    private func textWidthForString(_ string: String, font: UIFont) -> CGFloat {
        let size = NSString(string: string).size(withAttributes: [.font: font])
        return size.width
    }
    
}
