//
//  CustomCell.swift
//  AutoCellHeight
//
//  Created by 谢某某 on 16/5/9.
//  Copyright © 2016年 WeiBo. All rights reserved.
//

import UIKit

public let ___identifier = "CustomCell"

class CustomCell: UITableViewCell {


    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var contentImageV: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    var model: CellModel? = nil {
        didSet{
            contentLabel.text = model?.content
            userNameLabel.text = model?.username
            if let name = model?.imageName where !name.isEmpty {
                contentImageV.image = UIImage(named: name)
            }else{
                contentImageV.image = nil
            }
        }
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        var height: CGFloat = 0
        height += self.contentLabel.sizeThatFits(size).height
        height += self.contentImageV.sizeThatFits(size).height
        height += self.userNameLabel.sizeThatFits(size).height
        height += 40 // margins
        return CGSizeMake(size.width, height);
    }
    
}







