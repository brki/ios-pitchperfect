//
//  RecordSoundsViewController.swift
//  Pitch Perfect
//
//  Created by Brian on 11/05/15.
//  Copyright (c) 2015 truckin'. All rights reserved.
//

import AVFoundation
import UIKit

class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {

    @IBOutlet weak var microphone: UIButton!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var stopButton: UIButton!
    
    var audioRecorder: AVAudioRecorder!
    // Directory which will be recreated every time a recording is made, and in which
    // the recorded audio will be stored:
    var audioFileDirectoryUrl: NSURL!
    var recordingText = "Recording"
    var waitingToRecordText = "Tap to record"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioFileDirectoryUrl = NSURL.fileURLWithPathComponents([
            NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String,
            "recordedAudio"
        ])
    }
    
    override func viewWillAppear(animated: Bool) {
        adjustDisplayForRecordingStatus(recording: false, showRecordingLabel: true)
    }
    
    @IBAction func recordAudio(sender: UIButton) {
        var session = AVAudioSession.sharedInstance()
        session.setCategory(AVAudioSessionCategoryPlayAndRecord, error: nil)
        
        let fileUrl = audioFileUrl()
        
        audioRecorder = AVAudioRecorder(URL: fileUrl, settings: nil, error: nil)
        audioRecorder.delegate = self
        audioRecorder.meteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
        
        adjustDisplayForRecordingStatus(recording: true)
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        if flag {
            let recordedAudio = RecordedAudio(title: recorder.url.lastPathComponent!, filePathUrl: recorder.url!)
            performSegueWithIdentifier("fromRecordToPlay", sender: recordedAudio)
        } else {
            adjustDisplayForRecordingStatus(recording: false)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier != "fromRecordToPlay" { return }
        
        let playSoundsVC:PlaySoundsViewController = segue.destinationViewController as! PlaySoundsViewController
        
        playSoundsVC.receivedAudio = sender as! RecordedAudio
    }

    @IBAction func stopRecording(sender: UIButton) {
        audioRecorder.stop()
        AVAudioSession.sharedInstance()?.setActive(false, error: nil)
        adjustDisplayForRecordingStatus(recording: true, showRecordingLabel: false)
    }
    
    func adjustDisplayForRecordingStatus(recording isRecording: Bool, showRecordingLabel: Bool=false) {
        recordingLabel.hidden = !showRecordingLabel
        recordingLabel.text = isRecording ? recordingText : waitingToRecordText
        microphone.enabled = !isRecording
        stopButton.hidden = !isRecording
    }
    
    // Get a file URL for a file in a subdirectory of the app's Documents directory.
    // Every time this method is called, this subdirectory is deleted and recreated.
    // This avoids keeping files which are never used again.
    // The file name is the current timestamp with millisecond precision, with suffix .wav.
    func audioFileUrl() -> NSURL? {
        if recreateAudioFileDirectory() {
            let currentDateTime = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "ddMMyyyy-HHmmss.SSS"
            let recordingName = formatter.stringFromDate(currentDateTime)+".wav"
            let filePath = audioFileDirectoryUrl.URLByAppendingPathComponent(recordingName)
            return filePath
        } else {
            return nil
        }
    }
    
    func recreateAudioFileDirectory() -> Bool {
        let fileManager = NSFileManager.defaultManager()
        // Remove the directory and it's contents if it exists:
        fileManager.removeItemAtURL(audioFileDirectoryUrl, error: nil)
        var dirCreationError: NSError?
        fileManager.createDirectoryAtURL(audioFileDirectoryUrl, withIntermediateDirectories: false, attributes: nil, error: &dirCreationError)
        if let error = dirCreationError {
            println("Error creating directory '\(audioFileDirectoryUrl)': \(error.localizedDescription)")
            return false
        }
        return true
    }
}

