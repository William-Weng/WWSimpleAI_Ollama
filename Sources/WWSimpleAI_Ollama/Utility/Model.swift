//
//  Model.swift
//  WWSimpleAI_Ollama
//
//  Created by William.Weng on 2025/3/13.
//

import UIKit

// MARK: - api/chat
public extension WWSimpleAI.Ollama {
    
    /// Chat的訊息格式 (roleType不參與Decodable => CodingKeys)
    struct MessageInformation: Codable {
        
        let content: String
        let role: String
        let images: [String]?
        
        var roleType: Role = .user
        
        public init(roleType: Role, content: String, images: [UIImage]?, compressionQuality: CGFloat) {
            
            self.role = roleType.name()
            self.content = content
            self.images = images?._base64String(mimeType: .jpeg(compressionQuality: compressionQuality))
            self.roleType = roleType
        }
        
        enum CodingKeys: String, CodingKey {
            case role
            case content
            case images
        }
    }
}

// MARK: - api/embed
public extension WWSimpleAI.Ollama {
    
    /// 文字 => 數字向量的相關訊息
    struct EmbeddingInformation: Codable {
        
        let model: String
        let embeddings: [[Double]]
        let total_duration: Int
        let load_duration: Int
        let prompt_eval_count: Int
    }
}

// MARK: - api/tags
public extension WWSimpleAI.Ollama {
    
    /// 模型細節訊息格式 => {models:[]}
    struct ModelInformation: Codable {
        
        public let name: String
        public let model: String
        public let modified_at: String
        public let size: Int
        public let digest: String
        public let details: ModelDetailInformation
                
        /// ISO8601 => Date?
        /// - Returns: Date?
        public func modifiedDate() -> Date? { modified_at._dateISO8601() }
    }
    
    /// 模型細節訊息格式 => {models:[{details:{}}]}
    struct ModelDetailInformation: Codable {
        
        public let parent_model: String
        public let format: String
        public let family: String
        public let families: [String]
        public let parameter_size: String
        public let quantization_level: String
    }
}

// MARK: - api/ps
public extension WWSimpleAI.Ollama {
    
    /// 模型細節訊息格式 => {models:[]}
    struct RunningModelInformation: Codable {
        
        public let name: String
        public let model: String
        public let expires_at: String
        public let size: Int
        public let size_vram: Int
        public let digest: String
        public let details: ModelDetailInformation
    }
}

// MARK: - api/show
public extension WWSimpleAI.Ollama {
    
    /// 模型文件說明 => {}
    struct ModelDocumentInformation: Codable {
        
        public let license: String
        public let modelfile: String
        public let parameters: String
        public let template: String
        public let modified_at: String
        
        public let details: ModelDocumentDetailInformation
        public let model_info: ModelDocumentInfoInformation
        
        /// ISO8601 => Date?
        /// - Returns: Date?
        public func modifiedDate() -> Date? { modified_at._dateISO8601() }
    }
    
    /// 模型文件說明 => {"details""{}}
    struct ModelDocumentDetailInformation: Codable {
        
        public let parent_model: String
        public let format: String
        public let family: String
        public let families: [String]
        public let parameter_size: String
        public let quantization_level: String
    }
    
    /// 模型文件說明 => {"model_info""{}}
    struct ModelDocumentInfoInformation: Codable {
        
        public let general_architecture: String
        public let general_basename: String
        public let general_file_type: Int
        public let general_finetune: String
        public let general_languages: [String]
        public let general_parameter_count: Int
        public let general_quantization_version: Int
        public let general_size_label: String
        public let general_tags: [String]
        public let general_type: String
        
        public let llama_attention_head_count: Int
        public let llama_attention_head_count_kv: Int
        public let llama_attention_key_length: Int
        public let llama_attention_layer_norm_rms_epsilon: Double
        public let llama_attention_value_length: Int
        public let llama_block_count: Int
        public let llama_context_length: Int
        public let llama_embedding_length: Int
        public let llama_feed_forward_length: Int
        public let llama_rope_dimension_count: Int
        public let llama_rope_freq_base: Int
        public let llama_vocab_size: Int
        
        public let tokenizer_ggml_bos_token_id: Int
        public let tokenizer_ggml_eos_token_id: Int
        public let tokenizer_ggml_merges: [String]?
        public let tokenizer_ggml_model: String
        public let tokenizer_ggml_pre: String
        public let tokenizer_ggml_token_type: [Int]?
        public let tokenizer_ggml_tokens: [String]?
        
        enum CodingKeys: String, CodingKey {
            
            case general_architecture = "general.architecture"
            case general_basename = "general.basename"
            case general_file_type = "general.file_type"
            case general_finetune = "general.finetune"
            case general_languages = "general.languages"
            case general_parameter_count = "general.parameter_count"
            case general_quantization_version = "general.quantization_version"
            case general_size_label = "general.size_label"
            case general_tags = "general.tags"
            case general_type = "general.type"
            
            case llama_attention_head_count = "llama.attention.head_count"
            case llama_attention_head_count_kv = "llama.attention.head_count_kv"
            case llama_attention_key_length = "llama.attention.key_length"
            case llama_attention_layer_norm_rms_epsilon = "llama.attention.layer_norm_rms_epsilon"
            case llama_attention_value_length = "llama.attention.value_length"
            case llama_block_count = "llama.block_count"
            case llama_context_length = "llama.context_length"
            case llama_embedding_length = "llama.embedding_length"
            case llama_feed_forward_length = "llama.feed_forward_length"
            case llama_rope_dimension_count = "llama.rope.dimension_count"
            case llama_rope_freq_base = "llama.rope.freq_base"
            case llama_vocab_size = "llama.vocab_size"
            
            case tokenizer_ggml_bos_token_id = "tokenizer.ggml.bos_token_id"
            case tokenizer_ggml_eos_token_id = "tokenizer.ggml.eos_token_id"
            case tokenizer_ggml_merges = "tokenizer.ggml.merges"
            case tokenizer_ggml_model = "tokenizer.ggml.model"
            case tokenizer_ggml_pre = "tokenizer.ggml.pre"
            case tokenizer_ggml_token_type = "tokenizer.ggml.token_type"
            case tokenizer_ggml_tokens = "tokenizer.ggml.tokens"
        }
    }
}
