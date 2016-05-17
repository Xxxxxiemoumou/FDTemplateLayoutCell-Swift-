//
//  CellModel.swift
//  AutoCellHeight
//
//  Created by 谢某某 on 16/5/9.
//  Copyright © 2016年 WeiBo. All rights reserved.
//

import Foundation

class CellModel
{    
    let content: String
    let username: String
    var imageName: String?
    
    init(content: String, username: String, imageName: String?) {
        self.content = content
        self.username = username
        self.imageName = imageName
    }
    
    var identifier = ""
}