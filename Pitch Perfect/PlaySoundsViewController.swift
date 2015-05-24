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

class PlaySoundsViewController: UIViewController, AVAudioPlayerDelegate {

    @IBOutlet weak var stopPlayButton: UIButton!
    
    var audioEngine: AVAudioEngine?
    var audioFile: AVAudioFile?
    var audioPlayer: AVAudioPlayer?
    var receivedAudio: RecordedAudio!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var createError: NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.filePathUrl, error: &createError)
        if let error = createError {
            println("Error: \(error.localizedDescription)")
        } else {
            audioPlayer!.delegate = self
            audioPlayer!.enableRate = true
            // Pre-load the audio file to minimize delay when play() is called:
            audioPlayer!.prepareToPlay()
        }
        
        // Initialize the audioEngine and the file it will use:
        audioEngine = AVAudioEngine()
        if let engine = audioEngine {
            var fileError: NSError?
            audioFile = AVAudioFile(forReading: receivedAudio.filePathUrl, error: &fileError)
            if let error = fileError {
                println("Error intializing AVAudioFile: \(error.localizedDescription)")
            }
        } else {
            println("Error intializing AVAudioEngine")
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

    @IBAction func playChipmunkAudio(sender: UIButton) {
        playAudioAtPitch(900)
    }

    @IBAction func playDarthVaderAudio(sender: UIButton) {
        playAudioAtPitch(-1000)
    }
    
    func playAudioAtPitch(pitch: Float) {
        if let engine = audioEngine {
            engine.stop()
            engine.reset()
            let playerNode: AVAudioPlayerNode? = AVAudioPlayerNode()
            let pitchNode: AVAudioUnitTimePitch? = AVAudioUnitTimePitch()
            if let player = playerNode, timePitch = pitchNode {
                timePitch.pitch = pitch
                engine.attachNode(playerNode)
                engine.attachNode(pitchNode)
                engine.connect(playerNode, to: timePitch, format: nil)
                engine.connect(pitchNode, to:engine.outputNode, format: nil)
                
                player.scheduleFile(audioFile, atTime: nil, completionHandler: {
                    self.stopAudio(nil)
                })
                
                var engineError: NSError?
                engine.startAndReturnError(&engineError)
                if let error = engineError {
                    println("Error starting AVAudioEngine: \(error.localizedDescription)")
                    return
                }
                player.play()
                stopPlayButton.hidden = false
            }            
        }
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
    @IBAction func stopAudio(sender: UIButton?) {
        if let player = audioPlayer {
            player.stop()
            player.currentTime = 0
        }
        if let engine = audioEngine {
            engine.stop()
            engine.reset()
        }
        stopPlayButton.hidden = true
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        stopPlayButton.hidden = true
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
