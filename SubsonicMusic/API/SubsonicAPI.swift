//
//  SubsonicAPI.swift
//  SubsonicMusic
//
//  Created by Arna13 on 13/6/23.
//

import Foundation
import CoreData
import UIKit

class SubsonicAPI {
    
    // DEBUG MODE
    let debugMode = true;
    
    let operationQueue = OperationQueue()
    static let shared = SubsonicAPI()
    
    let baseURL: URL
    let username: String
    let password: String
    
    var syncStatusChanged: ((Bool) -> Void)?
    
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
        
        operationQueue.maxConcurrentOperationCount = 1
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

    func sendRequest(url: URL?, delay: UInt32 = 500000, completion: @escaping (Data?, Error?) -> Void) {
        guard let url = url else {
            completion(nil, nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorNetworkConnectionLost {
                usleep(delay)
                self.sendRequest(url: url, delay: delay * 2, completion: completion)
            } else if let error = error {
                print("Error sending request: \(error)")
                completion(nil, error)
            } else {
                completion(data, nil)
            }
        }
        task.resume()
    }
    
    func ping(completion: @escaping (Bool) -> Void) {
        let url = buildURL(path: "/rest/ping")
        
        sendRequest(url: url) { data, error in
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

    func getPlaylists(completion: @escaping ([NSManagedObject]) -> Void) {
        guard let url = buildURL(path: "/rest/getPlaylists") else {
            completion([])
            return
        }
        
        sendRequest(url: url) { data, error in
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
    
    func getPlaylistSongs(forPlaylistId playlistId: String, completion: @escaping ([NSManagedObject]) -> Void) {
        print("getSongs called with playlistId: \(playlistId)")
        let url = buildURL(path: "/rest/getPlaylist", queryItems: [URLQueryItem(name: "id", value: playlistId)])
        print("getSongs URL: \(url?.absoluteString ?? "")")
        
        sendRequest(url: url) { data, error in
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
    
    func getCoverArt(id: String, completion: @escaping (UIImage?) -> Void) {
        let url = buildURL(path: "/rest/getCoverArt", queryItems: [URLQueryItem(name: "id", value: id)])
        
        sendRequest(url: url) { data, error in
            if let data = data {
                if let image = UIImage(data: data) {
                    completion(image)
                } else {
                    print("Error fetching cover art image for song with ID \(id): Data is not a valid image")
                    print("Data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    completion(nil)
                }
            } else if let error = error {
                print("Error fetching cover art image for song with ID \(id): \(error)")
                completion(nil)
            } else {
                print("Error fetching cover art image for song with ID \(id): No data returned")
                completion(nil)
            }
        }
    }
    
    func getAllSongs(completion: @escaping ([NSManagedObject]) -> Void) {
        syncStatusChanged?(true)
        let url = self.buildURL(path: "/rest/getMusicFolders")
        
        sendRequest(url: url) { data, error in
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
                    
                    self.sendRequest(url: url) { data, error in
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
                                    
                                    self.sendRequest(url: url) { data, error in
                                        guard let data = data else {
                                            group.leave()
                                            return
                                        }
                                        
                                        do {
                                            let decoder = JSONDecoder()
                                            let response = try decoder.decode(MusicDirectoryResponse.self, from: data)
                                                                                            
                                            for song in response.songs {
                                                print(song)
                                                DispatchQueue.main.async {
                                                    let context = CoreDataStack.shared.viewContext
                                                    let songEntity = NSEntityDescription.entity(forEntityName: "Song", in: context)!
                                                    let songObject = NSManagedObject(entity: songEntity, insertInto: context)
                                                    songObject.setValue(song.id, forKey: "id")
                                                    songObject.setValue(song.title, forKey: "title")
                                                    songObject.setValue(song.artist, forKey: "artist")
                                                    songObject.setValue(song.album, forKey: "album")
                                                    songObject.setValue(song.coverArt, forKey: "coverArt")
                                                    songObject.setValue(song.duration, forKey: "duration")
                                                    songObject.setValue(song.bitRate, forKey: "bitRate")
                                                    songObject.setValue(song.contentType, forKey: "contentType")
                                                    
                                                    if let coverArtId = song.coverArt {
                                                        group.enter()
                                                        
                                                        self.getCoverArt(id: coverArtId) { image in
                                                            if let image = image,
                                                               let imageData = image.pngData() {
                                                                songObject.setValue(imageData, forKey: "coverArtData")
                                                            } else {
                                                                print("Error fetching cover art image for song with ID \(song.id)")
                                                            }
                                                            
                                                            group.leave()
                                                        }
                                                    } else {
                                                        print("No cover art ID available for song with ID \(song.id)")
                                                    }
                                                    
                                                    print("Song data: \(song)")
                                                    

                                                    allSongs.append(songObject)
                                                }
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
                    print("All syncing is done!")
                    self.syncStatusChanged?(false)
                    completion(allSongs)
                }
            } catch {
                print("Error decoding response data: \(error)")
                completion([])
            }
        }
    }
}
