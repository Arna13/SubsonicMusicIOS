//
//  SubsonicAPIModels.swift
//  SubsonicMusic
//
//  Created by Arna13 on 15/6/23.
//

import Foundation

// Playlists
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


// Music folders/dir
struct MusicFolder: Decodable {
    let id: Int
    let name: String
}

struct MusicFolders: Decodable {
    let musicFolder: [MusicFolder]
}

struct Directory: Decodable {
    let child: [SongData]
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

struct MusicDirectoryResponse: Decodable {
    let subsonicResponse: SubsonicResponse
    
    var songs: [SongData] {
        return subsonicResponse.directory?.child ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}


// Index
struct Index: Decodable {
    let name: String
    let artists: [Artist]
    
    enum CodingKeys: String, CodingKey {
        case name
        case artists = "artist"
    }
}

struct Indexes: Decodable {
    let index: [Index]
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


// Songs
struct SongData: Decodable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let coverArt: String?
    let bitRate: Int?
    let contentType: String?
    let duration: Int?
}


struct Songs: Decodable {
    let song: [SongData]
}

struct Artist: Decodable {
    let id: String
    let name: String
}

struct SongsResponse: Decodable {
    let subsonicResponse: SubsonicResponse
    
    var songs: [SongData] {
        return subsonicResponse.songs?.song ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}


// Extra
struct PingResponse: Decodable {
    let subsonicResponse: SubsonicResponse
    
    var status: String {
        return subsonicResponse.status
    }
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}


// Subsonic response
struct SubsonicResponse: Decodable {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let songs: Songs?
    let playlists: Playlists?
    let playlist: PlaylistSongsData?
    let musicFolders: MusicFolders?
    let indexes: Indexes?
    let directory: Directory?
}
