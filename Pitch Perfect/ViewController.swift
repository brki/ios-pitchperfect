//
//  ViewController.swift
//  Pitch Perfect
//
//  Created by Brian on 11/05/15.
//  Copyright (c) 2015 truckin'. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var stopRecordingButton: UIButton!
    
    var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func recordAudio(sender: UIButton) {
        if !isRecording {
            //TODO: record audio
            println("in recordAudio")
            isRecording = true
            recordingLabel.hidden = false
            stopRecordingButton.hidden = false
        }
    }

    @IBAction func stopRecording(sender: UIButton) {
        //TODO: stop audio recording
        recordingLabel.hidden = true
        stopRecordingButton.hidden = true
        isRecording = false
    }
}

