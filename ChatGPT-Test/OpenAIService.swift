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
    let temp: Float? = 0.25
    
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
        let messages = [Message(content: content)]
        
        let body = OpenAICompletionBody(model: self.model,
                                         messages: messages,
                                         temperature: self.temp)
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

struct Message: Encodable {
    let role: String = "user"
    let content: String
}

struct OpenAICompletionBody: Encodable {
    let model: String
    let messages: [Message]
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
