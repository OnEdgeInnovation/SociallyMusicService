//
//  PagingObject.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

public struct PagingObject<T: Codable>: Codable {
    
    let href: String
    var items: [T]
    let limit: Int
    let next: String?
    let offset: Int?
    let previous: String?
    
    let total: Int?
    
    var nextUrl: URL? {
        guard let next = next else {
            return nil
        }
        return URL(string: next)
    }
    
    var prevUrl: URL? {
        guard let previous = previous else {
            return nil
        }
        return URL(string: previous)
    }
}

public struct TrackPagingObject<T: Codable>: Codable {
    let tracks: PagingObject<T>
}

public struct SearchPagingObject: Codable {
    let tracks: PagingObject<TrackItem>?
    let albums: PagingObject<SimplifiedAlbum>?
    let artists: PagingObject<Artist>?
    let playlists: PagingObject<Playlist>?
    public var sociallyTracks: [SociallyTrack] {
        guard let tracks = tracks else { return [SociallyTrack]() }
        return tracks.items.map { SociallyTrack(from: $0) }
    }
    public var sociallyAlbums: [SociallyAlbum] {
        guard let albums = albums else { return [SociallyAlbum]() }
        return albums.items.map { SociallyAlbum(from: $0) }
    }
    public var sociallyArtists: [SociallyArtist] {
        guard let artists = artists else { return [SociallyArtist]() }
        return artists.items.map { SociallyArtist(from: $0) }
    }
    public var sociallyPlaylists: [SociallyPlaylist] {
        guard let playlists = playlists else { return [SociallyPlaylist]() }
        return playlists.items.map { SociallyPlaylist(from: $0) }
    }
}
