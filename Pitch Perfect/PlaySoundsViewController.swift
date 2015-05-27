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
    var playing: Bool = false
    
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
        stopEngine()
        playSoundAtRate(0.5)
    }
    
    @IBAction func playFastSound(sender: UIButton) {
        stopEngine()
        playSoundAtRate(2.0)
    }

    @IBAction func playChipmunkAudio(sender: UIButton) {
        stopPlayer()
        playAudioAtPitch(900)
    }

    @IBAction func playDarthVaderAudio(sender: UIButton) {
        stopPlayer()
        playAudioAtPitch(-1000)
    }
    
    // In order of priority, nice-to-have TODOs:
    // TODO: only use engine, not simple player (will considerably clean up code).
    // TODO: add a mixer or two, so that the engine can continue playing while effects are changed.
    // TODO: add echo and reverb effects
    
    func playAudioAtPitch(pitch: Float) {
        stopEngine()
        if let engine = audioEngine, buffer = audioBuffer {
            let playerNode: AVAudioPlayerNode? = AVAudioPlayerNode()
            let pitchNode: AVAudioUnitTimePitch? = AVAudioUnitTimePitch()
            if let player = playerNode, timePitch = pitchNode {
                timePitch.pitch = pitch
                engine.attachNode(playerNode)
                engine.attachNode(pitchNode)
                engine.connect(playerNode, to: timePitch, format: buffer.format)
                engine.connect(pitchNode, to:engine.outputNode, format: buffer.format)
                player.scheduleBuffer(buffer, atTime: nil, options: AVAudioPlayerNodeBufferOptions.Interrupts, completionHandler: {
                    self.stopEngine()
                    // Update the user interface on the main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        self.stopPlayButton.hidden = !self.playing
                    })
                })
                var engineError: NSError?
                playing = true
                engine.startAndReturnError(&engineError)
                if let error = engineError {
                    playing = false
                    println("Error starting AVAudioEngine: \(error.localizedDescription)")
                    return
                }
                player.play()
                
                stopPlayButton.hidden = !playing
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
                playing = true
            }
            stopPlayButton.hidden = !playing
        }
    }
    
    /// Stops the audio from playing and resets the player
    @IBAction func stopAudio(sender: UIButton) {
        stopPlayer()
        stopEngine()
        stopPlayButton.hidden = !playing
    }
    
    func stopPlayer() {
        if let player = audioPlayer {
            player.stop()
            player.currentTime = 0
        }
        playing = false
    }
    
    func stopEngine() {
        if let engine = audioEngine {
            if engine.running {
                engine.stop()
                engine.reset()
            }
        }
        playing = false
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
        playing = false
        stopPlayButton.hidden = !playing
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
