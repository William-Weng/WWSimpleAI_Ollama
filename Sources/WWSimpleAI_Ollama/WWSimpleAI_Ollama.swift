//
//  WWSimpleOllamaAI.swift
//  WWSimpleAI_Ollama
//
//  Created by William.Weng on 2025/3/13.
//

import UIKit
import WWNetworking

// MARK: - [簡單的Ollama功能使用](https://ollama.com/)
extension WWSimpleAI {
    
    open class Ollama {
        
        @MainActor
        public static let shared = Ollama()
        
        private(set) public static var baseURL = "http://localhost:11434/"
        private(set) public static var model: String = "gemma:2b"
        private(set) public static var jpegCompressionQuality = 0.75
        
        private let nullValue = "null"
        
        private init() {}
    }
}

// MARK: - 初始值設定 (static function)
public extension WWSimpleAI.Ollama {
    
    /// [相關參數設定](https://ollama.com/)
    /// - Parameters:
    ///   - baseURL: API的URL
    ///   - model: 模型名稱
    ///   - jpegCompressionQuality: 圖片壓縮率
    static func configure(baseURL: String, model: String, jpegCompressionQuality: Double = 0.75) {
        Self.baseURL = baseURL
        Self.model = model
        Self.jpegCompressionQuality = jpegCompressionQuality
    }
}

// MARK: - 公開函式
public extension WWSimpleAI.Ollama {
    
    /// 載入模型到記憶體的設定 - 開/關
    /// - Parameters:
    ///   - api: API類型
    ///   - isLoad: 載入 / 刪除
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - encoding: 文字編碼
    /// - Returns: Result<ResponseType, Error>
    func loadIntoMemory(api: API, isLoad: Bool = true, type: ResponseType = .string() , using encoding: String.Encoding = .utf8) async -> Result<ResponseType, Error> {
        
        switch api {
        case .generate: return await loadGenerateModelIntoMemory(isLoad, type: type, using: encoding)
        case .chat: return await loadChatModelIntoMemory(isLoad, type: type, using: encoding)
        }
    }
    
    /// [一次性回應 - 每次請求都是獨立的](https://github.com/ollama/ollama)
    /// - Parameters:
    ///   - prompt: 提問
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - format: 回應樣式格式化
    ///   - timeout: 設定請求超時時間
    ///   - options: 其它選項
    ///   - images: 要上傳的圖片
    ///   - useStream: 是否使用串流回應
    ///   - encoding: 文字編碼
    /// - Returns: Result<String?, Error>
    func generate(prompt: String, type: ResponseType = .string(), timeout: TimeInterval = 60, format: ResponseFormat? = nil, options: ResponseOptions? = nil, images: [UIImage]? = nil, useStream: Bool = false, using encoding: String.Encoding = .utf8) async -> Result<ResponseType, Error> {
        
        let api = API.generate
        let format = format?.value() ?? nullValue
        let options = options?.value() ?? nullValue
        let images = images?._base64String(mimeType: .jpeg(compressionQuality: Self.jpegCompressionQuality))._jsonString() ?? nullValue
        
        var json = """
        {
          "model": "\(Self.model)",
          "prompt": "\(prompt)",
          "stream": \(useStream),
          "format": \(format),
          "options": \(options),
          "images": \(images)
        }
        """
                
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), headers: nil, httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info): return .success(parseResponseInformation(info, api: api, forType: type, field: "response", using: encoding))
        }
    }
    
    /// [說話模式 - 會記住之前的對話內容](https://github.com/ollama/ollama/blob/main/docs/api.md)
    /// - Parameters:
    ///   - content: [提問文字](https://dribbble.com/shots/22339104-Crab-Loading-Gif)
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - timeout: 設定請求超時時間
    ///   - format: 回應樣式格式化
    ///   - options: 其它選項
    ///   - images: 要上傳的圖片
    ///   - tools: 要求AI的函式功能
    ///   - useStream: 是否使用串流回應
    ///   - encoding: 文字編碼
    /// - Returns: Result<ResponseType, Error>
    func talk(content: String, type: ResponseType = .string(), timeout: TimeInterval = 60, format: ResponseFormat? = nil, options: ResponseOptions? = nil, images: [UIImage]? = nil, tools: ResponseTools? = nil, useStream: Bool = false, using encoding: String.Encoding = .utf8) async -> Result<ResponseType, Error> {
        let message = MessageInformation(roleType: .user, content: content)
        return await chat(messages: [message], timeout: timeout, format: format, options: options, images: images, tools: tools, useStream: useStream, using: encoding)
    }
    
    /// [對話模式 - 會記住之前的對話內容](https://github.com/ollama/ollama/blob/main/docs/api.md)
    /// - Parameters:
    ///   - messages: [[對話內容]](https://dribbble.com/shots/22339104-Crab-Loading-Gif)
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - timeout: 設定請求超時時間
    ///   - format: 回應樣式格式化
    ///   - options: 其它選項
    ///   - images: 要上傳的圖片
    ///   - tools: 要求AI的函式功能
    ///   - useStream: 是否使用串流回應
    ///   - encoding: 文字編碼
    /// - Returns: Result<ResponseType, Error>
    func chat(messages: [MessageInformation], type: ResponseType = .string(), timeout: TimeInterval = 60, format: ResponseFormat? = nil, options: ResponseOptions? = nil, images: [UIImage]? = nil, tools: ResponseTools? = nil, useStream: Bool = false, using encoding: String.Encoding = .utf8) async -> Result<ResponseType, Error> {
        
        guard let _jsonString = messages._jsonString(using: encoding) else { return .failure(CustomError.jsonString) }
        
        let api = API.chat
        let format = format?.value() ?? nullValue
        let options = options?.value() ?? nullValue
        let tools = tools?.value() ?? nullValue
        let images = images?._base64String(mimeType: .jpeg(compressionQuality: Self.jpegCompressionQuality))._jsonString() ?? nullValue
        
        let json = """
        {
          "model": "\(Self.model)",
          "messages": \(_jsonString),
          "stream": \(useStream),
          "format": \(format),
          "options": \(options),
          "images": \(images),
          "tools": \(tools)
        }
        """
        
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), timeout: timeout, httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info): return .success(parseResponseInformation(info, api: api, forType: type, field: "content", using: encoding))
        }
    }
}

