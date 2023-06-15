//
//  SubsonicAPI.swift
//  SubsonicMusic
//
//  Created by Arna13 on 13/6/23.
//

import Foundation
import CoreData

class SubsonicAPI {
    static let shared = SubsonicAPI()
    
    let baseURL: URL
    let username: String
    let password: String
    
    private init() {
        if let credentials = loadCredentials() {
            self.baseURL = credentials.baseURL
            self.username = credentials.username
            self.password = credentials.password
        } else {
            self.baseURL = URL(string: "http://baseurl/")!
            self.username = "username"
            self.password = "password"
        }
    }
    
    func getRandomSongs(completion: @escaping ([NSManagedObject]) -> Void) {
        let url = buildURL(path: "/rest/getRandomSongs")
        
        sendRequest(url: url) { data in
            guard let data = data else {
                completion([])
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(SongsResponse.self, from: data)
                
                let songs = response.songs.map { song in
                    let context = CoreDataStack.shared.viewContext
                    let songEntity = NSEntityDescription.entity(forEntityName: "Song", in: context)!
                    let songObject = NSManagedObject(entity: songEntity, insertInto: context)
                    songObject.setValue(song.id, forKey: "id")
                    songObject.setValue(song.title, forKey: "title")
                    songObject.setValue(song.artist, forKey: "artist")
                    
                    return songObject
                }
                
                completion(songs)
            } catch {
                print("Error decoding response data: \(error)")
                completion([])
            }
        }
    }
    
    func ping(completion: @escaping (Bool) -> Void) {
        let url = buildURL(path: "/rest/ping")
        
        sendRequest(url: url) { data in
            guard let data = data else {
                completion(false)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PingResponse.self, from: data)
                print(response)
                completion(response.status == "ok")
            } catch {
                print("Error decoding response data: \(error)")
                completion(false)
            }
        }
    }
    
    private func buildURL(path: String, queryItems: [URLQueryItem] = []) -> URL? {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.path = path
        urlComponents?.queryItems = [
            URLQueryItem(name: "u", value: username),
            URLQueryItem(name: "p", value: password),
            URLQueryItem(name: "v", value: "1.16.1"),
            URLQueryItem(name: "c", value: "SubsonicMusicIOS"),
            URLQueryItem(name: "f", value: "json")
        ] + queryItems
        
        return urlComponents?.url
    }
    
    private func sendRequest(url: URL?, completion: @escaping (Data?) -> Void) {
        guard let url = url else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending request: \(error)")
            }
            
            completion(data)
        }
        task.resume()
    }

    func getPlaylists(completion: @escaping ([NSManagedObject]) -> Void) {
        guard let url = buildURL(path: "/rest/getPlaylists") else {
            completion([])
            return
        }
        
        sendRequest(url: url) { data in
            guard let data = data else {
                completion([])
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PlaylistsResponse.self, from: data)
                
                let playlists = response.playlists.map { playlist in
                    let context = CoreDataStack.shared.viewContext
                    let playlistEntity = NSEntityDescription.entity(forEntityName: "Playlist", in: context)!
                    let playlistObject = NSManagedObject(entity: playlistEntity, insertInto: context)
                    playlistObject.setValue(playlist.id, forKey: "id")
                    playlistObject.setValue(playlist.name, forKey: "name")
                    playlistObject.setValue(playlist.songCount, forKey: "songCount")
                    
                    return playlistObject
                }
                
                completion(playlists)
            } catch {
                print("Error decoding response data: \(error)")
                completion([])
            }
        }
    }
    
    func getSongs(forPlaylistId playlistId: String, completion: @escaping ([NSManagedObject]) -> Void) {
        print("getSongs called with playlistId: \(playlistId)")
        let url = buildURL(path: "/rest/getPlaylist", queryItems: [URLQueryItem(name: "id", value: playlistId)])
        print("getSongs URL: \(url?.absoluteString ?? "")")
        
        sendRequest(url: url) { data in
            guard let data = data else {
                print("getSongs received no data")
                completion([])
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PlaylistSongsResponse.self, from: data)
                
                let songs = response.songs.map { song in
                    let context = CoreDataStack.shared.viewContext
                    let songEntity = NSEntityDescription.entity(forEntityName: "Song", in: context)!
                    let songObject = NSManagedObject(entity: songEntity, insertInto: context)
                    songObject.setValue(song.id, forKey: "id")
                    songObject.setValue(song.title, forKey: "title")
                    songObject.setValue(song.artist, forKey: "artist")
                    
                    return songObject
                }
                
                print("getSongs decoded \(songs.count) songs")
                completion(songs)
            } catch {
                print("Error decoding response data: \(error)")
                completion([])
            }
        }
    }
    
    func getAllSongs(completion: @escaping ([NSManagedObject]) -> Void) {
        let url = self.buildURL(path: "/rest/getMusicFolders")
        
        sendRequest(url: url) { data in
            guard let data = data else {
                completion([])
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(MusicFoldersResponse.self, from: data)
                
                let musicFolderIds = response.musicFolders.map { String($0.id) }
                
                var allSongs: [NSManagedObject] = []
                
                let group = DispatchGroup()
                
                for musicFolderId in musicFolderIds {
                    group.enter()
                    
                    let url = self.buildURL(path: "/rest/getIndexes", queryItems: [URLQueryItem(name: "musicFolderId", value: musicFolderId)])
                    
                    self.sendRequest(url: url) { data in
                        guard let data = data else {
                            group.leave()
                            return
                        }
                        
                        do {
                            let decoder = JSONDecoder()
                            let response = try decoder.decode(IndexesResponse.self, from: data)
                            
                            for index in response.indexes {
                                for artist in index.artists {
                                    group.enter()
                                    
                                    let url = self.buildURL(path: "/rest/getMusicDirectory", queryItems: [URLQueryItem(name: "id", value: artist.id)])
                                    
                                    self.sendRequest(url: url) { data in
                                        guard let data = data else {
                                            group.leave()
                                            return
                                        }
                                        
                                        do {
                                            let decoder = JSONDecoder()
                                            let response = try decoder.decode(MusicDirectoryResponse.self, from: data)
                                            
                                            for song in response.songs {
                                                let context = CoreDataStack.shared.viewContext
                                                let songEntity = NSEntityDescription.entity(forEntityName: "Song", in: context)!
                                                let songObject = NSManagedObject(entity: songEntity, insertInto: context)
                                                songObject.setValue(song.id, forKey: "id")
                                                songObject.setValue(song.title, forKey: "title")
                                                songObject.setValue(song.artist, forKey: "artist")
                                                
                                                allSongs.append(songObject)
                                            }
                                            
                                            group.leave()
                                        } catch {
                                            print("Error decoding response data: \(error)")
                                            group.leave()
                                        }
                                    }
                                }
                            }
                            
                            group.leave()
                        } catch {
                            print("Error decoding response data: \(error)")
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    completion(allSongs)
                }
            } catch {
                print("Error decoding response data: \(error)")
                completion([])
            }
        }
    }
}
