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
    // An AVAudioBuffer is used instead of an AVAudioFile so that the completionHandler
    // of the AVAudioPlayerNode triggers at the correct time.
    // Reference: http://www.stackoverfliow.com/a/29630124
    var audioBuffer: AVAudioPCMBuffer?
    var audioPlayer: AVAudioPlayer?
    var receivedAudio: RecordedAudio!
    var audioSession:AVAudioSession = AVAudioSession.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var createError: NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.filePathUrl, error: &createError)
        if let error = createError {
            println("Error: \(error.localizedDescription)")
        }
        
        if let player = audioPlayer {
            player.delegate = self
            player.enableRate = true
            // Pre-load the audio file to minimize delay when play() is called:
            player.prepareToPlay()
        }
        
        // Initialize the audioEngine and the file it will use:
        audioEngine = AVAudioEngine()
        if let engine = audioEngine {
            audioBuffer = bufferFromReceivedAudio()
        } else {
            println("Error intializing AVAudioEngine")
        }
        
        // Make the audio play out of the bottom speaker.
        audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker, error: nil)
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
        if let engine = audioEngine, buffer = audioBuffer {
            engine.stop()
            engine.reset()
            let playerNode: AVAudioPlayerNode? = AVAudioPlayerNode()
            let pitchNode: AVAudioUnitTimePitch? = AVAudioUnitTimePitch()
            if let player = playerNode, timePitch = pitchNode {
                timePitch.pitch = pitch
                engine.attachNode(playerNode)
                engine.attachNode(pitchNode)
                engine.connect(playerNode, to: timePitch, format: buffer.format)
                engine.connect(pitchNode, to:engine.outputNode, format: buffer.format)
                
                player.scheduleBuffer(buffer, atTime: nil, options: nil, completionHandler: {
                    // Update the user interface on the main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        // Do not explicitly stop the audio by calling stopAudio(), because this handler is
                        // called before the audio has finished playing.  Bug or documentation failure, I guess.
                        self.stopPlayButton.hidden = true
                    })
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
    @IBAction func stopAudio(sender: UIButton) {
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
    
    func bufferFromReceivedAudio() -> AVAudioPCMBuffer? {
        var fileError: NSError?
        let audioFile = AVAudioFile(forReading: receivedAudio.filePathUrl, commonFormat: AVAudioCommonFormat.PCMFormatFloat32, interleaved: false, error: &fileError)
        if let error = fileError {
            println("Error intializing AVAudioFile: \(error.localizedDescription)")
        }
        
        if let file = audioFile {
            let buffer = AVAudioPCMBuffer(PCMFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
            file.readIntoBuffer(buffer, error: nil)
            return buffer
        } else {
            return nil
        }
    }
    
    
    // AVAudioPlayerDelegate method:
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
