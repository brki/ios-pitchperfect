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
    var playerNode: AVAudioPlayerNode? = AVAudioPlayerNode()
    var timePitchUnit: AVAudioUnitTimePitch? = AVAudioUnitTimePitch()
    var reverbUnit: AVAudioUnitReverb? = AVAudioUnitReverb()

    // An AVAudioBuffer is used instead of an AVAudioFile so that the completionHandler
    // of the AVAudioPlayerNode triggers at the correct time.
    // Reference: http://www.stackoverfliow.com/a/29630124
    var audioBuffer: AVAudioPCMBuffer?
    var receivedAudio: RecordedAudio!
    var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    var playing = false
    var interrupted = false
    var sampleRate: Double = 0
    var duration: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the audioEngine and the file it will use:
        audioEngine = AVAudioEngine()
        if let engine = audioEngine {
            audioBuffer = bufferFromReceivedAudio()
            setupEngine()
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
        playAudioAtPitchAndRate(pitch: 900)
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
    func playAudioAtPitchAndRate(pitch: Float=1, rate: Float=1) {

        if let engine = audioEngine, player = playerNode, timePitch = timePitchUnit {
            if !engine.running {
                var engineError: NSError?
                engine.startAndReturnError(&engineError)
                if let error = engineError {
                    println("Error starting AVAudioEngine: \(error.localizedDescription)")
                    return
                }
            }
            interrupted = true
            if playing {
                if let playerTime = player.playerTimeForNodeTime(player.lastRenderTime) {
                    let position = Double(playerTime.sampleTime) / sampleRate
                    let newSampleTime = AVAudioFramePosition(sampleRate * position)
                    var length = Double(duration) - position
                    var framestoplay = AVAudioFrameCount(Double(playerTime.sampleRate) * length)
                    //TODO: read https://github.com/danielmj/AEAudioPlayer/issues/1
                    //TODO: perhaps simply use file instead of buffer, so can use scheduleSegment.  in completionhandler,
                    //      find out how much time is left before end of audio, and schedule a stop for that time.
                    //TODO: or, just give up on this, and let the audio restart each time a button it tapped.
                    player.scheduleSegment(audioFile, startingFrame: newsampletime, frameCount: framestoplay, atTime: nil,completionHandler: nil)
                    println("position: \(position)")
                }
            }
            engine.disconnectNodeOutput(player)
            engine.connect(player, to: timePitch, format: nil)
            timePitch.pitch = pitch
            timePitch.rate = rate
            println("playing in playAudioAtPitch...: \(player.playing)")
            println("lastRenderTime:in playAudioAtPitch...: \(player.lastRenderTime)")
            if !playing { startPlayingAudio() }
            interrupted = false
        }
        updateStopButton()
    }

    func startPlayingAudio() {
        if let engine = audioEngine, player = playerNode, buffer = audioBuffer {

            player.scheduleBuffer(buffer, atTime: nil, options: AVAudioPlayerNodeBufferOptions.Interrupts, completionHandler: {

                //TODO: how to differentiate between end-of-file reached and was-interrupted?
//                self.playing = false
                // Update the user interface on the main thread
//                engine.disconnectNodeOutput(player)


                println("\(player.nodeTimeForPlayerTime(player.lastRenderTime))")
                println("\(player.playerTimeForNodeTime(player.lastRenderTime))")
                dispatch_async(dispatch_get_main_queue(), {
                    println("lastRenderTime: \(player.lastRenderTime)")
                    println("playing: \(player.playing)")
                    println("interrrupted \(self.interrupted)")
                    self.updateStopButton()
                })
            })

            player.play()
            playing = true
        }
    }

    func setupEngine() {
        if let engine = audioEngine, player = playerNode, timePitch = timePitchUnit, reverb = reverbUnit {
            engine.attachNode(player)
            engine.attachNode(timePitch)
            engine.attachNode(reverb)
            engine.connect(timePitch, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: nil)
            engine.connect(reverb, to: engine.mainMixerNode, fromBus: 0, toBus: 1, format: nil)

        }
    }

    func stopEngineAndUpdateStopButton() {
        stopEngine()
        updateStopButton()
    }

    /**
    Stops the ``audioEngine`` from playing and sets ``self.playing`` to ``false``.
    */
    func stopEngine() {
        if let engine = audioEngine {
            if engine.running {
                engine.stop()
                engine.reset()
            }
        }
        playing = false
    }

    /**
    Toggles the visibility of the stop button based on the current value of ``playing``.
    */
    func updateStopButton() {
        stopPlayButton.hidden = !playing
    }

    /**
    Creates an ``AVAudioPCMBuffer`` from the file identified by ``self.receivedAudio.filePathUrl``.
    */
    func bufferFromReceivedAudio() -> AVAudioPCMBuffer? {
        var fileError: NSError?
        let audioFile = AVAudioFile(forReading: receivedAudio.filePathUrl, commonFormat: AVAudioCommonFormat.PCMFormatFloat32, interleaved: false, error: &fileError)
        if let error = fileError {
            println("Error intializing AVAudioFile: \(error.localizedDescription)")
        }
        
        if let file = audioFile {
            let buffer = AVAudioPCMBuffer(PCMFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
            file.readIntoBuffer(buffer, error: nil)
            self.sampleRate = buffer.format.sampleRate
            self.duration = Double(file.length) / self.sampleRate
            return buffer
        } else {
            return nil
        }
    }
}
