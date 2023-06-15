//
//  DebugView.swift
//  SubsonicMusic
//
//  Created by Arna13 on 13/6/23.
//

import CoreData
import SwiftUI

struct DebugView: View {
    @EnvironmentObject var playlistsViewModel: PlaylistsViewModel
    @State private var serverReachable = false
    @State private var serverStatusChecked = false
    @State private var baseURLString = ""
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack {
            if serverStatusChecked {
                if serverReachable {
                    Text("Server is reachable")
                        .foregroundColor(.green)
                    
                    Button("Sync Data") {
                        syncData()
                    }.disabled(playlistsViewModel.isSyncing)
                    
                    Button("Drop database") {
                        clearDatabase()
                    }.disabled(playlistsViewModel.isSyncing || playlistsViewModel.isSyncing)
                } else {
                    Text("Server is not reachable")
                        .foregroundColor(.red)
                    
                    TextField("Base URL", text: $baseURLString)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                    
                    Button("Save Credentials") {
                        guard let baseURL = URL(string: baseURLString),
                              !username.isEmpty,
                              !password.isEmpty else {
                            return
                        }
                        
                        let credentials = Credentials(baseURL: baseURL, username: username, password: password)
                        storeCredentials(credentials)
                        
                        checkServer()
                    }
                }
            } else {
                ProgressView()
            }
        }
        .padding()
        .onAppear {
            checkServer()
        }
    }
    
    func checkServer() {
        let subsonicAPI = SubsonicAPI.shared
        
        subsonicAPI.ping { reachable in
            DispatchQueue.main.async {
                self.serverReachable = reachable
                self.serverStatusChecked = true
            }
        }
    }
    
    // FIXME For some reason everything gets duped on the DB unless we check for duplicates on sync, probably wanna fix that even though the workaround works
    func syncData() {
        var allSongs: [Song] = []
        
        let now = Date()
        let minimumDelayBetweenSyncs: TimeInterval = 5
        
        if let lastSyncTime = playlistsViewModel.lastSyncTime,
           now.timeIntervalSince(lastSyncTime) < minimumDelayBetweenSyncs {
            return
        }
        
        playlistsViewModel.lastSyncTime = now
        playlistsViewModel.isSyncing = true
        let subsonicAPI = SubsonicAPI.shared
        
        subsonicAPI.getAllSongs { songs in
            let context = CoreDataStack.shared.viewContext
            
            do {
                for song in songs {
                    let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", song.value(forKey: "id") as! CVarArg)
                    let existingSongs = try context.fetch(fetchRequest)
                    
                    if existingSongs.isEmpty {
                        let songEntity = NSEntityDescription.entity(forEntityName: "Song", in: context)!
                        let songObject = NSManagedObject(entity: songEntity, insertInto: context)
                        songObject.setValue(song.value(forKey: "id"), forKey: "id")
                        songObject.setValue(song.value(forKey: "title"), forKey: "title")
                        songObject.setValue(song.value(forKey: "artist"), forKey: "artist")
                    }
                }
                
                try context.save()
            } catch {
                print("Error syncing songs to database: \(error)")
            }
        }
        
        subsonicAPI.getPlaylists { playlists in
            let context = CoreDataStack.shared.viewContext
            
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Playlist")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(batchDeleteRequest)
                try context.save()
            } catch {
                print("Error executing batch delete request: \(error)")
            }
            
            let group = DispatchGroup()
            
            for playlist in playlists {
                group.enter()
                
                let fetchRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", playlist.value(forKey: "id") as! String)
                
                do {
                    let results = try context.fetch(fetchRequest)
                    let playlistEntity = NSEntityDescription.entity(forEntityName: "Playlist", in: context)!
                    var playlistObject: Playlist
                    if results.isEmpty {
                        playlistObject = NSManagedObject(entity: playlistEntity, insertInto: context) as! Playlist
                        playlistObject.setValue(playlist.value(forKey: "id"), forKey: "id")
                        playlistObject.setValue(playlist.value(forKey: "name"), forKey: "name")
                        playlistObject.setValue(playlist.value(forKey: "songCount"), forKey: "songCount")
                    } else {
                        playlistObject = results.first!
                    }
                    
                    subsonicAPI.getSongs(forPlaylistId: playlist.value(forKey: "id") as! String) { songs in
                        for song in songs {
                            let songFetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
                            songFetchRequest.predicate = NSPredicate(format: "id == %@", song.value(forKey: "id") as! String)
                            let songResults = try? context.fetch(songFetchRequest)
                            var songObject: Song
                            if let existingSong = songResults?.first {
                                songObject = existingSong
                            } else {
                                let songEntity = NSEntityDescription.entity(forEntityName: "Song", in: context)!
                                songObject = NSManagedObject(entity: songEntity, insertInto: context) as! Song
                                songObject.setValue(song.value(forKey: "id"), forKey: "id")
                                songObject.setValue(song.value(forKey: "title"), forKey: "title")
                                songObject.setValue(song.value(forKey: "artist"), forKey: "artist")
                            }
                            print("Adding song to playlist:", songObject.title ?? "Unknown")
                            playlistObject.addToSong(songObject)
                            
                            allSongs.append(songObject)
                            do {
                                try context.save()
                            } catch {
                                print("Error syncing songs to playlist:", error)
                            }
                        }
                        group.leave()
                    }
                } catch {
                    print("Error checking for existing playlist: \(error)")
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                do {
                    try context.save()
                    playlistsViewModel.loadPlaylists()
                } catch {
                    print("Error syncing playlists to database: \(error)")
                }
            }
        }
        
        playlistsViewModel.isSyncing = false
    }
    
    func clearDatabase() {
        playlistsViewModel.isDeleting = true
        let context = CoreDataStack.shared.viewContext
        
        let entities = ["Song", "Playlist"]
        
        for entity in entities {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(batchDeleteRequest)
            } catch {
                print("Error clearing \(entity) data from database: \(error)")
            }
        }
        playlistsViewModel.isDeleting = false
        playlistsViewModel.loadPlaylists()
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}
