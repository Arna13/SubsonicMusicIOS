//
//  PlaylistsViewModel.swift
//  SubsonicMusic
//
//  Created by Arna13 on 14/6/23.
//

import Foundation
import CoreData

class PlaylistsViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var isDeleting = false
    @Published var isSyncing = false
    var lastSyncTime: Date?

    func loadPlaylists() {
        let context = CoreDataStack.shared.viewContext

        let fetchRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()

        do {
            let playlists = try context.fetch(fetchRequest)

            self.playlists = playlists
        } catch {
            print("Error fetching playlists from database: \(error)")
        }
    }
}
