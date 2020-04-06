//
//  SociallyMusicServiceTests.swift
//  SociallyMusicServiceTests
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import XCTest
@testable import SociallyMusicService

class SociallyMusicServiceTests: XCTestCase {
    let classToTest = AppleMusicService()
    override func setUp() {
        classToTest.setToken(devToken: "", userToken: "")
    }
    
    func testDecodableAppleLibraryTracks() {
        let expectation = XCTestExpectation(description: "Tracks are decodable from a playlist")
        classToTest.getAllTracksForLibraryPlaylist(playlist: "p.1YeW3zpuRPkEpa") { (result) in
            switch result {
            case .success(let tracks):
                print(tracks)
                expectation.fulfill()
            case .failure(let err):
                print(err)
            }
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    func testTopArtists() {
        let expectation = XCTestExpectation(description: "Heavy rotation history is decodable")
        
        classToTest.getTopArtists { (result) in
            print(result)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTopTracks() {
           let expectation = XCTestExpectation(description: "Heavy rotation history is decodable")
           
           classToTest.getTopTracks { (result) in
               print(result)
               expectation.fulfill()
           }

           wait(for: [expectation], timeout: 20.0)
       }
    
    func testSearch() {
        let expectation = XCTestExpectation(description: "Search objects are decodable")
        
        classToTest.search("drake") { (result) in
            switch result {
            case .success(let search):
                print(search)
                expectation.fulfill()
            case .failure(let err):
                print(err)
            }
        }
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTracksForAlbum() {
        let expectation = XCTestExpectation(description: "album tracks are decodable")
        
        // Kygo singles album
        classToTest.getAlbumTracks("1287220266") { (result) in
            switch result {
            case .success(let tracks):
                print(tracks)
                expectation.fulfill()
            case .failure(let err):
                print(err)
            }
        }
        wait(for: [expectation], timeout: 5.0)
    }
    func testPlaylistTracks() {
        let expectation = XCTestExpectation(description: "kygo playlist is decodable")
        
        // some top kygo singles playlist
        classToTest.getCatalogPlaylistTracks("pl.bbb0d7b0c10b4078bbd5c3450faa31da") { (result) in
            switch result {
            case .success(let search):
                print(search)
                expectation.fulfill()
            case .failure(let err):
                print(err)
            }
        }
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetTopArtistTracks() {
        let kygoId =  "635806094"
        let name = "Kygo"
        
        let expectation = XCTestExpectation(description: "valid tracks are returned")
              classToTest.getArtistProfileTracks(name, artistId: kygoId) { (result) in
                  switch result {
                  case .success(let search):
                      print(search)
                      expectation.fulfill()
                  case .failure(let err):
                      print(err)
                  }
              }
              wait(for: [expectation], timeout: 5.0)
    }
    

}
