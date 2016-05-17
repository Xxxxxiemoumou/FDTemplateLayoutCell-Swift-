//
//  UITableView+IndexPathHeightCache.swift
//  AutoCellHeight
//
//  Created by 谢某某 on 16/5/9.
//  Copyright © 2016年 WeiBo. All rights reserved.
//

import UIKit

/// app支持的方向数
public let xlj_orientationCount = NSBundle.mainBundle().infoDictionary!["UISupportedInterfaceOrientations"]?.count ?? 1

// MARK: - XLJIndexPathHeightCache
public class XLJIndexPathHeightCache
{
    /// 是否自动管理所有indexPath缓存
    public var automaticallyInvalidateEnabled = true
    
// MARK: - -------------- private property --------------
    
    private typealias HetghtsArr = [[CGFloat]]

    private lazy var cacheArrForPortrait = HetghtsArr()
    private lazy var cacheArrForLandscape = HetghtsArr()
    
// MARK: - -------------- public function --------------
    public func isExistsHeightAt(indexPath path: NSIndexPath) -> Bool {
        
        initializeIndexPaths([path])
        return currentCacheArr{
            return $0[path.section][path.row] != -1
        }
    }
    
    public func setHeight(height: CGFloat, forIndexPath path: NSIndexPath) {
        
        initializeIndexPaths([path])
        return currentCacheArr{
            $0[path.section][path.row] = height
        }
    }
    
    public func heightForIndexPath(path: NSIndexPath) -> CGFloat {
        
        initializeIndexPaths([path])
        return currentCacheArr{
            return $0[path.section][path.row]
        }
    }
    
    /// 无效化指定的indexPath的缓存(横竖屏)
    public func invalidateHeightFor(path: NSIndexPath) {
        
        initializeIndexPaths([path])
        enumerateAllOrientations { $0[path.section][path.row] = -1 }
    }
    
    /// 移除所有的缓存
    public func removeAllCache() {
        enumerateAllOrientations{ $0.removeAll() }
    }
}

// MARK: - -------------- private function --------------
extension XLJIndexPathHeightCache
{
    private func currentCacheArr<T>(closure: (inout arr: HetghtsArr) -> T) -> T{
        /// app只支持一个方向
        if xlj_orientationCount == 1 { return closure(arr: &cacheArrForPortrait) }
        
        if UIDevice.currentDevice().orientation.isPortrait {
            return closure(arr: &cacheArrForPortrait)
        }else{
            return closure(arr: &cacheArrForLandscape)
        }
    }
    
    /// 遍历cacheArrForPortrait 和 cacheArrForLandscape
    private func enumerateAllOrientations(closure: (inout cacheArr: HetghtsArr) -> Void) {
        /// app只支持一个方向
        if xlj_orientationCount == 1 {
            closure(cacheArr: &cacheArrForPortrait)
        }else {
            closure(cacheArr: &cacheArrForPortrait)
            closure(cacheArr: &cacheArrForLandscape)
        }
    }
    
    /// 初始化indexPaths
    private func initializeIndexPaths(arr: [NSIndexPath]) {
        
        for indexPath in arr {
            initializeSections(indexPath.section)
            initializeRows(indexPath.row, inSection: indexPath.section)
        }
    }
    
    /// 初始化缓存数组中的不大于section的所有section值,如果不存在的话
    private func initializeSections(section: Int) {
        
        enumerateAllOrientations { (cacheArr) in
            for sec in 0...section where sec >= cacheArr.count {
                cacheArr.insert([CGFloat](), atIndex: sec)
            }
        }
    }
    
    /// 初始化缓存数组section中的不大于row的所有row值,如果不存在的话
    private func initializeRows(row: Int, inSection section: Int) {
        
        enumerateAllOrientations { (cacheArr) in
            var heightsByRow = cacheArr[section]
            for r in 0...row where r >= heightsByRow.count {
                heightsByRow.insert(-1, atIndex: r)
            }
            cacheArr[section] = heightsByRow
        }
    }
}


private var xlj_indexPathHeightCache_key = "xlj_indexPathHeightCache_key___"

