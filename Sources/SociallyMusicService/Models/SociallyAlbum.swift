//
//  SociallyAlbum.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 3/29/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

public struct SociallyAlbum: Codable {
    
    public let albumUri: String?
    public let albumId: String
    public let name: String
    public var imageURL: URL?
    public let artist: SociallyArtist
    
    init(from album: SimplifiedAlbum) {
        self.name = album.name
        self.imageURL = album.images?.first?.url
        if let artist = album.artists.first {
            self.artist = SociallyArtist(name: artist.name, id: artist.id, imageURL: "")
        } else {
            self.artist = SociallyArtist(name: "", id: "", imageURL: "")
        }
        self.albumId = album.id
        self.albumUri = album.uri
    }
    init?(from resource: Resource<AppleAlbum>) {
        guard let album = resource.attributes else { return nil }
        // Spotify users play the album via URI, apple music users shuffle [song] and enqueue them
        self.albumUri = nil
        self.artist = SociallyArtist(name: album.artistName, id: "", imageURL: "")
        self.name = album.name
        if let urlStr = album.artwork?.url {
            let url = urlStr.replacingOccurrences(of: "{w}x{h}bb", with: "640x640bb")
            self.imageURL = URL(string: url)
        }
        self.albumId = resource.id
    }
}
