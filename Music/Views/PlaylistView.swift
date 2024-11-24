//
//  PlaylistView.swift
//  Music
//
//  Created by Casey Dow on 9/5/24.
//

import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject var model: PlayerModel
    @EnvironmentObject var audio: AudioModel

    @State private var selection = Set<String>()
    @State private var isEditing = false
    
    @State private var showAlert = false
    @State private var presentCreator = false
    @State private var presentRename = false
    @State private var presentInsert = false
    @State private var selectedAction = 0
    @State private var builderText = ""
    
    var path: String = ""

    var body: some View {
        List(selection: $selection) {
            ForEach(audio.getPlaylists(path: path)[0].sorted(), id: \.self) { playlist in
                if isEditing {
                    Label("\(playlist.dropLast(37))", systemImage: "folder")
                        .padding(10)
                } else {
                    NavigationLink(destination: PlaylistView(path: "\(path)\(playlist)"), label: {
                        Label("\(playlist.dropLast(37))", systemImage: "folder")
                            .padding(10)
                    })
                    .selectionDisabled()
                }
            }
            ForEach(audio.getPlaylists(path: path)[1].sorted(), id: \.self) { playlist in
                if isEditing {
                    Text(playlist.dropLast(36))
                        .padding(10)
                } else {
                    NavigationLink(destination: SongsView(String(playlist.dropLast(36)), playlist: path + playlist + ".playlist"), label: {
                        Text(playlist.dropLast(36))
                            .padding(10)
                    })
                    .selectionDisabled()
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(path.split(separator: "/").last?.dropLast(36) ?? "Playlists")
        .toolbar {
            ToolbarItem(placement: .topBarLeading, content: {
                Button(action: {
                    if audio.getPlaylists(path: path).flatMap({ $0 }).count == selection.count {
                        selection = Set<String>()
                    } else {
                        audio.getPlaylists(path: path).forEach { $0.forEach { selection.insert($0) }}
                    }
                }) {
                    Text(audio.getPlaylists(path: path).flatMap{ $0 }.count == selection.count ? "Deselect All" : "Select All")
                }
                .opacity(self.isEditing == true ? 1 : 0)
            })
            ToolbarItem(placement: .topBarTrailing, content: {
                HStack {
                    Button(action: {
                        self.isEditing.toggle()
                    }) {
                        Text(isEditing ? "Done" : "Select")
                    }
                    if isEditing {
                        Menu {
                            Button(action: {
                                presentRename = true
                            }) {
                                Label("Rename", systemImage: "square.and.pencil")
                            }
                            .disabled (selection.count != 1)
                            Button(action: {
                                presentInsert = true
                            }) {
                                Label("Put In", systemImage: "square.and.arrow.down.on.square")
                            }
                            .disabled (selection.count == 0)
                            Button(action: {
                                selection.forEach {
                                    audio.takeOut($0, path: path)
                                }
                            }) {
                                Label("Take Out", systemImage: "square.and.arrow.up.on.square")
                            }
                            .disabled (selection.count == 0 || path.isEmpty)
                            Button(role: .destructive, action: {
                                selection.forEach {
                                    if $0.hasSuffix("/") {
                                        audio.deleteFolder($0, path: path)
                                    } else {
                                        audio.deletePlaylist($0, path: path)
                                    }

                                }
                                isEditing.toggle()
                            }) {
                                Label("Remove", systemImage: "trash")
                            }
                            .disabled(selection.count == 0)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .resizable()
                                .font(.title)
                                .frame(width: 20, height: 20)
                        }
                    } else {
                        Button(action: {
                            presentCreator = true
                        }) {
                            Label("New Playlist", systemImage: "plus")
                        }
                    }
                }
            })
        }
        .environment(\.editMode, .constant(self.isEditing ? EditMode.active : EditMode.inactive))
        .navigationBarBackButtonHidden(self.isEditing)
        .alert("Invalid name", isPresented: $showAlert) {}
        .sheet(isPresented: $presentCreator,  onDismiss: {
            builderText = ""
        }) {
            NavigationView {
                VStack(spacing: 20) {
                    Picker("Action", selection: $selectedAction) {
                        Text("Playlist").tag(0)
                        Text("Folder").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Enter name", text: $builderText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: {
                        if builderText.isEmpty || builderText.contains("/") {
                            showAlert = true
                            return
                        }
                        switch selectedAction {
                        case 0:
                            audio.createPlaylist(path + builderText)
                        case 1:
                            audio.createFolder(path + builderText)
                        default:
                            break
                        }
                        presentCreator = false
                    }) {
                        Text("Create")
                    }

                    Spacer()
                }
                .navigationTitle("New Item")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("Cancel")
                            .onTapGesture {
                                presentCreator = false
                            }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $presentRename,  onDismiss: {
            builderText = ""
        }) {
            NavigationView {
                VStack(spacing: 20) {
                    TextField("Enter a new name", text: $builderText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button(action: {
                        if builderText.isEmpty || builderText.contains("/") {
                            showAlert = true
                            return
                        }
                        if selection.first!.hasSuffix("/") {
                            audio.renameFolder(from: selection.first!, to: builderText, path: path)
                        } else {
                            audio.renamePlaylist(from: path + selection.first!, to: path + builderText)
                        }
                        selection = Set<String>()
                        isEditing.toggle()
                        presentRename = false
                    }) {
                        Text("Set")
                    }
                    Spacer()
                }
                .navigationTitle("Rename")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("Cancel")
                            .onTapGesture {
                                presentRename = false
                            }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $presentInsert) {
            NavigationView {
                List(audio.getPlaylists(path: path)[0].filter{ !selection.contains($0) }.sorted(), id: \.self) { playlist in
                    Button(action: {
                        selection.forEach { (str: String) in
                            if str.hasSuffix("/") {
                                audio.renameFolder(from: str, to: playlist + str.dropLast(37), path: path)
                            } else {
                                audio.renamePlaylist(from: path + str, to: path + playlist + str.dropLast(36))
                            }
                        }
                        presentInsert = false
                    }) {
                        Label(playlist.dropLast(37), systemImage: "plus")
                    }
                }
                .listStyle(.plain)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("Close")
                            .onTapGesture {
                                presentInsert = false
                            }
                    }
                }
            }
        }
    }
    
}
