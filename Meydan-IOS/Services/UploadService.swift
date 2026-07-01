//
//  UploadService.swift
//  Meydan-IOS
//
//  Created by bora ateş on 7.05.2026.
//

import Foundation
import Alamofire


@MainActor
protocol UploadServiceProtocol {
    func uploadImage( imageData: Data, fileName: FileType, mimeType: String,
        fieldName: String, endpointPath: String ) async throws -> String
}


@MainActor
class UploadService: UploadServiceProtocol {
    
    static let shared = UploadService()
    private let baseURL = AppConfig.apiBaseURL

    private func buildHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = ["Content-Type": "application/json"]
        if let token = TokenStorage.shared.token, !token.isEmpty {
            headers.add(name: "Authorization", value: "Bearer \(token)")
        }
        return headers
    }
    
    func uploadImage( imageData: Data, fileName: FileType, mimeType: String = "image/jpeg", fieldName: String = "file", endpointPath: String = "/brand/upload" ) async throws -> String {
        
        let url = "\(baseURL)\(endpointPath)"
        
        let response: ImageUploadResponse = try await withCheckedThrowingContinuation { continuation in
            AF.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(
                        imageData,
                        withName: fieldName,
                        fileName: fileName.rawValue,
                        mimeType: mimeType
                    )
                },
                to: url,
                method: .post,
                headers: buildHeaders()
            )
            .validate()
            .responseDecodable(of: ImageUploadResponse.self) { response in
                print("DEBUG: [POST] \(url)")
                if let data = response.data, let body = String(data: data, encoding: .utf8) {
                    print("DEBUG: Response Code: \(response.response?.statusCode ?? 0)")
                    print("DEBUG: Response Body: \(body)")
                }

                switch response.result {
                case .success(let decoded):
                    continuation.resume(returning: decoded)
                case .failure(let afError):
                    print("ERROR: Upload failed with error: \(afError.localizedDescription)")
                    if let data = response.data {
                        if let arrayError = try? JSONDecoder().decode(ErrorArrayResponse.self, from: data),
                           let first = arrayError.errors.first, !first.isEmpty {
                            continuation.resume(throwing: NetworkError.serverError(message: first))
                            return
                        }

                        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                            let message = errorResponse.message ?? errorResponse.error ?? afError.localizedDescription
                            continuation.resume(throwing: NetworkError.serverError(message: message))
                        } else {
                            let raw = String(data: data, encoding: .utf8) ?? afError.localizedDescription
                            continuation.resume(throwing: NetworkError.serverError(message: raw))
                        }
                    } else {
                        continuation.resume(throwing: NetworkError.serverError(message: afError.localizedDescription))
                    }
                }
            }
        }

        guard let uploadedURL = response.uploadedURL, !uploadedURL.isEmpty else {
            throw NetworkError.serverError(message: response.message ?? "Yuklenen gorselin URL bilgisi donmedi.")
        }

        return uploadedURL
    }

    
}
