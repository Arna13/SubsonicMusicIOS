//
//  HomeView.swift
//  SubsonicMusic
//
//  Created by Arna13 on 13/6/23.
//

import SwiftUI
import CoreData

struct SongsView: View {
    @FetchRequest(entity: Song.entity(), sortDescriptors: []) var songs: FetchedResults<Song>
    @State private var searchText = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Songs")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, -5)
            
            SearchBar(text: $searchText, placeholder: "Find in Songs")
            
            HStack {
                Text("\(songs.count) Songs")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .frame(width: 150, height: 44)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "shuffle")
                        Text("Shuffle")
                    }
                    .frame(width: 150, height: 44)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .font(.system(size: 17, weight: .semibold))
            .padding(.horizontal, 10)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredSongs, id: \.self) { song in
                        SongRow(song: song)
                            .onTapGesture {
                                // TODO Handle tap gesture here
                            }
                    }
                }
            }
        }.padding()
    }
    
    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return Array(songs)
        } else {
            return songs.filter { song in
                (song.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (song.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
}

struct SongRow: View {
    var song: Song
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                if let coverArtData = song.coverArtData,
                   let coverArtImage = UIImage(data: coverArtData) {
                    Image(uiImage: coverArtImage)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "music.note")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(4)
                }
                
                VStack(alignment: .leading) {
                    Text(song.title ?? "Unknown Song")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(song.artist ?? "Unknown Artist")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let album = song.album {
                        Text(album)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
        }
        .background(Color.clear)
    }
}



struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

struct ListenNowView_Previews: PreviewProvider {
    static var previews: some View {
        SongsView()
    }
}
