//
//  MainView.swift
//  SubsonicMusic
//
//  Created by Arna13 on 13/6/23.
//

import SwiftUI
import CoreData

struct CustomLabelStyle: LabelStyle {
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
                .foregroundColor(isSelected ? .white : .accentColor)
            configuration.title
                .font(isSelected ? .headline : .body)
                .foregroundColor(isSelected ? .white : .primary)
            Spacer()
        }
    }
}

struct CustomLabel: View {
    let title: String
    let systemImage: String
    @Binding var selectedView: String
    
    var body: some View {
        Button(action: {
            selectedView = title
        }) {
            Label(title, systemImage: systemImage)
                .labelStyle(CustomLabelStyle(isSelected: selectedView == title))
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedView == title ? Color.accentColor : Color.clear)
        )
    }
}

struct PlaylistButton: View {
    let playlist: Playlist
    @Binding var selectedPlaylist: Playlist?
    @Binding var selectedView: String
    
    var body: some View {
        Button(action: {
            selectedPlaylist = playlist
            selectedView = "Playlist"
        }) {
            Label(playlist.name ?? "Unknown", systemImage: "music.note.list")
                .labelStyle(CustomLabelStyle(isSelected: selectedView == "Playlist" && selectedPlaylist == playlist))
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedView == "Playlist" && selectedPlaylist == playlist ? Color.accentColor : Color.clear)
        )
    }
}

struct MainView: View {
    @State private var selectedView = "Songs"
    @State private var playlistsExpanded = true
    @EnvironmentObject var playlistsViewModel: PlaylistsViewModel
    @State private var selectedPlaylist: Playlist?

    var body: some View {
        NavigationView {
            List {
                CustomLabel(title: "Songs", systemImage: "music.note", selectedView: $selectedView)
                CustomLabel(title: "Debug", systemImage: "ladybug", selectedView: $selectedView)
                DisclosureGroup(
                    isExpanded: $playlistsExpanded,
                    content: {
                        ForEach(playlistsViewModel.playlists) { playlist in
                            PlaylistButton(playlist: playlist, selectedPlaylist: $selectedPlaylist, selectedView: $selectedView)
                        }
                    },
                    label: {
                        Text("Playlists")
                            .bold()
                    }
                )
                .accentColor(.primary)
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .foregroundColor(Color.black)
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Music")
            switch selectedView {
            case "Songs":
                SongsView()
            case "Debug":
                DebugView()
            case "Playlist":
                if let selectedPlaylist = selectedPlaylist {
                    PlaylistView(playlist: selectedPlaylist)
                } else {
                    Text("No playlist selected")
                }
            default:
                SongsView()
            }
        }
        .onAppear(perform: playlistsViewModel.loadPlaylists)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
	
