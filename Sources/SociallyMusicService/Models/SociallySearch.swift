//
//  SociallySearch.swift
//  SociallyMusicService
//
//  Created by Tommy Bojanin on 4/4/20.
//

import Foundation

public struct SociallySearchObject {
    
    public let albums: [SociallyAlbum]
    public let playlist: [SociallyPlaylist]
    public let artists: [SociallyArtist]
    public let tracks: [SociallyTrack]

    init(from spotifySearch: SearchPagingObject) {
        self.albums = spotifySearch.sociallyAlbums
        self.tracks = spotifySearch.sociallyTracks
        self.playlist = spotifySearch.sociallyPlaylists
        self.artists = spotifySearch.sociallyArtists
    }
    init(from appleSearch: AppleSearchObject) {
        self.albums = appleSearch.sociallyAlbums
        self.tracks = appleSearch.sociallyTracks
        self.playlist = appleSearch.sociallyPlaylists
        self.artists = appleSearch.sociallyArtists
    }
}
