//
//  SubsonicAPIModels.swift
//  SubsonicMusic
//
//  Created by Arna13 on 15/6/23.
//

import Foundation

struct PlaylistData: Decodable {
    let id: String
    let name: String
    let songCount: Int
}

struct Playlists: Decodable {
    let playlist: [PlaylistData]
}

struct PlaylistsResponse: Decodable {
    let subsonicResponse: SubsonicResponse
    
    var playlists: [PlaylistData] {
        return subsonicResponse.playlists?.playlist ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct PlaylistSongsData: Decodable {
    let id: String
    let name: String
    let songCount: Int
    let entry: [SongData]
}

struct PlaylistSongsResponse: Decodable {
    let subsonicResponse: SubsonicResponse
    
    var songs: [SongData] {
        return subsonicResponse.playlist?.entry ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct MusicFolder: Decodable {
    let id: Int
    let name: String
}

struct MusicFoldersResponse: Decodable {
    let subsonicResponse: SubsonicResponse
    
    var musicFolders: [MusicFolder] {
        return subsonicResponse.musicFolders?.musicFolder ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct Artist: Decodable {
    let id: String
    let name: String
}

struct Index: Decodable {
    let name: String
    let artists: [Artist]
    
    enum CodingKeys: String, CodingKey {
        case name
        case artists = "artist"
    }
}

struct IndexesResponse: Decodable {
    let subsonicResponse: SubsonicResponse
    
    var indexes: [Index] {
        return subsonicResponse.indexes?.index ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct SongData: Decodable {
    let id: String
    let title: String
    let artist: String
}

struct MusicDirectoryResponse: Decodable {
    let subsonicResponse: SubsonicResponse
    
    var songs: [SongData] {
        return subsonicResponse.directory?.child ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct RandomSongs: Decodable {
    let song: [SongData]
}

struct SongsResponse: Decodable {
    let subsonicResponse: SubsonicResponse
    
    var songs: [SongData] {
        return subsonicResponse.randomSongs?.song ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct PingResponse: Decodable {
    let subsonicResponse: SubsonicResponse
    
    var status: String {
        return subsonicResponse.status
    }
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct MusicFolders: Decodable {
    let musicFolder: [MusicFolder]
}

struct Indexes: Decodable {
    let index: [Index]
}

struct Directory: Decodable {
    let child: [SongData]
}

struct SubsonicResponse: Decodable {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let randomSongs: RandomSongs?
    let playlists: Playlists?
    let playlist: PlaylistSongsData?
    let musicFolders: MusicFolders?
    let indexes: Indexes?
    let directory: Directory?
}
