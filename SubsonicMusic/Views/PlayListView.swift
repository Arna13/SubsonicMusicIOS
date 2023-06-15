//
//  PlayListView.swift
//  SubsonicMusic
//
//  Created by Arna13 on 14/6/23.
//

import SwiftUI
import CoreData

struct PlaylistView: View {
    var playlist: NSManagedObject
    
    @FetchRequest var songs: FetchedResults<Song>
    
    init(playlist: NSManagedObject) {
        self.playlist = playlist
        
        let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ANY playlist == %@", playlist)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        _songs = FetchRequest(fetchRequest: fetchRequest)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(playlist.value(forKey: "name") as? String ?? "Unknown Playlist")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, -5)
                .padding(.bottom, 25)
            
            Text("\(playlist.value(forKey: "songCount") as? Int ?? 0) Songs")
                .font(.subheadline)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(songs, id: \.self) { song in
                        SongRow(song: song)
                            .onTapGesture {
                                // TODO Handle tap gesture here
                            }
                    }
                }
            }
        }.padding()
    }
}
