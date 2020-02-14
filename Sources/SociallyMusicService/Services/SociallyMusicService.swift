//
//  SociallyMusicService.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

class SociallyMusicService {
    
    public static let shared = SociallyMusicService()
    
    private var isAppleUser: Bool {
        return true
    }
    
    public func addToPlaylist(playlistId: String, isrc: String, result: @escaping (Result<[String: String], APIServiceError>) -> Void) {
        if isAppleUser {
            searchByISRC(isrc: isrc) { (context) in
                AppleMusicService.shared.addSong(context, to: playlistId, completion: result)
            }
        } else {
            searchByISRC(isrc: isrc) { (context) in
                 SpotifyService.shared.addToPlaylist(playlistId: playlistId, track: context, result: result)
            }
        }
    }
    
    public func fetchTopArtists(result: @escaping (Result<PagingObject<Artist>, APIServiceError>) -> Void) {
        if isAppleUser {
            // not supported by apple
            result(.failure(.noData))
        } else {
            SpotifyService.shared.fetchTopArtists(result: result)
        }
    }

     public func fetchTopSongs(result: @escaping (Result<PagingObject<TrackItem>, APIServiceError>) -> Void) {
        if isAppleUser {
            // not supported by apple
            result(.failure(.noData))
        } else {
            SpotifyService.shared.fetchTopSongs(result: result)
        }
    }
    
    public func fetchRecentSongs(limit: Int = 10, result: @escaping (Result<PagingObject<PlayHistoryObject>, APIServiceError>) -> Void) {
        if isAppleUser {
            //AppleMusicService
        } else {
            SpotifyService.shared.fetchRecentlyPlayed(result: result)
        }
    }
    
    public func fetchCurrentUser(completion: @escaping (String) -> Void) {
        if isAppleUser {
            //AppleMusicService
        } else {
            SpotifyService.shared.fetchCurrentUser(completion: completion)
        }
    }
    
    public func fetchCurrentTrack(completion: @escaping (Result<SociallyTrack, APIServiceError>) -> Void) {
        if isAppleUser {
            AppleMusicService.shared.fetchCurrentTrack { (result) in
                completion(result)
            }
        } else {
            SpotifyService.shared.fetchCurrentTrack { (result) in
                completion(result)
            }
        }
    }
    
    public func playback(action: PlaybackState, result: @escaping (Result<Bool, APIServiceError>) -> Void = { _ in }) {
        if isAppleUser {
            //AppleMusicService.shared.playback(action: action, result: result)
        } else {
            SpotifyService.shared.playback(action: action, result: result)
        }
    }
    
    public func playSong(context: String, otherContext: String? = nil, completion: @escaping (Bool) -> Void = {_ in }) {
       if isAppleUser {
           AppleMusicService.shared.playSong(context: context, result: completion)
       } else {
           SpotifyService.shared.playSong(context: context, result: completion)
       }
    }
    
    public func playSongFromInfo(isrc: String, appleTrackContext: String, spotifyTrackContext: String, completion: @escaping (Bool) -> Void = {_ in }) {
        if isAppleUser {
            if appleTrackContext != "" {
                playSong(context: appleTrackContext, completion: completion)
            } else {
                searchByISRC(isrc: isrc) { (trackContext) in
                    self.playSong(context: trackContext, completion: completion)
                }
            }
        } else {
            if spotifyTrackContext != "" {
                playSong(context: spotifyTrackContext, completion: completion)
            } else {
                searchByISRC(isrc: isrc) { (trackContext) in
                    self.playSong(context: trackContext, completion: completion)
                }
            }
        }
    }
    
    public func searchByISRC(isrc: String, completion: @escaping (String) -> Void) {
        if isAppleUser {
            AppleMusicService.shared.searchByISRC(isrc: isrc, completion: completion)
        } else {
            SpotifyService.shared.searchByISRC(isrc: isrc, completion: completion)
        }
    }
    
    func getCurrUserPlaylists(limit: Int = 50, offset: Int = 0, url: URL? = nil, result: @escaping (Result<PagingObject<Playlist>, APIServiceError>) -> Void) {
        if isAppleUser {
            fatalError("Please use getAll playlists function, as apple doesn't allow grabbing other users playlists.")
        } else {
            SpotifyService.shared.getUserPlaylists(result: result)
        }
    }
    
    func getAllPlaylists(of userId: String, result: @escaping (Result<[SociallyPlaylist], APIServiceError>) -> Void) {
        if isAppleUser {
            AppleMusicService.shared.getAllPlaylists(completion: result)
        } else {
            SpotifyService.shared.getAllPlaylists(of: userId, result: result)
        }
    }
    
    func getAllSongsFor(playlist: String, completion: @escaping (Result<[SociallyTrack], Error>) -> Void) {
        if isAppleUser {
            AppleMusicService.shared.getAllSongsFor(playlist: playlist, completion: completion)
        } else {
            SpotifyService.shared.getAllTracksForPlaylist(playlist, result: completion)
        }
    }
    
    func deleteFromPlaylist(_ playlistId: String, trackId: String, result: @escaping (Result<[String: String], APIServiceError>) -> Void = { _ in }) {
        if isAppleUser {
            // not supported by apple
        } else {
            SpotifyService.shared.deleteFromPlaylist(playlistId, trackId: trackId, result: result)
        }
    }
}
