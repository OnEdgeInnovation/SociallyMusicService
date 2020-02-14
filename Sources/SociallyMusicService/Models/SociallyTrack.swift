//
//  SociallyTrack.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

struct SociallyTrack: Codable {
    
    init(album: String, artist: String, name: String, isrc: String, context: String, imageURL: String) {
        self.album = album
        self.artist = artist
        self.name = name
        self.isrc = isrc
        self.context = context
        self.imageURL = imageURL
    }
    
    init(from track: TrackItem) {
        self.album = track.album.name
        if !track.artists.isEmpty {
            self.artist = track.artists[0].name
        } else {
            self.artist = ""
        }
        self.name = track.name
        self.context = track.uri
        self.imageURL = track.album.images?[0].url.absoluteString ?? ""
        self.isrc = track.externalIds?.isrc ?? ""
    }
    
    let album: String
    let artist: String
    let name: String
    let isrc: String
    let context: String
    let imageURL: String
}
