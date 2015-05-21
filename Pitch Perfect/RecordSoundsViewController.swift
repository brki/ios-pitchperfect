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
    var audioRecorder:AVAudioRecorder!
    
    override func viewDidLoad() {
        println("viewDidLoad")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        adjustDisplayForRecordingStatus()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func recordAudio(sender: UIButton) {
        var session = AVAudioSession.sharedInstance()
        session.setCategory(AVAudioSessionCategoryPlayAndRecord, error: nil)
        
        let filePath = timeStampFilePath()
        
        if filePath == nil {
            println("Error: timeStampFilePath() did not return a valid file URL")
            return
        }
        audioRecorder = AVAudioRecorder(URL: filePath!, settings: nil, error: nil)
        audioRecorder.delegate = self
        audioRecorder.meteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
        
        isRecording = true
        adjustDisplayForRecordingStatus()
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        if flag {
            let recordedAudio = RecordedAudio()
            recordedAudio.filePathUrl = recorder.url
            recordedAudio.title = recorder.url.lastPathComponent
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
        adjustDisplayForRecordingStatus()
        
    }
    
    func adjustDisplayForRecordingStatus() {
        microphone.enabled = !isRecording
        recordingLabel.hidden = !isRecording
        stopButton.hidden = !isRecording
    }
    
    // Get a file URL for a file in the Document directory.
    // The file name is the current timestamp with millisecond precision, with suffix .wav.
    func timeStampFilePath() -> NSURL? {
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        
        let currentDateTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss.SSS"
        let recordingName = formatter.stringFromDate(currentDateTime)+".wav"
        let pathArray = [dirPath, recordingName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        println(filePath)
        return filePath
    }
}

