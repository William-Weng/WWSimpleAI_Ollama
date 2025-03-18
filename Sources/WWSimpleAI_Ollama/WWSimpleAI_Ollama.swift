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
        
        private(set) public static var baseURL = "http://localhost:11434"
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

// MARK: - 公開函式 (應用相關)
public extension WWSimpleAI.Ollama {
    
    /// 載入模型到記憶體的設定 - 開/關
    /// - Parameters:
    ///   - api: API類型
    ///   - isLoad: 載入 / 刪除
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - encoding: 文字編碼
    ///   - separator: 分隔號
    /// - Returns: Result<ResponseType, Error>
    func loadIntoMemory(api: API, isLoad: Bool = true, type: ResponseType = .string() , using encoding: String.Encoding = .utf8, separator: String = "") async -> Result<ResponseType, Error> {
        
        switch api {
        case .generate: return await loadGenerateModelIntoMemory(isLoad, type: type, using: encoding, separator: separator)
        case .chat: return await loadChatModelIntoMemory(isLoad, type: type, using: encoding, separator: separator)
        case .create: return .failure(CustomError.notSupport)
        case .model, .models, .version, .delete, .ps, .copy, .download: return .failure(CustomError.notSupport)
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
    ///   - separator: 分隔號
    /// - Returns: Result<String?, Error>
    func generate(prompt: String, type: ResponseType = .string(), timeout: TimeInterval = 60, format: ResponseFormat? = nil, options: ResponseOptions? = nil, images: [UIImage]? = nil, useStream: Bool = false, using encoding: String.Encoding = .utf8, separator: String = "") async -> Result<ResponseType, Error> {
        
        let api = API.generate
        let format = format?.value() ?? nullValue
        let options = options?.value() ?? nullValue
        let images = images?._base64String(mimeType: .jpeg(compressionQuality: Self.jpegCompressionQuality))._jsonString() ?? nullValue
        
        let json = """
        {
          "model": "\(Self.model)",
          "prompt": "\(prompt)",
          "stream": \(useStream),
          "format": \(format),
          "options": \(options),
          "images": \(images)
        }
        """
        
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info): return parseResponseInformation(info, api: api, forType: type, field: "response", using: encoding, separator: separator)
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
    ///   - separator: 分隔號
    /// - Returns: Result<ResponseType, Error>
    func talk(content: String, type: ResponseType = .string(), timeout: TimeInterval = 60, format: ResponseFormat? = nil, options: ResponseOptions? = nil, images: [UIImage]? = nil, tools: ResponseTools? = nil, useStream: Bool = false, using encoding: String.Encoding = .utf8, separator: String = "") async -> Result<ResponseType, Error> {
        let message = MessageInformation(roleType: .user, content: content)
        return await chat(messages: [message], timeout: timeout, format: format, options: options, images: images, tools: tools, useStream: useStream, using: encoding, separator: separator)
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
    ///   - separator: 分隔號
    /// - Returns: Result<ResponseType, Error>
    func chat(messages: [MessageInformation], type: ResponseType = .string(), timeout: TimeInterval = 60, format: ResponseFormat? = nil, options: ResponseOptions? = nil, images: [UIImage]? = nil, tools: ResponseTools? = nil, useStream: Bool = false, using encoding: String.Encoding = .utf8, separator: String = "") async -> Result<ResponseType, Error> {
        
        guard let _jsonString = messages._jsonString(using: encoding) else { return .failure(CustomError.notJSONString) }
        
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
        case .success(let info): return parseResponseInformation(info, api: api, forType: type, field: "content", using: encoding, separator: separator)
        }
    }
}

// MARK: - 公開函式 (模型相關)
public extension WWSimpleAI.Ollama {
    
    /// [建立客製化模型](https://medium.com/@simon3458/ollama-llm-model-as-a-service-introduction-d849fb6d9ced)
    /// - Parameters:
    ///   - newModel: 新模型名稱
    ///   - oldModel: 要引用的舊模型名稱
    ///   - personality: 人物設定
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - useStream: 是否使用串流回應
    ///   - encoding: 文字編碼
    ///   - separator: 分隔號
    /// - Returns: Result<ResponseType, Error>
    func create(newModel: String, from oldModel: String, personality: String, type: ResponseType = .string(), useStream: Bool = false, using encoding: String.Encoding = .utf8, separator: String = ",") async -> Result<ResponseType, Error> {
        
        let api = API.create
        
        let json = """
        {
          "model": "\(newModel)",
          "from": "\(oldModel)",
          "system": "\(personality)",
          "stream": \(useStream)
        }
        """
        
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info):
            
            let httpResult = parseHttpStatusCode(info)

            switch httpResult {
            case .failure(let error): return .failure(error)
            case .success(let data):
                switch type {
                case .data: return .success(.data(data))
                case .ndjson: return .success(.ndjson(data._ndjson(using: encoding)))
                case .string: return combineResponseString(api: api, data: data, field: "status", using: encoding, separator: separator)
                }
            }
        }
    }
    
