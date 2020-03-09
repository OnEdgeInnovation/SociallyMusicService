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

public typealias Track = Resource<TrackAttributes>

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
    let canEdit: Bool
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
    let tracks: Relationship<Track>
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

