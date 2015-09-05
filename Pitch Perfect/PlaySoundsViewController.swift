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
    var echoArray = [AVAudioUnitDelay(), AVAudioUnitDelay(), AVAudioUnitDelay()]

    // An AVAudioBuffer is used instead of an AVAudioFile so that the completionHandler
    // of the AVAudioPlayerNode triggers at the correct time.
    // Reference: http://www.stackoverfliow.com/a/29630124
    var audioBuffer: AVAudioPCMBuffer?
    var receivedAudio: RecordedAudio!
    var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    var playing = false

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
    
    @IBAction func playReverbAudio(sender: UIButton) {
        if let engine = audioEngine, player = playerNode, reverb = reverbUnit {
            playAudioWithEffect({
                engine.connect(player, to: reverb, format: nil)
                reverb.wetDryMix = 50
            })
        }
    }

    @IBAction func playEchoAudio(sender: UIButton) {
        if let engine = audioEngine, player = playerNode, reverb = reverbUnit {
            playAudioWithEffect({
                var offset = 0.0
                for delay in self.echoArray {
                    delay.delayTime = offset
                    engine.connect(player, to: delay, format:nil)
                    offset += 0.1
                }
            })
        }
    }

    @IBAction func stopAudio(sender: UIButton) {
        stopEngine()
        updateStopButton()
    }

    /**
    Plays audio at the given pitch and/or rate.
    
    :param: pitch Float value between -2400 and 2400; default standard pitch is 1.0
    :param: rate Float value between 1/32 and 32; default standard rate is 1.0
     */
    func playAudioAtPitchAndRate(pitch: Float=1, rate: Float=1) {
		if let engine = audioEngine, player = playerNode, timePitch = timePitchUnit, buffer = audioBuffer {
			playAudioWithEffect({
				engine.connect(player, to: timePitch, format: buffer.format)
				timePitch.pitch = pitch
				timePitch.rate = rate
			})
		}
	}

    /**
    Plays the given effect.
    
    This method handles some common logic: ensuring that the engine is running, disconnecting the player
    from any effect nodes it was previously connected to, starts the player playing after running
    the code in the ``effect`` closure, and updating the hidden property of the stop button.
    
    :param: effect closure that connects the player to the desired effect nodes, and configures the effect nodes.

    */
    func playAudioWithEffect(effect: () -> Void) {
        if let engine = audioEngine, player = playerNode {
            if !startEngine(engine) {return}
            engine.disconnectNodeOutput(player)
            effect()
            if !playing { startPlayingAudio() }
        }
        updateStopButton()
    }

    /**
    Start the engine if it's not already running.
    
    :param: engine
    */
    func startEngine(engine: AVAudioEngine) -> Bool{
        if !engine.running {
            var engineError: NSError?
            engine.startAndReturnError(&engineError)
            if let error = engineError {
                println("Error starting AVAudioEngine: \(error.localizedDescription)")
                return false
            }
        }
        return true
    }

    /**
    Schedule the audio buffer and start playing.
    
    A completion handler is set that will update the playing state and ensure that the stopButton hidden property is updated.
    */
	func startPlayingAudio() {
		if let engine = audioEngine, player = playerNode, buffer = audioBuffer {

			player.scheduleBuffer(buffer, atTime: nil, options: AVAudioPlayerNodeBufferOptions.Interrupts, completionHandler: {
				self.playing = false
				// Update the user interface on the main thread
				dispatch_async(dispatch_get_main_queue(), {
					self.updateStopButton()
				})
			})

			player.play()
			playing = true
		}
	}

    /**
    Do the initial engine setup - attach nodes and connect the audio effect nodes to the mixer.
    */
	func setupEngine() {
		if let engine = audioEngine, player = playerNode, timePitch = timePitchUnit, reverb = reverbUnit, buffer = audioBuffer {
			engine.attachNode(player)
			engine.attachNode(timePitch)
			engine.attachNode(reverb)
			engine.mainMixerNode
			engine.connect(timePitch, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: buffer.format)
			engine.connect(reverb, to: engine.mainMixerNode, fromBus: 0, toBus: 1, format: buffer.format)
			for delay in echoArray {
				engine.attachNode(delay)
				engine.connect(delay, to: engine.mainMixerNode, fromBus:0, toBus: engine.mainMixerNode.nextAvailableInputBus, format:buffer.format)
			}
			engine.connect(engine.mainMixerNode, to:engine.outputNode, format:buffer.format)
		}
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
            return buffer
        } else {
            return nil
        }
    }
}
