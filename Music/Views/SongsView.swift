//
//  SongView.swift
//  Music
//
//  Created by Casey Dow on 8/31/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct SongsView: View {
    @EnvironmentObject var model: PlayerModel
    @EnvironmentObject var audio: AudioModel

    @State private var uploaderPresented = false
    @State private var playlistPresented = false
    @State private var selection = Set<RxMusicPlayerItem>()
    @State private var isEditing = false
    @State private var showItems = false
    @State private var searchText = ""
    @State private var path = ""

    let title: String
    let artist: String?
    let album: String?
    let playlist: String?

    init(_ title: String, artist: String? = nil, album: String? = nil, playlist: String? = nil) {
        self.title = title
        self.artist = artist
        self.album = album
        self.playlist = playlist
    }
    
    var filteredSongs: [RxMusicPlayerItem] {
        let songs = audio.getSongs(artist: artist, album: album, playlist: playlist)
        if searchText.isEmpty {
            return songs
        } else {
            return songs.filter { song in
                song.getTitle().localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List(selection: $selection) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color("App.Color.gray"))
                    .padding(5)
                TextField("Find in Songs", text: $searchText)
            }
            .padding(5)
            .background(Color("App.Color.lightgray"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .selectionDisabled()
            .listRowSeparator(.hidden)
            
            HStack {
                Button(action: { model.start(items: filteredSongs) }) {
                    Label("Play", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color("App.Color.lightgray"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.borderless)
                Spacer()
                Button(action: { model.start(items: filteredSongs.shuffled()) }) {
                    Label("Shuffle", systemImage: "shuffle")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color("App.Color.lightgray"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.borderless)
            }
            .selectionDisabled()
            .listRowSeparator(.hidden)

            ForEach(filteredSongs, id: \.self) { song in
                SongView(song: song, isEditing: $isEditing, playlist: playlist)
            }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    if filteredSongs.count == selection.count {
                        selection = Set<RxMusicPlayerItem>()
                    } else {
                        filteredSongs.forEach { item in
                            selection.insert(item)
                        }
                    }
                }) {
                    Text(filteredSongs.count == selection.count ? "Deselect All" : "Select All")
                }
                .opacity(self.isEditing ? 1 : 0)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button(action: {
                        withAnimation(.spring) {
                            self.isEditing.toggle()
                        }
                    }) {
                        Text(isEditing ? "Done" : "Select")
                    }
                    if isEditing {
                        Menu {
                            Section {
                                
                                Button(action: {
                                    playlistPresented = true
                                }) {
                                    Label("Add to Playlist", systemImage: "text.badge.plus")
                                }
                                .disabled(selection.isEmpty)
                                Button(action: {
                                    model.frontQueue(items: Array(selection))
                                }) {
                                    Label("Play Next", systemImage: "text.insert")
                                }
                                .disabled(selection.isEmpty)
                                Button(action: {
                                    model.queue(items: Array(selection))
                                }) {
                                    Label("Play Last", systemImage: "text.append")
                                }
                                .disabled(selection.isEmpty)
                            }
                            Section {
                                if let playlist = playlist {
                                    Button(role: .destructive, action: {
                                        for item in selection {
                                            audio.removeFromPlaylist(playlist, item: item)
                                        }
                                        isEditing.toggle()
                                    }) {
                                        Label("Remove from Playlist", systemImage: "trash")
                                    }
                                    .disabled(selection.isEmpty)
                                }
                                Button(role: .destructive, action: {
                                    for item in selection {
                                        audio.delete(item: item)
                                        model.remove(item: item)
                                    }
                                    isEditing.toggle()
                                }) {
                                    Label("Delete Songs", systemImage: "trash")
                                }
                                .disabled(selection.isEmpty)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .resizable()
                                .font(.title)
                                .frame(width: 20, height: 20)
                        }
                    } else {
                        Button(action: {
                            uploaderPresented = true
                        }) {
                            Label("Add Songs", systemImage: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $uploaderPresented) {
            DocumentPicker { urls in
                urls.forEach { audio.saveSong($0, upload: true, playlist: playlist) }
            }
        }
        .sheet(isPresented: $playlistPresented) {
            NavigationView {
                List {
                    ForEach (audio.getPlaylists(path: path)[0].sorted(), id: \.self) { playlist in
                        Button(action: {
                            path = path + playlist
                        }) {
                            Label(playlist.dropLast(37), systemImage: "folder")
                                .lineLimit(1)
                                .padding(10)
                        }
                    }
                    ForEach (audio.getPlaylists(path: path)[1].sorted(), id: \.self) { playlist in
                        Button(action: {
                            print(path + playlist + ".playlist")
                            selection.forEach { audio.addToPlaylist(path + playlist + ".playlist", item: $0) }
                            playlistPresented = false
                        }) {
                            Label(playlist.dropLast(36), systemImage: "plus")
                                .lineLimit(1)
                                .padding(10)
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Add to Playlist")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("Back")
                            .onTapGesture {
                                path = path.split(separator: "/").dropLast().map{"\($0)/"}.joined()
                            }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("Close")
                            .onTapGesture {
                                playlistPresented = false
                            }
                    }
                }
                .padding()
            }
        }
        .environment(\.editMode, .constant(self.isEditing ? EditMode.active : EditMode.inactive))
        .navigationBarBackButtonHidden(self.isEditing)
    }
                    
}


struct DocumentPicker: UIViewControllerRepresentable {
    var didPickDocuments: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.didPickDocuments(urls)
        }
    }
}
