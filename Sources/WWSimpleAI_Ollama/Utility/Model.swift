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
    class MessageInformation: Codable {
        
        var content: String
        var role: String
        var images: [String]?
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
    class EmbeddingInformation: Codable {
        
        var model: String
        var embeddings: [[Double]]
        var total_duration: Int
        var load_duration: Int
        var prompt_eval_count: Int
    }
}

// MARK: - api/tags
public extension WWSimpleAI.Ollama {
    
    /// 模型細節訊息格式 => {models:[]}
    class ModelInformation: Codable {
        
        public var name: String
        public var model: String
        public var modified_at: String
        public var size: Int
        public var digest: String
        public var details: ModelDetailInformation
                
        /// ISO8601 => Date?
        /// - Returns: Date?
        public func modifiedDate() -> Date? { modified_at._dateISO8601() }
    }
    
    /// 模型細節訊息格式 => {models:[{details:{}}]}
    class ModelDetailInformation: Codable {
        
        public var parent_model: String
        public var format: String
        public var family: String
        public var families: [String]
        public var parameter_size: String
        public var quantization_level: String
    }
}

// MARK: - api/ps
public extension WWSimpleAI.Ollama {
    
    /// 模型細節訊息格式 => {models:[]}
    class RunningModelInformation: Codable {
        
        public var name: String
        public var model: String
        public var expires_at: String
        public var size: Int
        public var size_vram: Int
        public var digest: String
        public var details: ModelDetailInformation
    }
}

// MARK: - api/show
public extension WWSimpleAI.Ollama {
    
    /// 模型文件說明 => {}
    class ModelDocumentInformation: Codable {
        
        public var license: String
        public var modelfile: String
        public var parameters: String
        public var template: String
        public var modified_at: String
        
        public var details: ModelDocumentDetailInformation
        public var model_info: ModelDocumentInfoInformation
        
        /// ISO8601 => Date?
        /// - Returns: Date?
        public func modifiedDate() -> Date? { modified_at._dateISO8601() }
    }
    
    /// 模型文件說明 => {"details""{}}
    class ModelDocumentDetailInformation: Codable {
        
        public var parent_model: String
        public var format: String
        public var family: String
        public var families: [String]
        public var parameter_size: String
        public var quantization_level: String
    }
    
    /// 模型文件說明 => {"model_info""{}}
    class ModelDocumentInfoInformation: Codable {
        
        public var general_architecture: String
        public var general_basename: String
        public var general_file_type: Int
        public var general_finetune: String
        public var general_languages: [String]
        public var general_parameter_count: Int
        public var general_quantization_version: Int
        public var general_size_label: String
        public var general_tags: [String]
        public var general_type: String
        
        public var llama_attention_head_count: Int
        public var llama_attention_head_count_kv: Int
        public var llama_attention_key_length: Int
        public var llama_attention_layer_norm_rms_epsilon: Double
        public var llama_attention_value_length: Int
        public var llama_block_count: Int
        public var llama_context_length: Int
        public var llama_embedding_length: Int
        public var llama_feed_forward_length: Int
        public var llama_rope_dimension_count: Int
        public var llama_rope_freq_base: Int
        public var llama_vocab_size: Int
        
        public var tokenizer_ggml_bos_token_id: Int
        public var tokenizer_ggml_eos_token_id: Int
        public var tokenizer_ggml_merges: [String]?
        public var tokenizer_ggml_model: String
        public var tokenizer_ggml_pre: String
        public var tokenizer_ggml_token_type: [Int]?
        public var tokenizer_ggml_tokens: [String]?
        
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
