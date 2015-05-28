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
    
    var audioEngine: AVAudioEngine?
    // An AVAudioBuffer is used instead of an AVAudioFile so that the completionHandler
    // of the AVAudioPlayerNode triggers at the correct time.
    // Reference: http://www.stackoverfliow.com/a/29630124
    var audioBuffer: AVAudioPCMBuffer?
    var receivedAudio: RecordedAudio!
    var audioSession:AVAudioSession = AVAudioSession.sharedInstance()
    var playing: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the audioEngine and the file it will use:
        audioEngine = AVAudioEngine()
        if let engine = audioEngine {
            audioBuffer = bufferFromReceivedAudio()
        } else {
            println("Error intializing AVAudioEngine")
        }
        
        // Make the audio play out of the bottom speaker.
        audioSession.setCategory(
            AVAudioSessionCategoryPlayAndRecord,
            withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker,
            error: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        stopPlayButton.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func playSlowSound(sender: UIButton) {
        playAudioAtPitchAndRate(rate: 0.4)
    }
    
    @IBAction func playFastSound(sender: UIButton) {
        playAudioAtPitchAndRate(rate: 2.2)
    }

    @IBAction func playChipmunkAudio(sender: UIButton) {
        playAudioAtPitchAndRate(rate: 1.1, pitch: 900)
    }

    @IBAction func playDarthVaderAudio(sender: UIButton) {
        playAudioAtPitchAndRate(pitch: -1000)
    }
    
    @IBAction func stopAudio(sender: UIButton) {
        stopEngineAndUpdateStopButton()
    }
    
    // In order of priority, nice-to-have TODOs:
    // TODO: add a mixer or two, so that the engine can continue playing while effects are changed.
    // TODO: add echo and reverb effects

    /**
    Plays audio at the given pitch and/or rate.
    
    :param: pitch Float value between -2400 and 2400; default standard pitch is 1.0
    :param: rate Float value between 1/32 and 32; default standard rate is 1.0
     */
    func playAudioAtPitchAndRate(pitch: Float=0, rate: Float=1) {
        stopEngine()
        if let engine = audioEngine, buffer = audioBuffer {
            let playerNode: AVAudioPlayerNode? = AVAudioPlayerNode()
            let pitchNode: AVAudioUnitTimePitch? = AVAudioUnitTimePitch()
            if let player = playerNode, timePitch = pitchNode {
                timePitch.pitch = pitch
                timePitch.rate = rate
                engine.attachNode(playerNode)
                engine.attachNode(pitchNode)
                engine.connect(playerNode, to: timePitch, format: buffer.format)
                engine.connect(pitchNode, to:engine.outputNode, format: buffer.format)
                player.scheduleBuffer(buffer, atTime: nil, options: AVAudioPlayerNodeBufferOptions.Interrupts, completionHandler: {
                    self.stopEngine()
                    // Update the user interface on the main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        self.updateStopButton()
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
            }
        }
        updateStopButton()
    }

    func stopEngineAndUpdateStopButton() {
        stopEngine()
        updateStopButton()
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
    
    func updateStopButton() {
        stopPlayButton.hidden = !playing
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
