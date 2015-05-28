//
//  RecordedAudio.swift
//  Pitch Perfect
//
//  Created by Brian on 21/05/15.
//  Copyright (c) 2015 truckin'. All rights reserved.
//

import Foundation

class RecordedAudio: NSObject{
    var filePathUrl: NSURL!
    var title: String!

    init(title: String, filePathUrl: NSURL) {
        self.title = title
        self.filePathUrl = filePathUrl
    }
}