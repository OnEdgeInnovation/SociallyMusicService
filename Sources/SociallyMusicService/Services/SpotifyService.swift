//
//  SpotifyService.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

class SpotifyService {
    
    public static let shared = SpotifyService()
    private let urlSession = URLSession.shared
    private let baseURL = URL(string: "https://api.spotify.com/v1/")!
    
    var token = ""
    
    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()
    
    private func fetchResources<T: Decodable>(request: URLRequest, completion: @escaping (Result<T, APIServiceError>) -> Void) {
        var newRequest = request
        //Add headers
        newRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        newRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        newRequest.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        //Make call
        self.urlSession.dataTask(with: newRequest) { (result: Result<(URLResponse, Data), Error> ) in
            switch result {
            case .success(let (response, data)):
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, 200..<299 ~= statusCode else {
                    print(response)
                    completion(.failure(.invalidResponse))
                    return
                }
                do {
                    let values = try self.jsonDecoder.decode(T.self, from: data)
                    completion(.success(values))
                } catch let error {
                    print(error)
                    completion(.failure(.decodeError))
                }
            case .failure:
                completion(.failure(.apiError))
            }
        }.resume()
    }
    
    private func sendRequestNoPayload(request: URLRequest, result: @escaping (Result<Bool, APIServiceError>) -> Void) {
        var newRequest = request
        //Add headers
        newRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        newRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        newRequest.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        //Perform call
        self.urlSession.dataTask(with: newRequest) { data, response, error in
            if error != nil || data == nil {
                result(.failure(.apiError))
                return
            }
            guard let response = response as? HTTPURLResponse, (204 == response.statusCode || 200 == response.statusCode) else {
                result(.failure(.invalidResponse))
                return
            }
            result(.success(true))
        }.resume()
    }
    
    public func searchByISRC(isrc: String, completion: @escaping (String) -> Void) {
        var component = URLComponents(string: baseURL.appendingPathComponent("search").absoluteString)
                
        component?.queryItems = [
            URLQueryItem(name: "q", value: "isrc:\(isrc)"),
            URLQueryItem(name: "type", value: "track")
        ]

        guard let url = component?.url else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        fetchResources(request: request) { (result: Result<TrackPagingObject<TrackItem>, APIServiceError>) in
            switch result {
            case .success(let pagingObj):
                completion(pagingObj.tracks.items[0].uri)
            case .failure:
                completion("")
            }
        }
    }
    
    public func addToPlaylist(playlistId: String, track: String, result: @escaping (Result<[String: String], APIServiceError>) -> Void) {
        let params: [URLQueryItem] = [
            URLQueryItem(name: "uris", value: "\(track)")
        ]
        
        var component = URLComponents(string: baseURL.appendingPathComponent("playlists/\(playlistId)/tracks").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        
        var urlreq = URLRequest(url: finURL)
        urlreq.httpMethod = "POST"
        fetchResources(request: urlreq, completion: result)
    }
    
    public func fetchTopArtists(limit: Int = 20, offset: Int = 0, timeRange: TimeRange = .longTerm, result: @escaping (Result<PagingObject<Artist>, APIServiceError>) -> Void) {
        
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "time_range", value: timeRange.rawValue)
        ]
        var component = URLComponents(string: baseURL.appendingPathComponent("me/top/artists").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        let urlreq = URLRequest(url: finURL)
        fetchResources(request: urlreq, completion: result)
        
    }
    
