//
//  UITableViewCell+AutoCellHeight.swift
//  AutoCellHeight
//
//  Created by 谢某某 on 16/5/9.
//  Copyright © 2016年 WeiBo. All rights reserved.
//

import UIKit

private var xlj_registerCellDic_key = "xlj_registerCellDic_key___"

extension UITableView
{
    public typealias ConfigurationClosure = (cell: UITableViewCell) -> Void
    
    /// 利用indexPath缓存
    public func xlj_heightForCell(identifier id: String, indexPath cache: NSIndexPath!, configuration: ConfigurationClosure) -> CGFloat
    {
        guard !id.isEmpty && cache != nil else{ return 0 }
        
        let heightCache = self.xlj_indexPathHeightCache
        
        if heightCache.isExistsHeightAt(indexPath: cache) {
            return heightCache.heightForIndexPath(cache)
        }
                
        let height = self.xlj_heightForCell(identifier: id, configuration: configuration)
        heightCache.setHeight(height, forIndexPath: cache)
        return height
    }
    
    /// 利用给定的字符串缓存
    public func xlj_heightForCell(identifier id: String, key cache: String, configuration: ConfigurationClosure) -> CGFloat
    {
        guard !id.isEmpty && !cache.isEmpty else{ return 0 }
        
        let keyCache = self.xlj_keyHeightCache
        
        if keyCache.isExistsHeightAt(key: cache) {
            return keyCache.heightForKey(cache)
        }
        
        let height = self.xlj_heightForCell(identifier: id, configuration: configuration)
        keyCache.setHeight(height, forKey: cache)
        return height
    }
    
    public func xlj_registerCellForReuseIdentifier(identifier id: String) -> UITableViewCell
    {
        if id.isEmpty { fatalError("identifier can't be empty") }
        
        var cellDic: NSMutableDictionary! = objc_getAssociatedObject(self, &xlj_registerCellDic_key) as? NSMutableDictionary
        
        if cellDic == nil {
            cellDic = NSMutableDictionary()
            objc_setAssociatedObject(self, &xlj_registerCellDic_key, cellDic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        var cell: UITableViewCell! = cellDic[id] as? UITableViewCell
        
        if cell == nil {
            cell = self.dequeueReusableCellWithIdentifier(id)
            if cell == nil { fatalError("Cell must be registered") }
            cell.xlj_isTemplateCell = true
            cell.contentView.translatesAutoresizingMaskIntoConstraints = false
            cellDic[id] = cell
        }
        return cell
    }
    
    public func xlj_heightForCell(identifier id: String, configuration: ConfigurationClosure) -> CGFloat
    {
        guard !id.isEmpty else { return 0 }
        
        let cell = self.xlj_registerCellForReuseIdentifier(identifier: id)
        /// 手动调用
        cell.prepareForReuse()
        
        /// 配置cell
        configuration(cell: cell)
        
        var contentViewWidth = CGRectGetWidth(self.frame)
        guard contentViewWidth > 0 else { return 0 }
        
        if cell.accessoryView != nil {
            contentViewWidth -= 16 + CGRectGetWidth(cell.accessoryView!.frame)
        }else{
            switch cell.accessoryType {
            case .None: contentViewWidth -= 0.0
            case .DisclosureIndicator: contentViewWidth -= 34.0
            case .DetailDisclosureButton: contentViewWidth -= 68.0
            case .Checkmark: contentViewWidth -= 40.0
            case .DetailButton: contentViewWidth -= 48.0
            }
        }
        
        var fittingSize = CGSizeZero
        
        if cell.xlj_isFrameLayout {
            
            #if swift(>=2.2)
            let selector = #selector(sizeThatFits)
            #else
            let selector = Selector("sizeThatFits:")
            #endif
            
            let inherited = !cell.isMemberOfClass(UITableViewCell)
            let overrided = cell.dynamicType.instanceMethodForSelector(selector) != UITableViewCell.self.instanceMethodForSelector(selector)
            
            if inherited && !overrided {
                fatalError("you must be override sizeThatFits: if use frameLayout")
            }
            fittingSize = cell.sizeThatFits(CGSizeMake(contentViewWidth, 0))
            
        }else {
            /// 添加约束
            let contraint = NSLayoutConstraint(item: cell.contentView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: contentViewWidth)
            cell.contentView.addConstraint(contraint)
            
            /// 根据约束计算出所需的最小高度
            fittingSize = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
            cell.contentView.removeConstraint(contraint)
        }
        
        /// 为separator line添加一个像素
        if self.separatorStyle != .None {
            fittingSize.height += 1.0 / UIScreen.mainScreen().scale;
        }
        return fittingSize.height
    }
}

private var xlj_registerHeaderFooterView_key = "xlj_registerHeaderFooterView_key___"

// MARK: - extension UITableView(LayoutHeaderFooterView)
extension UITableView
{
    public func xlj_registerHeaderFooterViewFor(identifier id: String) -> UITableViewHeaderFooterView
    {
        if id.isEmpty { fatalError("identifier can't be empty") }
        
        var viewDic: NSMutableDictionary! = objc_getAssociatedObject(self, &xlj_registerHeaderFooterView_key) as? NSMutableDictionary
        
        if viewDic == nil {
            viewDic = NSMutableDictionary()
            objc_setAssociatedObject(self, &xlj_registerHeaderFooterView_key, viewDic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        var view: UITableViewHeaderFooterView! = viewDic[id] as? UITableViewHeaderFooterView
        if view == nil {
            view = self.dequeueReusableHeaderFooterViewWithIdentifier(id)
            if view == nil { fatalError("HeaderFooterView must be registered") }
            view.contentView.translatesAutoresizingMaskIntoConstraints = false
            viewDic[id] = view
        }
        return view
    }
    
    //TODO: 没有加入缓存
    public func xlj_heightForHeaderFooterView(identifier id: String, configuration: (view: UITableViewHeaderFooterView) -> Void) -> CGFloat
    {
        let view = self.xlj_registerHeaderFooterViewFor(identifier: id)
        view.prepareForReuse()
        configuration(view: view)
        
        let contentViewWid = CGRectGetWidth(self.frame)
        
        let contraint = NSLayoutConstraint(item: view.contentView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: contentViewWid)
        view.contentView.addConstraint(contraint)
        
        var height = view.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        view.contentView.removeConstraint(contraint)
        
        if height == 0 { height = view.sizeThatFits(CGSizeMake(contentViewWid, 0)).height }
        
        return height
    }
}

private var xlj_isRegisterCell_key = "xlj_isRegisterCell_key___"
private var xlj_isFrameLayout_key = "xlj_isFrameLayout_key___"

extension UITableViewCell
{
    /// @code return tableView.xlj_heightForCell(identifier: "CustomCell", indexPath:            
    ///                 indexPath, configuration: {[unowned self] (cell) in
    ///
    ///                     let cusCell = cell as! CustomCell
    ///                     cusCell.model = self.dataSource[indexPath.row]
    ///
    ///                     if !cusCell.xlj_isTemplateCell {
    ///                         self.notifySomething
    ///                     }
    ///               })
    public var xlj_isTemplateCell: Bool {
        get {
            return (objc_getAssociatedObject(self, &xlj_isRegisterCell_key) as? Bool) ?? true
        }
        set {
            objc_setAssociatedObject(self, &xlj_isRegisterCell_key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 是否是frame布局(默认为false)
    public var xlj_isFrameLayout: Bool {
        get {
            return (objc_getAssociatedObject(self, &xlj_isFrameLayout_key) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &xlj_isFrameLayout_key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}

