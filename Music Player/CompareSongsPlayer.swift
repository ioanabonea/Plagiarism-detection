//
//  CompareSongsPlayer.swift
//  Music Player
//
//  Created by Bonea Ioana on 6/28/17.
//  Copyright © 2017 Sem. All rights reserved.
//

import AVKit
import Foundation
import UIKit

class CompareSongsPlayer: AVPlayerViewController, AVPlayerViewControllerDelegate{
    
    var playerItem: AVPlayerItem!
    var songIdentifier: String!
    
    var start: CMTime!
    var end: CMTime!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let filePath = MiscFuncs.grabFilePath("\(songIdentifier!).mp4")
        var url = URL(fileURLWithPath: filePath)
        
        if(!FileManager.default.fileExists(atPath: filePath)){
            url = URL(fileURLWithPath: MiscFuncs.grabFilePath("\(songIdentifier!).m4a"))
        }
        
        self.player = AVPlayer(url: url)
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        }catch{}

    }
    
    func seekToTime(){
        self.player?.seek(to: start)
    }
    
    func play(){
        self.player?.play()
        self.player?.addBoundaryTimeObserver( forTimes:[NSValue.init(time:self.end)], queue:nil ){
            self.player?.pause()
        }
    }

}
