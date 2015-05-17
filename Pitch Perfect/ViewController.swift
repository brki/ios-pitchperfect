//
//  ViewController.swift
//  Pitch Perfect
//
//  Created by Brian on 11/05/15.
//  Copyright (c) 2015 truckin'. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var microphone: UIButton!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var stopButton: UIButton!
    
    var isRecording = false
    
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
        //TODO: record audio
        println("in recordAudio")
        isRecording = true
        adjustDisplayForRecordingStatus()
    }

    @IBAction func stopRecording(sender: UIButton) {
        //TODO: stop audio recording
        isRecording = false
        adjustDisplayForRecordingStatus()
    }
    
    func adjustDisplayForRecordingStatus() {
        microphone.enabled = !isRecording
        recordingLabel.hidden = !isRecording
        stopButton.hidden = !isRecording
    }
}