    /// 刪除已下載模型
    /// - Parameters:
    ///   - model: 模型名稱
    /// - Returns: Result<Bool, Error>
    func delete(model: String) async -> Result<Bool, Error> {
        
        let api = API.delete
        
        let json = """
        {
          "model": "\(model)"
        }
        """
        
        let result = await WWNetworking.shared.request(httpMethod: .DELETE, urlString: api.url(), httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info):
            
            let httpResult = parseHttpStatusCode(info)
            
            switch httpResult {
            case .failure(let error): return .failure(error)
            case .success(_): return .success(true)
            }
        }
    }
    
    /// [複製模型](https://yanwei-liu.medium.com/model-context-protocol-mcp-a7d424e0f1d0)
    /// - Parameters:
    ///   - source: 來源模型名稱
    ///   - destination: 目的模型名稱
    /// - Returns: Result<Bool, Error>
    func copy(source model: String, destination name: String) async -> Result<Bool, Error> {
        
        let api = API.copy
        
        let json = """
        {
          "source": "\(model)",
          "destination": "\(name)"
        }
        """
        
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info):
            
            let httpResult = parseHttpStatusCode(info)
            
            switch httpResult {
            case .failure(let error): return .failure(error)
            case .success(_): return .success(true)
            }
        }
    }
    
    /// [下載模型](https://github.com/exo-explore/exo)
    /// - Parameters:
    ///   - model: 模型名稱
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - timeout: 設定請求超時時間
    ///   - useStream: 是否使用串流回應
    ///   - encoding: 文字編碼
    ///   - separator: 分隔號
    /// - Returns: Result<ResponseType, Error>
    func download(model: String, type: ResponseType = .string(), timeout: TimeInterval = 600, useStream: Bool = false, using encoding: String.Encoding = .utf8, separator: String = ",") async -> Result<ResponseType, Error> {
        
        let api = API.download
        
        let json = """
        {
          "model": "\(model)",
          "stream": \(useStream)
        }
        """
        
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), timeout: timeout, httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info):
            
            let httpResult = parseHttpStatusCode(info)
            
            switch httpResult {
            case .failure(let error): return .failure(error)
            case .success(let data):
                switch type {
                case .data: return .success(.data(data))
                case .ndjson: return .success(.ndjson(data._ndjson(using: encoding)))
                case .string: return combineResponseString(api: api, data: data, field: "status", using: encoding, separator: separator)
                }
            }
        }
    }
}

// MARK: - 公開函式 (文件相關)
public extension WWSimpleAI.Ollama {
    
