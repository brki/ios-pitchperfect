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
    
    var isRecording = false
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
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        adjustDisplayForRecordingStatus(showRecordingLabel: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        isRecording = true
        adjustDisplayForRecordingStatus()
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        if flag {
            let recordedAudio = RecordedAudio(title: recorder.url.lastPathComponent!, filePathUrl: recorder.url!)
            performSegueWithIdentifier("fromRecordToPlay", sender: recordedAudio)
        } else {
            isRecording = false
            adjustDisplayForRecordingStatus()
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier != "fromRecordToPlay" { return }
        
        let playSoundsVC:PlaySoundsViewController = segue.destinationViewController as! PlaySoundsViewController
        
        playSoundsVC.receivedAudio = sender as! RecordedAudio
    }

    @IBAction func stopRecording(sender: UIButton) {
        audioRecorder.stop()
        var audioSession = AVAudioSession.sharedInstance()
        audioSession.setActive(false, error: nil)
        
        isRecording = false
        adjustDisplayForRecordingStatus(showRecordingLabel: false)
        
    }
    
    func adjustDisplayForRecordingStatus(showRecordingLabel: Bool=false) {
        microphone.enabled = !isRecording
        recordingLabel.hidden = !showRecordingLabel
        recordingLabel.text = isRecording ? recordingText : waitingToRecordText
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

