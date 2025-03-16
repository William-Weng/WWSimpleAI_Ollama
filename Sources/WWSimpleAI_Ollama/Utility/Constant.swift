//
//  Constant.swift
//  WWSimpleAI_Ollama
//
//  Created by William.Weng on 2025/2/11.
//

import UIKit
import UniformTypeIdentifiers

// MARK: - enum
public extension WWSimpleAI {
    
    /// [網頁檔案類型的MimeType](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types)
    enum MimeType {
        
        var mimeType: String { return mimeTypeMaker() }
        var fileExtension: String { return fileExtensionMaker() }
        var UTI: UTTypeReference? { return typeReference() }
        
        case jpeg(compressionQuality: CGFloat)
        case png
        case icon
        case bin
        case gif
        case txt
        case csv
        case doc
        case docx
        case xls
        case xlsx
        case pdf
        case webp
        case bmp
        case heic
        case avif
        case svg
        case html
        case xml
        case json
        
        /// [利用Mirror讀取enum case name](https://gist.github.com/qmchenry/a3b317a8cc47bd06aeabc0ddf95ba113)
        /// - jpeg / png / bin
        /// - Returns: String
        private func extensionName() -> String {
            if let label = Mirror(reflecting: self).children.first?.label { return label }
            return String(describing: self)
        }
        
        /// [副檔名 (pdf) => 統一類型標識符 (UTI - com.adobe.pdf)](https://www.jianshu.com/p/d6fe1e7af9b6)
        private func typeReference() -> UTTypeReference? {
            return UTTypeReference._find(with: self.extensionName())
        }
        
        /// [產生副檔名 (.jpg / .png / .gif)](https://www.ibm.com/docs/en/wkc/cloud?topic=catalog-previews)
        /// - Returns: String
        private func fileExtensionMaker() -> String { return ".\(extensionName())" }
        
        /// [產生MimeType (image/jpeg)](https://www.runoob.com/http/http-content-type.html)
        private func mimeTypeMaker() -> String {
            
            switch self {
            case .bin: return "application/octet-stream"
            case .pdf: return "application/pdf"
            case .doc: return "application/msword"
            case .docx: return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            case .xls: return "application/vnd.ms-excel"
            case .xlsx: return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            case .txt: return "text/plain"
            case .csv: return "text/csv"
            case .jpeg: return "image/jpeg"
            case .png: return "image/png"
            case .icon: return "image/x-icon"
            case .gif: return "image/gif"
            case .webp: return "image/webp"
            case .bmp: return "image/bmp"
            case .heic: return "image/heic"
            case .avif: return "image/avif"
            case .svg: return "image/svg+xml"
            case .html: return "text/html"
            case .xml: return "text/xml"
            case .json: return "application/json"
            }
        }
    }
    
    /// 圖片的Data開頭辨識字元
    enum ImageFormat: CaseIterable {
        
        var header: [UInt8] { return headerMaker() }
        
        case icon
        case png
        case jpeg
        case gif
        case webp
        case bmp
        case heic
        case avif
        case svg
        case pdf
        
        /// [圖片的文件標頭檔 (要看各圖檔的文件)](https://github.com/MROS/jpeg_tutorial)
        /// - Returns: [UInt8]
        private func headerMaker() -> [UInt8] {
            
            switch self {
            case .icon: return [0x00, 0x00, 0x01, 0x00]
            case .png: return [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            case .jpeg: return [0xFF, 0xD8, 0xFF]
            case .gif: return [0x47, 0x49, 0x46]
            case .webp: return [0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50]
            case .bmp:  return [0x42, 0x4D]
            case .heic: return [0x00, 0x00, 0x00, 0x00, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63]
            case .avif: return [0x00, 0x00, 0x00, 0x00, 0x66, 0x74, 0x79, 0x70, 0x61, 0x76, 0x69, 0x66]
            case .pdf: return [0x25, 0x50, 0x44, 0x46]
            case .svg: return []
            }
        }
    }
}

// MARK: - enum
public extension WWSimpleAI.Ollama {
    
    /// [API功能](https://api-docs.deepseek.com/)
    enum API {
        
        case generate
        case chat
        
        /// 取得url
        /// - Returns: String
        public func url() -> String {
            
            let path: String
            
            switch self {
            case .generate: path = "api/generate"
            case .chat: path = "api/chat"
            }
            
            return "\(WWSimpleAI.Ollama.baseURL)/\(path)"
        }
    }
    
    /// 角色類型
    enum Role: Codable {
        
        case user
        case assistant
        case custom(_ name: String)
        
        /// 角色名稱
        /// - Returns: String
        func name() -> String {
            switch self {
            case .user: return "user"
            case .assistant: return "assistant"
            case .custom(let name): return name
            }
        }
    }
    
    /// 結果回傳的格式
    enum ResponseType {
        case string(_ string: String? = nil)
        case data(_ data: Data? = nil)
        case ndjson(_ json: [Any]? = nil)
    }
    
    /// 要求AI要回傳的格式敘述
    enum ResponseFormat {
        
        case string(_ string: String)
        case json(_ json: String)
        
        /// 數值
        /// - Returns: String
        func value() -> String {
            switch self {
            case .string(let string): return "\"\(string)\""
            case .json(let json): return json
            }
        }
    }
    
    /// 要求AI的選項敘述
    enum ResponseOptions {
        
        case json(_ json: String)
        
        /// 數值
        /// - Returns: String
        func value() -> String {
            switch self {
            case .json(let json): return json
            }
        }
    }
    
    /// 要求AI的函式功能
    enum ResponseTools {
        
        case json(_ json: String)
        
        /// 數值
        /// - Returns: String
        func value() -> String {
            switch self {
            case .json(let json): return json
            }
        }
    }
    
    /// 自定義錯誤
    enum CustomError: Error {
        
        case jsonString     // JSON格式編碼錯誤
        case system         // Ollama上的錯誤訊息
        
        /// 錯誤訊息
        /// - Returns: String
        public func message() -> String {
            
            switch self {
            case .jsonString: return "JSON format encoding error."
            case .system: return "System error."
            }
        }
    }
}
