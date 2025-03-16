//
//  Extension.swift
//  Example
//
//  Created by William.Weng on 2025/3/13.
//

import UIKit

// MARK: - UITextView (function)
extension UITextView {
    
    /// 自動向下移動
    func _autoScrollToBottom() {
        
        let count = text.count
        guard count > 0 else { return }
        
        let bottom = NSMakeRange(count - 1, 1)
        scrollRangeToVisible(bottom)
    }
}
