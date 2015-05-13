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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func recordAudio(sender: UIButton) {
        //TODO: record audio
        println("in recordAudio")
        recordingLabel.hidden = !recordingLabel.hidden
    }

}

