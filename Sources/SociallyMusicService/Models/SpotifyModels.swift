//
//  SpotifyModels.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

struct TrackResult: Codable {
    let item: TrackItem
    let isPlaying: Bool
}

struct UserResult: Codable {
    let displayName: String
    let followers: Followers?
    let href: String
    let id: String
    let images: [SpotifyImage]?
    let type: SpotifyType
}

struct Followers: Codable {
    let href: String?
    let total: Int
}

enum SpotifyType: String, Codable {
    case user
    case album
}

struct TrackItem: Codable {
    let album: SimplifiedAlbum
    let artists: [SimplifiedArtist]
    let name: String
    let availableMarkets: [String]?
    let discNumber: Int?
    let durationMs: Int?
    let explicit: Bool?
    let externalIds: ExternalId?
    let id: String?
    let isPlayable: Bool?
    let popularity: Int?
    let previewUrl: String?
    let trackNumber: Int?
    let type: String?
    let uri: String
}

struct TrackItemList: Codable {
    let tracks: [TrackItem]
}

struct SimplifiedAlbum: Codable {
    let artists: [SimplifiedArtist]
    let images: [SpotifyImage]?
    let name: String
    let uri: String
}

struct SimplifiedArtist: Codable {
    let name: String
}

struct SimplifiedTrack: Codable {
    let artists: [SimplifiedArtist]
    let availableMarkets: [String]
    let discNumber: Int
    let durationMs: Int
    let explicit: Bool
    let externalUrls: [String: String]
    let name: String
    let previewUrl: String
    let trackNumber: Int
    let uri: String
    let id: String
}

struct ExternalId: Codable {
    let isrc: String?
}

struct SpotifyImage: Codable {
    let height: Int?
    let width: Int?
    let url: URL
}

struct Playlist: Codable {
    let collaborative: Bool
    let description: String
    let href: String
    let id: String
    let images: [SpotifyImage]
    let name: String
    let uri: String
    let owner: UserResult
}

struct Artist: Codable {
    let name: String
    let followers: Followers
    let genres: [String]
    let href: String
    let id: String
    let images: [SpotifyImage]
    let popularity: Int
    let type: String
    let uri: String
}

struct PlayHistoryObject: Codable {
    let track: SimplifiedTrack
}

struct PlaylistTrack: Codable {
    let track: TrackItem?
}

public struct TokenObject: Codable {

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }

    public let accessToken: String
    public let expiresIn: Double
    public let refreshToken: String
}