    public func fetchTopSongs(limit: Int = 20, offset: Int = 0, timeRange: TimeRange = .mediumTerm, result: @escaping (Result<PagingObject<TrackItem>, APIServiceError>) -> Void) {
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "time_range", value: timeRange.rawValue)
        ]
        
        var component = URLComponents(string: baseURL.appendingPathComponent("me/top/tracks").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        let urlreq = URLRequest(url: finURL)
        fetchResources(request: urlreq, completion: result)
    }
    
    public func fetchRecentlyPlayed(limit: Int = 10, result: @escaping (Result<PagingObject<PlayHistoryObject>, APIServiceError>) -> Void) {
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        var component = URLComponents(string: baseURL.appendingPathComponent("me/player/recently-played").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        let urlreq = URLRequest(url: finURL)
        fetchResources(request: urlreq, completion: result)
    }
    
    public func fetchCurrentUser(completion: @escaping (String) -> Void) {
        //Get proper URL
        let url = baseURL.appendingPathComponent("me")
        let request = URLRequest(url: url)
        //Make the call
        fetchResources(request: request) { (result: Result<UserResult, APIServiceError>) in
            switch result {
            case .success(let user):
                completion(user.id)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    public func fetchCurrentTrack(completion: @escaping (Result<SociallyTrack, APIServiceError>) -> Void) {
        //Get proper URL
        let url = baseURL.appendingPathComponent("me/player/currently-playing")
        let request = URLRequest(url: url)
        //Make the call
        fetchResources(request: request) { (result: Result<TrackResult, APIServiceError>) in
            switch result {
            case .success(let trackResult):
                let track = SociallyTrack(album: trackResult.item.album.name, artist: trackResult.item.artists[0].name, name: trackResult.item.name, isrc: trackResult.item.externalIds?.isrc ?? "", context: trackResult.item.uri, imageURL: trackResult.item.album.images?[0].url.absoluteString ?? "")
                completion(.success(track))
            case .failure:
                completion(.failure(.apiError))
            }
        }
    }
    
    public func playback(action: PlaybackState, result: @escaping (Result<Bool, APIServiceError>) -> Void = { _ in }) {
        //Get proper URL
        let url = baseURL.appendingPathComponent("me/player/"+action.rawValue)
        var request = URLRequest(url: url)
        switch action {
        case .play, .pause :
            request.httpMethod = "PUT"
            sendRequestNoPayload(request: request, result: result)
        default :
            request.httpMethod = "POST"
            sendRequestNoPayload(request: request, result: result)
        }
    }
    
    public func playSong(context: String, result: @escaping (Bool) -> Void) {
        result(true)
    }
    
    func getUserPlaylists(of userId: String? = nil, limit: Int = 50, offset: Int = 0, url: URL? = nil, result: @escaping (Result<PagingObject<Playlist>, APIServiceError>) -> Void) {
        if let url = url {
            fetchResources(request: URLRequest(url: url), completion: result)
            return
        }
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        var component: URLComponents?
        if let userId = userId {
            component = URLComponents(string: baseURL.appendingPathComponent("users/\(userId)/playlists").absoluteString)
        } else {
            component = URLComponents(string: baseURL.appendingPathComponent("me/playlists").absoluteString)
        }
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        let urlreq = URLRequest(url: finURL)
        fetchResources(request: urlreq, completion: result)
    }
    
    func getAllPlaylists(of userId: String? = nil, result: @escaping (Result<[SociallyPlaylist], APIServiceError>) -> Void) {
        var arr = [Playlist]()
        var url: URL?
        let group = DispatchGroup()
        var shouldContinue = true
        while shouldContinue {
            group.enter()
            getUserPlaylists(of: userId, url: url) { (actResult: Result<PagingObject<Playlist>, APIServiceError>) in
                switch actResult {
                case .success(let pagingObj):
                    arr += pagingObj.items
                    if let nextUrl = pagingObj.nextUrl {
                        url = nextUrl
                    } else {
                        shouldContinue = false
                        result(.success(arr.map({SociallyPlaylist(from: $0)})))
                    }
                case .failure:
                    shouldContinue = false
                    result(.failure(.invalidResponse))
                }
                group.leave()
            }
            group.wait()
        }
    }
      
    func getTracksForPlaylist(_ playlistId: String, url: URL?, result: @escaping (Result<PagingObject<PlaylistTrack>, APIServiceError>) -> Void) {
        if let url = url {
            fetchResources(request: URLRequest(url: url), completion: result)
            return
        }
        
        let component = URLComponents(string: baseURL.appendingPathComponent("playlists/\(playlistId)/tracks").absoluteString)
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        let urlreq = URLRequest(url: finURL)
        fetchResources(request: urlreq, completion: result)
    }
    
    func getAllTracksForPlaylist(_ playlistId: String, result: @escaping (Result<[SociallyTrack], Error>) -> Void) {
        var arr = [TrackItem]()
        var url: URL?
        let group = DispatchGroup()
        var shouldContinue = true
        
        while shouldContinue {
            group.enter()
            getTracksForPlaylist(playlistId, url: url) { (actResult) in
                switch actResult {
                case .success(let pagObj):
                    arr += pagObj.items.compactMap({$0.track})
                    if let nextUrl = pagObj.nextUrl {
                        url = nextUrl
                    } else {
                        shouldContinue = false
                        result(.success(arr.map({SociallyTrack(from: $0)})))
                    }
                case .failure:
                    shouldContinue = false
                    result(.failure(APIServiceError.invalidResponse))
                }
                group.leave()
            }
            group.wait()
        }
    }
    
    func deleteFromPlaylist(_ playlistId: String, trackId: String, result: @escaping (Result<[String: String], APIServiceError>) -> Void) {
        let params: [URLQueryItem] = [
            URLQueryItem(name: "tracks", value: "\([["uri": trackId]])")
        ]
        var component = URLComponents(string: baseURL.appendingPathComponent("playlists/\(playlistId)/tracks").absoluteString)
        
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(APIServiceError.invalidCompiledURL))
            return
        }
        let urlreq = URLRequest(url: finURL)
        fetchResources(request: urlreq, completion: result)
    }
}
