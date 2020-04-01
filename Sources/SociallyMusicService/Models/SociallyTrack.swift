//
//  SociallyTrack.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

public struct SociallyTrack: Codable {
    
    public let album: String
    public let artist: String
    public let name: String
    public let isrc: String
    public let context: String
    public let imageURL: String
    
    public init(album: String, artist: String, name: String, isrc: String, context: String, imageURL: String) {
        self.album = album
        self.artist = artist
        self.name = name
        self.isrc = isrc
        self.context = context
        self.imageURL = imageURL
    }
    
    public init?(with data: [String: Any]) {
        guard let album = data["album"] as? String,
            let artist = data["artist"] as? String,
            let name = data["name"] as? String,
            let isrc = data["isrc"] as? String,
            let context = data["context"] as? String,
            let imageURL = data["imageURL"] as? String
            else { return nil }
        
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
    
    //Converting to JSON representation
    public var jsonRepresentation: [String: String] {
        return [
            "album": album,
            "artist": artist,
            "name": name,
            "isrc": isrc,
            "context": context,
            "imageURL": imageURL
        ]
    }
}
