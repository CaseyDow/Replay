//
//  PlayerView.swift
//  ExampleSwiftUI
//
//  Created by Yoheimuta on 2021/06/18.
//  Copyright © 2021 YOSHIMUTA YOHEI. All rights reserved.
//
// swiftlint:disable multiple_closures_with_trailing_closure

import SwiftUI
import Combine
import RxSwift
import RxCocoa

class PlayerModel: ObservableObject {
    private let disposeBag = DisposeBag()
    private let commandRelay = PublishRelay<RxMusicPlayer.Command>()
    public private(set) var player: RxMusicPlayer = RxMusicPlayer()!
    
//    @Published var audio: AudioManager = AudioManager()

    @Published var canPlay = true
    @Published var canPlayNext = true
    @Published var canPlayPrevious = true
    @Published var canSkipForward = true
    @Published var canSkipBackward = true
    @Published var title = "Not Playing"
    @Published var artist = "No Artist"
    @Published var artwork: Image = Image("unknown-song")
    @Published var lyrics = ""
    @Published var restDuration = "--:--"
    @Published var duration = "--:--"
    @Published var shuffleMode = RxMusicPlayer.ShuffleMode.off
    @Published var repeatMode = RxMusicPlayer.RepeatMode.none
    @Published var remoteControl = RxMusicPlayer.RemoteControl.moveTrack

    @Published var sliderValue = Float(0)
    @Published var sliderMaximumValue = Float(0)
    @Published var sliderIsUserInteractionEnabled = false
    @Published var sliderPlayableProgress = Float(0)

    private var cancelBag = Set<AnyCancellable>()
    var sliderValueChanged = PassthroughSubject<Float, Never>()

    init() {
        player.rx.canSendCommand(cmd: .play)
            .do(onNext: { [weak self] canPlay in
                self?.canPlay = canPlay
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .next)
            .do(onNext: { [weak self] canPlayNext in
                self?.canPlayNext = canPlayNext
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .previous)
            .do(onNext: { [weak self] canPlayPrevious in
                self?.canPlayPrevious = canPlayPrevious
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .seek(seconds: 0, shouldPlay: false))
            .do(onNext: { [weak self] canSeek in
                self?.sliderIsUserInteractionEnabled = canSeek
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .skip(seconds: 15))
            .do(onNext: { [weak self] canSkip in
                self?.canSkipForward = canSkip
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .skip(seconds: -15))
            .do(onNext: { [weak self] canSkip in
                self?.canSkipBackward = canSkip
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemDuration()
            .do(onNext: { [weak self] in
                self?.sliderMaximumValue = Float($0?.seconds ?? 0)
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemTime()
            .do(onNext: { [weak self] time in
                self?.sliderValue = Float(time?.seconds ?? 0)
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemLoadedProgressRate()
            .do(onNext: { [weak self] rate in
                self?.sliderPlayableProgress = rate ?? 0
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemTitle()
            .do(onNext: { [weak self] title in
                self?.title = title ?? ""
            })
            .drive()
            .disposed(by: disposeBag)
        
        player.rx.currentItemArtist()
            .do(onNext: { [weak self] artist in
                self?.artist = artist ?? ""
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemArtwork()
            .do(onNext: { [weak self] artwork in
                if artwork != nil {
                    self?.artwork = Image(uiImage: artwork!)
                } else {
                    self?.artwork = Image("unknown-song")
                }
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemLyrics()
            .do(onNext: { [weak self] lyrics in
                self?.lyrics = lyrics ?? ""
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemRestDurationDisplay()
            .do(onNext: { [weak self] duration in
                self?.restDuration = duration ?? "--:--"
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemTimeDisplay()
            .do(onNext: { [weak self] duration in
                if duration == "00:00" {
                    self?.duration = "00:00"
                    return
                }
                self?.duration = duration ?? "--:--"
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.shuffleMode()
            .do(onNext: { [weak self] mode in
                self?.shuffleMode = mode
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.repeatMode()
            .do(onNext: { [weak self] mode in
                self?.repeatMode = mode
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.remoteControl()
            .do(onNext: { [weak self] control in
                self?.remoteControl = control
            })
            .drive()
            .disposed(by: disposeBag)

        player.run(cmd: commandRelay.asDriver(onErrorDriveWith: .empty()))
            .flatMap { status -> Driver<()> in
                switch status {
                case let RxMusicPlayer.Status.failed(err: err):
                    print(err)
                case let RxMusicPlayer.Status.critical(err: err):
                    print(err)
                default:
                    break
                }
                return .just(())
            }
            .drive()
            .disposed(by: disposeBag)

        sliderValueChanged
            .sink { [weak self] value in
                self?.seek(value: value)
            }
            .store(in: &cancelBag)
        
    }

    func seek(value: Float?) {
        commandRelay.accept(.seek(seconds: Int(value ?? 0), shouldPlay: false))
    }

    func skip(second: Int) {
        commandRelay.accept(.skip(seconds: second))
    }

    func shuffle() {
        switch player.shuffleMode {
            case .off: player.shuffleMode = .songs
            case .songs: player.shuffleMode = .off
        }
    }

    func play() {
        commandRelay.accept(.play)
    }
    
    func playAt(at: Int) {
        commandRelay.accept(.playAt(index: at))
    }

    func pause() {
        commandRelay.accept(.pause)
    }
    
    func playPause() {
        canPlay ? play() : pause()
    }

    func playNext() {
        if (player.queuedItems.count == player.playIndex + 1) {
            switch player.repeatMode {
            case .none: commandRelay.accept(.restart)
            case .one: commandRelay.accept(.seek(seconds: 0, shouldPlay: false))
            case .all: commandRelay.accept(.playAt(index: 0))
            }
            return
        }
        player.player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .positiveInfinity)
        
        if canPlayNext {
            commandRelay.accept(.next)
        }
    }

    func playPrevious() {
        if canPlayPrevious {
            commandRelay.accept(.previous)
        }
    }

    func doRepeat() {
        switch player.repeatMode {
            case .none: player.repeatMode = .all
            case .all: player.repeatMode = .one
            case .one: player.repeatMode = .none
        }
    }

    func toggleRemoteControl() {
        switch remoteControl {
            case .moveTrack:
                player.remoteControl = .skip(second: 15)
            case .skip:
                player.remoteControl = .moveTrack
        }
    }
    
    func start(items: [RxMusicPlayerItem]) {
        player.newSongs(items: items)
        play()
    }
    
    func queue(items: [RxMusicPlayerItem]) {
        player.append(items: items)
    }
    
    func frontQueue(items: [RxMusicPlayerItem]) {
        if (player.queuedItems.count == 0) {
            queue(items: items)
            return
        }
        for item in items {
            player.insert(item, at: player.playIndex + 1)
        }
    }
    
    func remove(item: RxMusicPlayerItem) {
        for i in (0..<player.queuedItems.count).reversed() {
            if player.queuedItems[i].url == item.url {
                try? player.remove(at: i)
            }
        }
    }
    
}