    /// 取得版本號
    /// - Parameters:
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - encoding: 文字編碼
    ///   - separator: 分隔號
    /// - Returns: Result<ResponseType, Error>
    func version(type: ResponseType = .string(), using encoding: String.Encoding = .utf8, separator: String = "") async -> Result<ResponseType, Error> {
        
        let api = API.version
        let result = await WWNetworking.shared.request(httpMethod: .GET, urlString: api.url())
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info): return parseResponseInformation(info, api: api, forType: type, field: "version", using: encoding, separator: separator)
        }
    }
    
    /// 取得已下載模型列表
    /// - Returns: Result<[ModelInformation]?, Error>
    func models() async -> Result<[ModelInformation], Error> {
        
        let api = API.models
        let result = await WWNetworking.shared.request(httpMethod: .GET, urlString: api.url())
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info):
            
            let httpResult = parseHttpStatusCode(info)
            
            switch httpResult {
            case .failure(let error): return .failure(error)
            case .success(let data):
                
                guard let dictionary = data._jsonObject() as? [String: Any],
                      let models = dictionary["models"] as? [Any]
                else {
                    return .failure(CustomError.notJSONString)
                }
                
                guard let modelArray = models._jsonClass(for: [ModelInformation].self),
                      !modelArray.isEmpty
                else {
                    return .failure(CustomError.isEmpty)
                }
                
                return .success(modelArray)
            }
        }
    }
    
    /// 取得模型文件說明
    /// - Parameters:
    ///   - model: 模型名稱
    ///   - isVerbose: 是否要詳細的資料
    /// - Returns: Result<ModelDocumentInformation, Error>
    func document(model: String, isVerbose: Bool = false) async -> Result<ModelDocumentInformation, Error> {
        
        let api = API.model
        
        let json = """
        {
          "model": "\(model)",
          "verbose": \(isVerbose)
        }
        """
        
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), httpBodyType: .string(json))
                
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info):
            
            let httpResult = parseHttpStatusCode(info)
            
            switch httpResult {
            case .failure(let error): return .failure(error)
            case .success(let data):
                
                guard let dictionary = data._jsonObject() as? [String: Any],
                      let info = dictionary._jsonClass(for: ModelDocumentInformation.self)
                else {
                    return .failure(CustomError.notJSONString)
                }
                
                return .success(info)
            }
        }
        
        return .failure(CustomError.isEmpty)
    }
    
    /// 取得正在執行的模型列表
    /// - Returns: Result<RunningModelInformation, Error>
    func processStatus() async -> Result<[RunningModelInformation], Error> {
        
        let api = API.ps
        let result = await WWNetworking.shared.request(httpMethod: .GET, urlString: api.url())
                
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info):
            
            let httpResult = parseHttpStatusCode(info)
            
            switch httpResult {
            case .failure(let error): return .failure(error)
            case .success(let data):
                
                guard let dictionary = data._jsonObject() as? [String: Any],
                      let models = dictionary["models"] as? [Any]
                else {
                    return .failure(CustomError.notJSONString)
                }
                
                guard let modelArray = models._jsonClass(for: [RunningModelInformation].self),
                      !modelArray.isEmpty
                else {
                    return .failure(CustomError.isEmpty)
                }
                
                return .success(modelArray)
            }
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
    ///   - separator: 分隔號
    /// - Returns: Result<ResponseType, Error>
    func loadGenerateModelIntoMemory(_ isLoad: Bool, type: ResponseType, using encoding: String.Encoding, separator: String) async -> Result<ResponseType, Error> {
        
        let api = API.generate
        
        var json = """
        {
          "model": "\(Self.model)",
          "keep_alive": \(isLoad._int())
        }
        """
        
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info): return parseResponseInformation(info, api: api, forType: type, field: "done_reason", using: encoding, separator: separator)
        }
    }
    
    /// 載入對話模型到記憶體的設定 - 開/關
    /// - Parameters:
    ///   - isLoad: 載入 / 刪除
    ///   - type: 回應樣式 => String / Data / JSON
    ///   - encoding: 文字編碼
    ///   - separator: 分隔號
    /// - Returns: Result<ResponseType, Error>
    func loadChatModelIntoMemory(_ isLoad: Bool = true, type: ResponseType = .string(), using encoding: String.Encoding, separator: String) async -> Result<ResponseType, Error> {
        
        let api = API.chat
        
        var json = """
        {
          "model": "\(Self.model)",
          "messages": [],
          "keep_alive": \(isLoad._int())
        }
        """
                
        let result = await WWNetworking.shared.request(httpMethod: .POST, urlString: api.url(), httpBodyType: .string(json))
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let info): return parseResponseInformation(info, api: .generate, forType: type, field: "done_reason", using: encoding, separator: separator)
        }
    }
    
    /// 解析回應格式 => String / Data / JSON
    /// - Parameters:
    ///   - info: 回應資訊
    ///   - api: API類型
    ///   - type: 回應類型
    ///   - field: 要取得的欄位名稱
    ///   - encoding: 文字編碼
    ///   - separator: 分隔號
    /// - Returns: Result<ResponseType, Error>
    func parseResponseInformation(_ info: WWNetworking.ResponseInformation, api: API, forType type: ResponseType, field: String, using encoding: String.Encoding, separator: String) -> Result<ResponseType, Error> {
        
        let httpResult = parseHttpStatusCode(info)
        
        switch httpResult {
        case .failure(let error): return .failure(error)
        case .success(let data):
            switch type {
            case .string: return combineResponseString(api: api, data: data, field: field, using: encoding, separator: separator)
            case .data: return .success(.data(data))
            case .ndjson: return .success(.ndjson(data._ndjson(using: encoding)))
            }
        }
    }
    
    /// [結合回應字串](https://zh.pngtree.com/freebackground/ai-artificial-intelligent-blue_961916.html)
    /// - Parameters:
    ///   - api: API
    ///   - data: Data?
    ///   - field: 欄位名稱 (response / content)
    ///   - encoding: String.Encoding
    ///   - separator: 分隔號
    /// - Returns: Result<ResponseType, Error>
    func combineResponseString(api: API, data: Data?, field: String, using encoding: String.Encoding, separator: String) -> Result<ResponseType, Error> {
        
        guard let jsonArray = data?._ndjson(using: encoding) else { return .failure(CustomError.notJSONString) }
        
        if let errorMessage = errorMessage(from: jsonArray.first) { return .failure(CustomError.systemError(errorMessage)) }
        
        var stringArray: [String] = []
        
        switch api {
        case .version:
            
            jsonArray.forEach { json in
                
                guard let dict = json as? [String: Any],
                      let version = dict[field] as? String
                else {
                    return
                }
                
                stringArray.append(version)
            }
                    
        case .generate:
            
            jsonArray.forEach { json in
                
                guard let dict = json as? [String: Any],
                      let response = dict[field] as? String
                else {
                    return
                }
                
                stringArray.append(response)
            }
            
        case .chat:
                        
            jsonArray.forEach { json in
                
                guard let dict = json as? [String: Any],
                      let message = dict["message"] as? [String: Any],
                      let content = message[field] as? String
                else {
                    return
                }
                
                stringArray.append(content)
            }
                        
        case .create, .download:
                        
            jsonArray.forEach { json in
                
                guard let dict = json as? [String: Any],
                      let status = dict[field] as? String
                else {
                    return
                }
                
                stringArray.append(status)
            }
            
        case .model, .models, .delete, .ps, .copy: return .failure(CustomError.notSupport)
        }
        
        return .success(.string(stringArray.joined(separator: separator)))
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
    
    /// 處理HTTP狀態碼的相關功能 (200 / 404 / 500)
    /// - Parameters:
    ///   - info: WWNetworking.ResponseInformation
    ///   - successCodes: 成功的HttpCode
    /// - Returns: Result<Data, Error>
    func parseHttpStatusCode(_ info: WWNetworking.ResponseInformation, successCodes: Set<Int> = [200]) -> Result<Data, Error> {
        
        guard let response = info.response,
              let data = info.data
        else {
            return .failure(CustomError.isEmpty)
        }
        
        if (!successCodes.contains(response.statusCode)) { return .failure(CustomError.httpError(response.statusCode, data)) }
        return .success(data)
    }
}
