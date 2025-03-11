//
//  OpenAIService.swift
//  ChatGPT-Test
//
//  Created by Simeon Shaffar on 2/28/25.
//

import Foundation
import Alamofire
import Combine

class OpenAIService {
    let baseURL = "https://api.openai.com/v1/"
    let model = "gpt-4o-mini"
    let temp: Float? = 1
    
//    init() {
//        let modelsURL = "https://api.openai.com/v1/models"
//        
//        let headers: HTTPHeaders = [
//            "Authorization" : "Bearer \(Constants.openAIAPIKey)"
//        ]
//        
//        AF.request(modelsURL, headers: headers).responseString { data in
//            print(data.result)
//            print("")
//        }
//    }
    
    func sendMessage(content: String) -> AnyPublisher<OpenAICompletionResponse, Error> {
        let messages = [SimpleMessage(content: content)]
        
        let body = OpenAICompletionBodySimple(model: self.model,
                                              messages: messages,
                                              temperature: self.temp)
        
//        if let encodedBody = try? JSONEncoder().encode(body),
//            let stringEncodedBody = String(data: encodedBody, encoding: .utf8)  {
//            print("OpenAIService encoded body: \(stringEncodedBody)")
//        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIAPIKey)"
        ]
        
        return Future{ [weak self] promise in
            guard let self = self else { return }
            AF.request(baseURL + "chat/completions", method: .post, parameters: body,
                       encoder: .json, headers: headers).responseDecodable(of: OpenAICompletionResponse.self) { response in
                print("Response: \(response.result)")
                
                switch response.result {
                case .success(let response):
                    promise(.success(response))
                case .failure(let error):
                    promise(.failure(error))
                }
                
            } //AF request
        } //return Future
        .eraseToAnyPublisher()
    } //sendMessage
    
    func sendImage(text: String, imageData: Data) -> AnyPublisher<OpenAICompletionResponse, Error> {
        let base64Image = imageData.base64EncodedString()
        
        let messages = [
            FullMessage(content: [
                FullMessage.ContentItem(type: "text",
                                        text: text,
                                        image_url: nil),
                FullMessage.ContentItem(type: "image_url",
                                        text: nil,
                                        image_url: FullMessage.ContentItem.ImageURL(url: "data:image/jpeg;base64,\(base64Image)"))
            ])
        ]
        
        let body = OpenAICompletionBodyFull(model: self.model,
                                            messages: messages,
                                            temperature: self.temp)
        
//        if let encodedBody = try? JSONEncoder().encode(body),
//            let stringEncodedBody = String(data: encodedBody, encoding: .utf8)  {
//            print("OpenAIService encoded body: \(stringEncodedBody)")
//        }
       
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIAPIKey)"
        ]
        
        return Future{ [weak self] promise in
            guard let self = self else { return }
            AF.request(baseURL + "chat/completions", method: .post, parameters: body,
                       encoder: .json, headers: headers).responseDecodable(of: OpenAICompletionResponse.self) { response in
                print("Response: \(response.result)")
                
                switch response.result {
                case .success(let response):
                    promise(.success(response))
                case .failure(let error):
                    promise(.failure(error))
                }
                
            } //AF request
        } //return Future
        .eraseToAnyPublisher()
    } //sendMessage
    
}

struct SimpleMessage: Encodable {
    let role: String = "user"
    let content: String
}

struct FullMessage: Encodable {
    let role: String = "user"
    let content: [ContentItem]
    
    struct ContentItem: Encodable {
        let type: String
        let text: String?
        let image_url: ImageURL?
        
        struct ImageURL: Encodable {
            let url: String
        }
    }
}

struct OpenAICompletionBodySimple: Encodable {
    let model: String
    let messages: [SimpleMessage]
    let temperature: Float?
}

struct OpenAICompletionBodyFull: Encodable {
    let model: String
    let messages: [FullMessage]
    let temperature: Float?
}

struct OpenAICompletionResponse: Decodable {
    let id: String
    let object: String
    let model: String
    
    let choices: [OpenAICompletionChoice]
    
    struct OpenAICompletionChoice: Decodable {
        let message: OpenAICompletionMessage
        
        struct OpenAICompletionMessage: Decodable {
            let role: String
            let content: String
        }
    }
}