// MARK: - 小工具
private extension WWSimpleAI.Ollama {
    
    /// 載入一次性回應模型到記憶體的設定 - 開/關
    /// - Parameters:
    ///   - isLoad: 載入 / 刪除
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - encoding: 文字編碼
    /// - Returns: Result<ResponseType, Error>
    func loadGenerateModelIntoMemory(_ isLoad: Bool, type: ResponseType, using encoding: String.Encoding) async -> Result<ResponseType, Error> {
        
        let api = API.generate
        
        var json = """
        {
          "model": "\(Self.model)",
          "keep_alive": \(isLoad._int())
        }
        """
        
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), headers: nil, httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info): return .success(parseResponseInformation(info, api: api, forType: type, field: "done_reason", using: encoding))
        }
    }
    
    /// 載入對話模型到記憶體的設定 - 開/關
    /// - Parameters:
    ///   - isLoad: 載入 / 刪除
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - encoding: 文字編碼
    /// - Returns: Result<ResponseType, Error>
    func loadChatModelIntoMemory(_ isLoad: Bool = true, type: ResponseType = .string(), using encoding: String.Encoding = .utf8) async -> Result<ResponseType, Error> {
        
        let api = API.chat
        
        var json = """
        {
          "model": "\(Self.model)",
          "messages": [],
          "keep_alive": \(isLoad._int())
        }
        """
                
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), headers: nil, httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info): return .success(parseResponseInformation(info, api: .generate, forType: type, field: "done_reason", using: encoding))
        }
    }
    
    /// 解析回應格式 => String / Data / JSON
    /// - Parameters:
    ///   - info: 回應資訊
    ///   - api: API類型
    ///   - type: 回應類型
    ///   - field: 要取得的欄位名稱
    ///   - encoding: 文字編碼
    /// - Returns: ResponseType
    func parseResponseInformation(_ info: WWNetworking.ResponseInformation, api: API, forType type: ResponseType, field: String, using encoding: String.Encoding) -> ResponseType {
        
        let data = info.data
        
        switch type {
        case .string: return .string(combineResponseString(api: api, data: data, field: field, using: encoding))
        case .data(_): return .data(data)
        case .ndjson(_): return .ndjson(data?._ndjson(using: encoding))
        }
    }
    
    /// [結合回應字串](https://zh.pngtree.com/freebackground/ai-artificial-intelligent-blue_961916.html)
    /// - Parameters:
    ///   - api: API
    ///   - data: Data?
    ///   - field: 欄位名稱 (response / content)
    ///   - encoding: String.Encoding
    /// - Returns: String?
    func combineResponseString(api: API, data: Data?, field: String, using encoding: String.Encoding = .utf8) -> String? {
                
        guard let jsonArray = data?._ndjson(using: encoding) else { return nil }
        
        var string: String = ""
        
        if let errorMessage = errorMessage(from: jsonArray.first) { return errorMessage }
        
        switch api {
        case .generate:
            
            jsonArray.forEach { json in
                
                guard let dict = json as? [String: Any],
                      let response = dict[field] as? String
                else {
                    return
                }
                
                string += response
            }
            
        case .chat:
            
            jsonArray.forEach { json in
                
                guard let dict = json as? [String: Any],
                      let message = dict["message"] as? [String: Any],
                      let content = message[field] as? String
                else {
                    return
                }
                
                string += content
            }
        }
        
        return string
    }
    
    /// 取得錯誤訊息
    /// - Parameter json: Any?
    /// - Returns: String?
    func errorMessage(from json: Any?) -> String? {
        
        guard let dict = json as? [String: Any],
              let errorMessage = dict["error"] as? String
        else {
            return nil
        }
        
        return errorMessage
    }
}
