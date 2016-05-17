//
//  ViewController.swift
//  AutoCellHeight
//
//  Created by 谢某某 on 16/5/9.
//  Copyright © 2016年 WeiBo. All rights reserved.
//

import UIKit

func *(lhs: String, rhs: Int) -> String {
    guard rhs > 0 else { return lhs }
    return Array(0...rhs).reduce("", combine: { $0.0 + "\($0.1)" + lhs })
}

let imageArr = ["breaddoge", "doge", "forkingdog",
                "phil", "sark", "sinojerk", "sunnyxx"]

class ViewController: UITableViewController {
    
    @IBOutlet weak var semegmented: UISegmentedControl! {
        didSet{
            semegmented.selectedSegmentIndex = 1
        }
    }
    
    private var jsonModel = [CellModel]()
    private var dataSource = [[CellModel]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadData {[unowned self] in
            self.dataSource.append($0)
            self.tableView.reloadData()
        }
    }
  
    private func loadData(then t: ([CellModel]) -> Void) {
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            let count = 50
            var data = [CellModel]()
            for index in 0..<count
            {
                let content = "\n"
                let userName = "\(index)"
                let image = imageArr[Int(arc4random_uniform(UInt32(imageArr.count)))]
                let model = CellModel(content: content*index, username: userName, imageName: image)
                model.identifier = String(index)
                data.append(model)
                self.jsonModel.append(model)
            }
            dispatch_sync(dispatch_get_main_queue()) { t(data) }
        }
    }
    
    @IBAction func refresh(sender: UIRefreshControl) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            
            let count = arc4random_uniform(5)
            for _ in 0...count {
                self.dataSource[0].insert(self.randomModel(), atIndex: 0)
            }
            self.tableView.reloadData()
            sender.endRefreshing()
        }
    }
    @IBAction func actions(sender: UIBarButtonItem) {
        UIActionSheet.init(title: "Actions", delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: nil, otherButtonTitles: "Insert a row", "Delete a row",
            "Insert a section", "Delete a section").showInView(self.view)
    }
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
//        cell.xlj_isFrameLayout = true
        
        if indexPath.row % 2 == 0 {
            cell.accessoryType = .DisclosureIndicator
        } else {
            cell.accessoryType = .Checkmark
        }
        
        if cell is CustomCell {
            (cell as! CustomCell).model = dataSource[indexPath.section][indexPath.row]
        }
    }
}

extension ViewController: UIActionSheetDelegate {
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        let selector = [
            #selector(insertRow),
            #selector(deleteRow),
            #selector(insertSection),
            #selector(deleteSection)
        ]
        if buttonIndex != 0 {
            self.performSelector(selector[buttonIndex-1])
        }
    }
    
    private func randomModel() -> CellModel {
        
        let random = randomNumber(self.jsonModel.count)
        print("random - \(random)")
        return self.jsonModel[random]
    }
    
    private func randomColor() -> UIColor {
        let r = CGFloat(arc4random_uniform(256)) / 255.0
        let g = CGFloat(arc4random_uniform(256)) / 255.0
        let b = CGFloat(arc4random_uniform(256)) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    private func randomNumber(num: Int) -> Int {
        return Int(arc4random_uniform(UInt32(num)))
    }
    
    func insertRow() {
        if self.dataSource.isEmpty {
            self.insertSection()
        }else {
            let random = randomNumber(self.dataSource.count)
            var section = self.dataSource[random]
            
            let count = min(5, randomNumber(self.jsonModel.count))
            var indexPaths = [NSIndexPath]()
            
            for i in 0..<count {
                section.append(self.randomModel())
                indexPaths.append(NSIndexPath(forRow: i, inSection: random))
            }
            print("insertRow: section:\(random)")
            self.dataSource[random] = section
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
          
        }
    }
    
    func deleteRow() {
        let random = randomNumber(self.dataSource.count)
        var section = self.dataSource[random]
        
        if !section.isEmpty {
            
            let count = min(10, randomNumber(section.count))
            var indexPaths = [NSIndexPath]()
            
            var nums = Set<Int>()
            for i in 0..<count {
                nums.insert(randomNumber(section.count - i))
            }
            
            print("deleteRow: section:\(random), rows:\(nums)")

            nums.sort(>).lazy.forEach{ [unowned self] num in
                let model = section.removeAtIndex(num)
                self.tableView.xlj_keyHeightCache.removeHeightFor(model.identifier)
                indexPaths.append(NSIndexPath(forRow: num, inSection: random))
            }
            self.dataSource[random] = section
            self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }
    }
    
    
    func insertSection() {
        self.dataSource.insert([randomModel()], atIndex: 0)
        self.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    func deleteSection() {
        if !self.dataSource.isEmpty {
            self.dataSource.removeFirst()
            self.tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
    }
}


extension ViewController
{
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(___identifier, forIndexPath: indexPath) as! CustomCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
}

extension ViewController
{
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        switch semegmented.selectedSegmentIndex {
        case 0:
            return tableView.xlj_heightForCell(identifier: ___identifier, configuration: {[unowned self] (cell) in
                self.configureCell(cell, atIndexPath: indexPath)
            })
            
        case 1:
            return tableView.xlj_heightForCell(identifier: ___identifier, indexPath: indexPath, configuration: { (cell) in
                self.configureCell(cell, atIndexPath: indexPath)
            })
            
        case 2:
            let model = self.dataSource[indexPath.section][indexPath.row]
            return tableView.xlj_heightForCell(identifier: ___identifier, key: model.identifier, configuration: { (cell) in
                self.configureCell(cell, atIndexPath: indexPath)
            })
        default:
            return 0
        }
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            var models = dataSource[indexPath.section]
            models.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
}



