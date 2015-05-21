//
//  PlaySoundsViewController.swift
//  Pitch Perfect
//
//  Created by Brian on 17/05/15.
//  Copyright (c) 2015 truckin'. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class PlaySoundsViewController: UIViewController {

    @IBOutlet weak var stopPlayButton: UIButton!
    
    var audioPlayer: AVAudioPlayer?
    var receivedAudio: RecordedAudio!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var createError: NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.filePathUrl, error: &createError)
        if let error = createError {
            println("Error: \(error.localizedDescription)")
        } else {
            audioPlayer!.enableRate = true
            // Pre-load the audio file to minimize delay when play() is called:
            audioPlayer!.prepareToPlay()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        stopPlayButton.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func playSlowSound(sender: UIButton) {
        playSoundAtRate(0.5)
    }

    @IBAction func playFastSound(sender: UIButton) {
        playSoundAtRate(2.0)
    }

    /// Play sound at provided rate (between 0.5 and 2.0)
    /// and shows the stopPlayButton.
    func playSoundAtRate(rate: Double) {
        if let player = audioPlayer {
            player.rate = Float(rate)
            // Stopping and starting the player when it's already playing makes the audio
            // a bit choppy, so don't do that.
            if (!player.playing) {
                player.play()
            }
            stopPlayButton.hidden = false
        }
    }
    
    /// Stops the audio from playing and resets the player's currentTime to 0
    @IBAction func stopAudio(sender: UIButton) {
        if let player = audioPlayer {
            player.stop()
            player.currentTime = 0
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
