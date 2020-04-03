//
//  AppleModels.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

public struct ResponseRoot<T: Codable>: Codable {
    let data: [T]?
}

public typealias AppleTrack = Resource<TrackAttributes>

public struct TrackAttributes: Codable {
    let artistName: String
    let albumName: String
    let isrc: String
    let artwork: Artwork
    let composerName: String?
    let genreNames: [String]
    let name: String
    let releaseDate: String
    let trackNumber: Int
    let url: URL
}

public struct Artwork: Codable {
    let url: String
}

public struct Resource<AttributesType: Codable>: Codable {
    let id: String
    let href: String
    let attributes: AttributesType?
}

public typealias ApplePlaylist = AdditionalResource<PlaylistAttributes, PlaylistRelationships>
public typealias SimpleApplePlaylist = Resource<PlaylistAttributes>

public enum PlaylistType: String, Codable {
    case userShared = "user-shared"
    case editorial
    case external
    case personalMix = "personal-mix"
}

public struct PlaylistAttributes: Codable {
    let description: EditorialNotes?
    let name: String
    let artwork: Artwork?
    let canEdit: Bool?
    let curatorName: String?
    let playParams: PlayParameters
    
}

public struct EditorialNotes: Codable {
    let standard: String?
    let short: String?
}

public struct Relationship<T: Codable>: Codable {
    let data: [T]?
    let href: String
    let next: String?
}

public typealias Curator = Resource<CuratorAttributes>

public struct CuratorAttributes: Codable {
    let artwork: Artwork
    let editorialNotes: EditorialNotes?
    let name: String
    let url: URL
}

public struct CuratorRelationships: Codable {
    let playlists: Relationship<ApplePlaylist>
}

public struct AdditionalResource<AttributesType: Codable, RelationshipsType: Codable>: Codable {
    let id: String
    let href: String
    let attributes: AttributesType?
    let relationships: RelationshipsType?
}
public struct PlaylistRelationships: Codable {
    let curator: Relationship<Curator>?
    let tracks: Relationship<AppleTrack>
}

public typealias Song = Resource<SongAttributes>

public typealias LibrarySong = Resource<LibrarySongAttributes>

public struct SongAttributes: Codable {
    let albumName: String
    let artistName: String
    let artwork: Artwork
    let isrc: String?
    let name: String
    let url: String?
    let playParams: PlayParameters
}

public struct LibrarySongAttributes: Codable {
    let albumName: String
    let artistName: String
    let artwork: Artwork
    let playParams: PlayParameters
    let name: String
    
}

public struct PlayParameters: Codable {
    let id: String
    let kind: String
    let catalogId: String?
}

public typealias HistoryObject = Resource<HistoryAttributes>

public struct HistoryAttributes: Codable {
    let artistName: String?
    let artwork: Artwork?
    let name: String
    let playParams: PlayParameters
}

public struct ChartRoot: Codable {
    let results: SongChart
}

public struct SongChart: Codable {
    let songs: [AppleChart]
}

public struct AppleChart: Codable {
    let chart: String
    let data: [Song]
    let href: String
    let name: String
    let next: String?
}

public struct AppleAlbum: Codable {
    let artistName: String
    let artwork: Artwork?
    let name: String
    let playParams: PlayParameters?
}

public struct AppleAlbumRelationships: Codable {
    let tracks: ResponseRoot<Resource<SongAttributes>>
}


public struct AppleSearchObject: Codable {
    let playlists: ResponseRoot<Resource<PlaylistAttributes>>
    let songs: ResponseRoot<Resource<SongAttributes>>
    let artists: ResponseRoot<AdditionalResource<ArtistSearchAttributes, ArtistRelationships>>
    let albums: ResponseRoot<Resource<AppleAlbum>>

    var sociallyTracks: [SociallyTrack] {
        return songs.data?.compactMap({SociallyTrack(from: $0.attributes)}) ?? []
    }
    
    var sociallyAlbums: [SociallyAlbum] {
        return albums.data?.compactMap({SociallyAlbum(from: $0 )}) ?? []
    }
    
    var sociallyArtists: [SociallyArtist] {
        return artists.data?.compactMap({SociallyArtist(from: $0 )}) ?? []
    }
    
    var sociallyPlaylists: [SociallyPlaylist] {
        return playlists.data?.compactMap({SociallyPlaylist(from: $0 )}) ?? []
    }
}

struct AppleSearchRoot<T: Decodable>: Decodable {
    let results: T
}

struct ArtistRelationships: Codable {
    let albums: ResponseRoot<Resource<AppleAlbum>>
}

struct CatalogPlaylistAttributes: Codable {
    let tracks: ResponseRoot<Resource<SongAttributes>>
}


struct ArtistSearchAttributes: Codable {
    let url: String
    let genreNames: [String]
    let name: String
}


struct ArtistProfileSongsSearch: Codable {
    let songs: ResponseRoot<AdditionalResource<SongAttributes, ArtistProfileSongSearchRelationships>>
    
    var sociallyTracks: [SociallyTrack] {
        return songs.data?.compactMap({SociallyTrack(from: $0.attributes)}) ?? []
    }
}

struct ArtistProfileSongSearchRelationships: Codable {
    let artists: ResponseRoot<Resource<ArtistSearchAttributes>>
}