// MARK: - extension UITableView(IndexPathHeightCache)
extension UITableView
{
    /// 注意: 如果在第一次加载tableView时,
    ///      需要设置automaticallyInvalidateEnabled属性,
    ///      请在添加到父视图前设置
    public var xlj_indexPathHeightCache: XLJIndexPathHeightCache {
        get {
            var cache: XLJIndexPathHeightCache! = objc_getAssociatedObject(self, &xlj_indexPathHeightCache_key) as? XLJIndexPathHeightCache
            
            if cache == nil {
                cache = XLJIndexPathHeightCache()
                objc_setAssociatedObject(self, &xlj_indexPathHeightCache_key, cache, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return cache
        }
        set {
            objc_setAssociatedObject(self, &xlj_indexPathHeightCache_key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - extension UITableView(ExchangeImplementations)
extension UITableView
{
    public override class func initialize() {
        
        struct Static {
            static var token: dispatch_once_t = 0
        }
        // 过滤子类
        guard self === UITableView.self else { return }
  
        dispatch_once(&Static.token) {
            
#if swift(>=2.2)
            let selectorArr = [
                #selector(UITableView.reloadData),
                #selector(UITableView.insertSections(_:withRowAnimation:)),
                #selector(UITableView.deleteSections(_:withRowAnimation:)),
                #selector(UITableView.reloadSections(_:withRowAnimation:)),
                #selector(UITableView.moveSection(_:toSection:)),
                #selector(UITableView.insertRowsAtIndexPaths(_:withRowAnimation:)),
                #selector(UITableView.deleteRowsAtIndexPaths(_:withRowAnimation:)),
                #selector(UITableView.reloadRowsAtIndexPaths(_:withRowAnimation:)),
                #selector(UITableView.moveRowAtIndexPath(_:toIndexPath:))
            ]
#else
          let selectorArr = [
                Selector("reloadData"),
                Selector("insertSections:withRowAnimation:"),
                Selector("deleteSections:withRowAnimation:"),
                Selector("reloadSections:withRowAnimation:"),
                Selector("moveSection:toSection:"),
                Selector("insertRowsAtIndexPaths:withRowAnimation:"),
                Selector("deleteRowsAtIndexPaths:withRowAnimation:"),
                Selector("reloadRowsAtIndexPaths:withRowAnimation:"),
                Selector("moveRowAtIndexPath:toIndexPath:")
    
            ]
#endif
            
            for selector in selectorArr
            {
                let originalSelector = selector
                let swizzledSelector = NSSelectorFromString("xlj_\(selector)")
                
                let originalMethod = class_getInstanceMethod(self, originalSelector)
                let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
                
                let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
                
                if didAddMethod {
                    class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
                } else {
                    method_exchangeImplementations(originalMethod, swizzledMethod);
                }
            }
        }
    }
    
    private struct TempEnabled {
        static var key = "tempEnabled_key____"
    }
    
    private var tempEnabled: Bool {
        get {
            var enabled: Bool! = objc_getAssociatedObject(self, &TempEnabled.key) as? Bool
            if enabled == nil {
                enabled = self.xlj_indexPathHeightCache.automaticallyInvalidateEnabled
                objc_setAssociatedObject(self, &TempEnabled.key, enabled, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return enabled
        }set {
            objc_setAssociatedObject(self, &TempEnabled.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public override func didMoveToSuperview() {
     
        let cache = self.xlj_indexPathHeightCache
        
        /// 记录先前的automaticallyInvalidateEnabled值
        tempEnabled = cache.automaticallyInvalidateEnabled
        
        /// 由于第一次加载数据时会调用 reloadData 方法
        /// 会把算好的高度缓存移除,导致需要重新计算
        /// 所以需要设置先为false
        if cache.automaticallyInvalidateEnabled == true {
            cache.automaticallyInvalidateEnabled = false
        }
    }
    
    @objc private func xlj_reloadData() {
        
        let cache = self.xlj_indexPathHeightCache
        if cache.automaticallyInvalidateEnabled { cache.removeAllCache() }
        cache.automaticallyInvalidateEnabled = tempEnabled
        
        self.xlj_reloadData()
    }
    
    @objc private func xlj_insertSections(sections: NSIndexSet, withRowAnimation: UITableViewRowAnimation)
    {
        let cache = self.xlj_indexPathHeightCache
        if cache.automaticallyInvalidateEnabled {
            sections.enumerateIndexesUsingBlock { (sec, stop) in
                cache.initializeSections(sec)
                cache.enumerateAllOrientations{ $0.insert([CGFloat](), atIndex: sec) }
            }
        }
        self.xlj_insertSections(sections, withRowAnimation: withRowAnimation)
    }
    
    @objc private func xlj_deleteSections(sections: NSIndexSet, withRowAnimation: UITableViewRowAnimation)
    {
        let cache = self.xlj_indexPathHeightCache
        if cache.automaticallyInvalidateEnabled {
            sections.enumerateIndexesUsingBlock { (sec, _) in
                cache.initializeSections(sec)
                cache.enumerateAllOrientations{ $0.removeAtIndex(sec) }
            }
        }
        self.xlj_deleteSections(sections, withRowAnimation: withRowAnimation)
    }
    
    @objc private func xlj_reloadSections(sections: NSIndexSet, withRowAnimation: UITableViewRowAnimation)
    {
        let cache = self.xlj_indexPathHeightCache
        if cache.automaticallyInvalidateEnabled {
            sections.enumerateIndexesUsingBlock { (sec, _) in
                cache.initializeSections(sec)
                cache.enumerateAllOrientations{ $0[sec].removeAll() }
            }
        }
        
        self.xlj_reloadSections(sections, withRowAnimation: withRowAnimation)
    }
    
    @objc private func xlj_moveSection(section: Int, toSection: Int)
    {
        let cache = self.xlj_indexPathHeightCache
        if cache.automaticallyInvalidateEnabled {
            
            cache.initializeSections(toSection)
            cache.initializeSections(section)
            
            cache.enumerateAllOrientations{ swap(&$0[section], &$0[toSection]) }
        }
        self.xlj_moveSection(section, toSection: toSection)
    }
    
    @objc private func xlj_insertRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation: UITableViewRowAnimation)
    {
        let cache = self.xlj_indexPathHeightCache
        if cache.automaticallyInvalidateEnabled {
            cache.initializeIndexPaths(indexPaths)
            
            indexPaths.lazy.sort{ (path1, path2) in
                if path1.section != path2.section {
                    return path1.row > path2.row
                }else {
                    return path1.section > path1.section
                }
            }.lazy.forEach { path in
                cache.enumerateAllOrientations{ (cacheArr) in
                    cacheArr[path.section].insert(-1, atIndex: path.row)
                }
            }
        }
        self.xlj_insertRowsAtIndexPaths(indexPaths, withRowAnimation: withRowAnimation)
    }
    
    @objc private func xlj_deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation: UITableViewRowAnimation)
    {
        let cache = self.xlj_indexPathHeightCache
        if cache.automaticallyInvalidateEnabled {
            cache.initializeIndexPaths(indexPaths)
            
            indexPaths.lazy.sort{ (path1, path2) in
                if path1.section != path2.section {
                    return path1.row > path2.row
                }else {
                    return path1.section > path1.section
                }
            }.lazy.forEach { path in
                cache.enumerateAllOrientations{ (cacheArr) in
                        cacheArr[path.section].removeAtIndex(path.row)
                }
            }
        }
        self.xlj_deleteRowsAtIndexPaths(indexPaths, withRowAnimation: withRowAnimation)
    }
    
    @objc private func xlj_reloadRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation: UITableViewRowAnimation)
    {
        let cache = self.xlj_indexPathHeightCache
        if cache.automaticallyInvalidateEnabled {
            cache.initializeIndexPaths(indexPaths)
            
            for path in indexPaths {
                cache.enumerateAllOrientations{ $0[path.section][path.row] = -1 }
            }
        }
        self.xlj_reloadRowsAtIndexPaths(indexPaths, withRowAnimation: withRowAnimation)
    }
    
    @objc private func xlj_moveRowAtIndexPath(indexPath: NSIndexPath, toIndexPath: NSIndexPath)
    {
        let cache = self.xlj_indexPathHeightCache
        if cache.automaticallyInvalidateEnabled {
            cache.initializeIndexPaths([indexPath, toIndexPath])
            
            cache.enumerateAllOrientations{ (cacheArr) in
                var oldValue = cacheArr[indexPath.section][indexPath.row]
                var newValue = cacheArr[toIndexPath.section][toIndexPath.row]
                swap(&oldValue, &newValue)
            }
        }
        self.xlj_moveRowAtIndexPath(indexPath, toIndexPath: toIndexPath)
    }
}




















