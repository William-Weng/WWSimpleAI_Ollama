//
//  Extension.swift
//  WWSimpleAI_Ollama
//
//  Created by William.Weng on 2025/3/13.
//

import UIKit
import UniformTypeIdentifiers

// MARK: - Collection (function)
public extension Collection where Self.Element: UIImage {
    
    /// [UIImage] => [Base64]
    /// - Parameter mimeType: Constant.MimeType
    /// - Returns: [String?]
    func _base64String(mimeType: WWSimpleAI.MimeType) -> [String] {
        return compactMap({ $0._base64String(mimeType: mimeType) })
    }
}

// MARK: - Encodable (function)
public extension Encodable {
    
    /// Class => JSON Data
    /// - Returns: Data?
    func _jsonData() -> Data? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        return jsonData
    }
    
    /// Class => JSON String
    /// - Parameter encoding: String.Encoding
    /// - Returns: String?
    func _jsonString(using encoding: String.Encoding = .utf8) -> String? {
        guard let jsonData = self._jsonData() else { return nil }
        return jsonData._string(using: encoding)
    }
    
    /// Class => JSON Object
    /// - Returns: Any?
    func _jsonObject() -> Any? {
        guard let jsonData = self._jsonData() else { return nil }
        return jsonData._jsonObject()
    }
}

// MARK: - Bool (function)
public extension Bool {
    
    /// 將布林值轉成Int (true => 1 / false => 0)
    /// - Returns: Int
    func _int() -> Int { return Int(truncating: NSNumber(value: self)) }
}

// MARK: - String (function)
public extension String {
    
    /// String => Data
    /// - Parameters:
    ///   - encoding: 字元編碼
    ///   - isLossyConversion: 失真轉換
    /// - Returns: Data?
    func _data(using encoding: String.Encoding = .utf8, isLossyConversion: Bool = false) -> Data? {
        let data = self.data(using: encoding, allowLossyConversion: isLossyConversion)
        return data
    }
}

// MARK: - Data (function)
public extension Data {
    
    /// Data => 字串
    /// - Parameter encoding: 字元編碼
    /// - Returns: String?
    func _string(using encoding: String.Encoding = .utf8) -> String? {
        return String(data: self, encoding: encoding)
    }

    /// [Data => JSON](https://blog.zhgchg.li/現實使用-codable-上遇到的-decode-問題場景總匯-下-cb00b1977537)
    /// - 7b2268747470223a2022626f6479227d => {"http": "body"}
    /// - Returns: Any?
    func _jsonObject(options: JSONSerialization.ReadingOptions = .allowFragments) -> Any? {
        let json = try? JSONSerialization.jsonObject(with: self, options: options)
        return json
    }
    
    /// [將Data => NDJSON格式 (newline-delimited JSON)](https://blog.csdn.net/ken_coding/article/details/135313052)
    /// - Parameter encoding: [文字編碼](https://cloud.tencent.com/developer/article/1506199)
    /// - Returns: [[Any]?](https://ithelp.ithome.com.tw/articles/10332309)
    func _ndjson(using encoding: String.Encoding = .utf8) -> [Any]? {
        
        guard let jsonString = _string(using: encoding) else { return nil }
        
        var jsonArray: [Any] = []
        
        jsonString.split(separator: "\n").forEach({ string in
            guard let json = "\(string)"._data()?._jsonObject() else { return }
            jsonArray.append(json)
        })
        
        return jsonArray
    }
}

// MARK: - UIImage (function)
public extension UIImage {
    
    /// UIImage => Data
    /// - Parameter mimeType: jpeg / png / heic
    /// - Returns: Data?
    func _data(mimeType: WWSimpleAI.MimeType = .png) -> Data? {
        
        switch mimeType {
        case .jpeg(let compressionQuality): return jpegData(compressionQuality: compressionQuality)
        case .png: return pngData()
        case .heic: if #available(iOS 17.0, *) { return heicData() }; return nil
        default: return nil
        }
    }
    
    /// Image => Data => Base64字串
    /// - Parameter mimeType: jpeg / png
    /// - Returns: String?
    func _base64String(mimeType: WWSimpleAI.MimeType = .png) -> String? {
        let data = _data(mimeType: mimeType)
        return data?.base64EncodedString()
    }
}

// MARK: - UTTypeReference (static function)
public extension UTTypeReference {
    
    /// [副檔名 (pdf) => 統一類型標識符 (com.adobe.pdf)](https://www.jianshu.com/p/d6fe1e7af9b6)
    /// - Parameter filenameExtension: 副檔名
    /// - Returns: UTTypeReference?
    static func _find(with filenameExtension: String) -> UTTypeReference? { return UTTypeReference(filenameExtension: filenameExtension) }
}
