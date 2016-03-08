//
//  String+addText.swift
//  MyLocations
//
//  Created by xyy on 16/2/29.
//  Copyright © 2016年 Razeware. All rights reserved.
//

extension String {
    mutating func addText(text: String?, withSeparator separator: String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}

