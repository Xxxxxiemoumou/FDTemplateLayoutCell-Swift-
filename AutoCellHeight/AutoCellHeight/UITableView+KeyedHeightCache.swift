//
//  UITableView+KeyedHeightCache.swift
//  AutoCellHeight
//
//  Created by 谢某某 on 16/5/9.
//  Copyright © 2016年 WeiBo. All rights reserved.
//

import UIKit

public class XLJKeyedHeightCache
{
    
// MARK: - -------------- private property --------------
    
    private typealias HetghtsArr = [String: CGFloat]
    
    private lazy var cacheArrForPortrait = HetghtsArr()
    private lazy var cacheArrForLandscape = HetghtsArr()
    
    
// MARK: - -------------- public function --------------
    
    public func isExistsHeightAt(key _key: String) -> Bool {
        return currentCacheArr{
            return ($0[_key] ?? -1) != -1
        }
    }
    
    public func setHeight(height: CGFloat, forKey key: String) {
        currentCacheArr{ $0[key] = height }
    }
    
    public func heightForKey(key: String) -> CGFloat {
        return currentCacheArr{ return $0[key] ?? -1 }
    }
    
    /// 移除指定的indexPath的缓存(横竖屏)
    public func removeHeightFor(key: String) {
        enumerateAllOrientations { $0.removeValueForKey(key) }
    }
    
    /// 移除所有的缓存
    public func removeAllCache() {
        enumerateAllOrientations { $0.removeAll() }
    }
}

extension XLJKeyedHeightCache
{
    /// 当前缓存数组
    private func currentCacheArr<T>(closure: (inout arr: HetghtsArr) -> T) -> T {
        /// 只支持一个方向
        if xlj_orientationCount == 1 { return closure(arr: &cacheArrForPortrait) }
        
        if UIDevice.currentDevice().orientation.isPortrait {
            return closure(arr: &cacheArrForPortrait)
        }else{
            return closure(arr: &cacheArrForLandscape)
        }
    }
    
    /// 遍历cacheArrForPortrait 和 cacheArrForLandscape
    private func enumerateAllOrientations(closure: (inout cacheArr: HetghtsArr) -> Void) {
        if xlj_orientationCount == 1 { /// 只支持一个方向
            closure(cacheArr: &cacheArrForPortrait)
        }else {
            closure(cacheArr: &cacheArrForPortrait)
            closure(cacheArr: &cacheArrForLandscape)
        }
    }
}


private var xlj_keyHeightCache_key = "xlj_keyHeightCache_key___"

// MARK: - extension UITableView(KeyedHeightCache)
extension UITableView
{
    public var xlj_keyHeightCache: XLJKeyedHeightCache {
        get {
            var cache: XLJKeyedHeightCache! = objc_getAssociatedObject(self, &xlj_keyHeightCache_key) as? XLJKeyedHeightCache
            
            if cache == nil {
                cache = XLJKeyedHeightCache()
                objc_setAssociatedObject(self, &xlj_keyHeightCache_key, cache, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return cache
        }
        set{
            objc_setAssociatedObject(self, &xlj_keyHeightCache_key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}






