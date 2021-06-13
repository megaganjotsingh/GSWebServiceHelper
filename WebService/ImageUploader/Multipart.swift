//
//  Multipart.swift
//  Task Manager
//
//  Created by Gagan Mac on 25/09/20.
//  Copyright © 2020 IT Manufactory. All rights reserved.
//

import Foundation

import UIKit
import MobileCoreServices


public enum MultiPartResult<Value, ResponseError: GeneralResponseModel> {
    case success(Value)
    case failure(ResponseError)
    case error(Error?)
}

public class MultiPart: NSObject {
    
    public static let fieldName = "fieldName"
    public static let pathURLs = "pathURL"
    public static let fileName = ""
    public static var data: Data!
    
    var session: URLSession?
    public func callPostWebService(_ urlString: String, parameters: [String: Any]?, filePathArr arrFilePath: [[String: Any]]?, completion: @escaping ([String: Any]?, Error?) -> Void) {
        
        let boundary = generateBoundaryString()
        
        // configure the request
        var request = NSMutableURLRequest()
        if let url = URL(string: urlString) {
            request = NSMutableURLRequest(url: url)
        }
        
        request.httpMethod = "POST"
        
        // set content type
        let contentType = "multipart/form-data; boundary=\(boundary)"
        //        request.setValue("asdkjfklaj;fl;afnsvjafds", forHTTPHeaderField: "Authorization")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // create body
        let httpBody: Data? = createBody(withBoundary: boundary, parameters: parameters, paths: arrFilePath)
        session = URLSession.shared
        
        let task = session?.uploadTask(with: request as URLRequest, from: httpBody, completionHandler: {(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void in
            if error != nil {
                print("error = \(String(describing: error ?? 0 as? Error))")
                DispatchQueue.main.async(execute: {() -> Void in
                    completion( nil, error)
                })
                return
            }
            let user = try? JSONSerialization.jsonObject(with: safelyUnwrapedData(data), options: .allowFragments) as? [String: Any]
            DispatchQueue.main.async(execute: {() -> Void in
                if let user = user {
                    completion(user, nil)
                } else {
                     completion( nil, error)
                }
            })
            // NSLog(@"result = %@", result);
            })
        task?.resume()
    }
    
    public func callPostWSWithModel<T: Decodable>(_ urlString: String, parameters: [String: Any]?, filePathArr arrFilePath: [[String: Any]]?, model: T.Type, completion: @escaping (MultiPartResult<T, GeneralResponseModel>) -> Void) {
        
        let boundary = generateBoundaryString()
        
        // configure the request
        var request = NSMutableURLRequest()
        if let url = URL(string: urlString) {
            request = NSMutableURLRequest(url: url)
        }
        request.httpMethod = "POST"
        
        // set content type
        let contentType = "multipart/form-data; boundary=\(boundary)"
        //        request.setValue("asdkjfklaj;fl;afnsvjafds", forHTTPHeaderField: "Authorization")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // create body
        let httpBody: Data? = createBody(withBoundary: boundary, parameters: parameters, paths: arrFilePath)
        session = URLSession.shared
        
        let task = session?.uploadTask(with: request as URLRequest, from: httpBody, completionHandler: {(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void in
            if error != nil {
                print("error = \(String(describing: error ?? 0 as? Error))")
                mainThread {
                    completion(.error(error))
                }
                return
            }
            if let data = data {
                let decoder = JSONDecoder()
                do {
                    if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                        print(convertedJsonIntoDict)
                    }
                    
                    let dictResponse = try decoder.decode(GeneralResponseModel.self, from: data )
                    
                    let strStatus = dictResponse.status ?? 0
                    if strStatus == 200 {
                        let dictResponsee = try decoder.decode(model, from: data )
                        mainThread {
                            completion(.success(dictResponsee))
                        }
                    } else {
                        mainThread {
                            completion(.failure(dictResponse))
                            debugPrint(dictResponse.message ?? 0)
                        }
                    }
                } catch let error as NSError {
                    debugPrint(error.localizedDescription)
                    mainThread {
                        completion(.error(error))
                    }
                }
            }
        })
        task?.resume()
    }
    
    public func uploadImageWithModel<T: Decodable>(_ urlString: String, filePathArr arrFilePath: [[String: Any]]?, model: T.Type, completion: @escaping (MultiPartResult<T?, GeneralResponseModel>) -> Void) {
        
        let boundary = generateBoundaryString()
        
        // configure the request
        var request = NSMutableURLRequest()
        if let url = URL(string: urlString) {
            request = NSMutableURLRequest(url: url)
        }
        request.httpMethod = "POST"
        
        request.setValue(DefaultsManager.bearerToken, forHTTPHeaderField: "Authorization")
        
        // set content type
        let contentType = "multipart/form-data; boundary=\(boundary)"

        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // create body
        let httpBody: Data? = createBodyForImageUpload(withBoundary: boundary, paths: arrFilePath)
        session = URLSession.shared
        
        let task = session?.uploadTask(with: request as URLRequest, from: httpBody, completionHandler: {(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void in
            if error != nil {
                print("error = \(String(describing: error ?? 0 as? Error))")
                mainThread {
                    completion(.error(error))
                }
                return
            }
            if let data = data {
//                let decoder = JSONDecoder()
                do {
                    if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                        print(convertedJsonIntoDict)
                    }
                    mainThread {
                        completion(.success(nil))
                    }
//                    let dictResponse = try decoder.decode(GeneralResponseModel.self, from: data )
                    
//                    let strStatus = dictResponse.status ?? 0
//                    if (200..<300) ~= strStatus {
//                        let dictResponsee = try decoder.decode(model, from: data )
//                        mainThread {
//                            completion(.success(dictResponsee))
//                        }
//                    } else {
//                        mainThread {
//                            completion(.failure(dictResponse))
//                            debugPrint(dictResponse.message ?? 0)
//                        }
//                    }
                } catch let error as NSError {
                    debugPrint(error.localizedDescription)
                    mainThread {
                        completion(.error(error))
                    }
                }
            }
        })
        task?.resume()
    }
    
    fileprivate func createBodyForImageUpload(withBoundary boundary: String, paths: [[String: Any]]?) -> Data {
        var httpBody = Data()
        
        if let paths = paths {
            for pathDic in paths {
                guard let pDictUrls = pathDic[MultiPart.pathURLs] as? [Data] else { return Data() }
                for path: Data in pDictUrls {
                    httpBody.append(safelyUnwrapedData("--\(boundary)\r\n".data(using: String.Encoding.utf8)))
                    httpBody.append(safelyUnwrapedData("Content-Disposition: form-data; name=\"\(pathDic[MultiPart.fieldName] ?? "")\"; filename=\"\( pathDic[MultiPart.fileName] ?? "")\"\r\n".data(using: String.Encoding.utf8)))
                    httpBody.append(safelyUnwrapedData("Content-Type: image/png\r\n\r\n".data(using: String.Encoding.utf8)))
                    httpBody.append(path)
                    httpBody.append(safelyUnwrapedData("\r\n".data(using: String.Encoding.utf8)))
                }
            }
        }
        httpBody.append(safelyUnwrapedData("--\(boundary)--\r\n".data(using: String.Encoding.utf8)))
        return httpBody

    }
    
    
    fileprivate func createBody(withBoundary boundary: String, parameters: [String: Any]?, paths: [[String: Any]]?) -> Data {
        var httpBody = Data()
        
        // add params (all params are strings)
        if let parameters = parameters {
            for (parameterKey, parameterValue) in parameters {
                if let arr = parameterValue as? [AnyObject] {
                    for ii in 0 ..< arr.count {
                        httpBody.append(safelyUnwrapedData("--\(boundary)\r\n".data(using: String.Encoding.utf8)))
                        httpBody.append(safelyUnwrapedData("Content-Disposition: form-data; name=\"\(parameterKey)[]\"\r\n\r\n".data(using: String.Encoding.utf8)))
                        httpBody.append(safelyUnwrapedData("\(arr[ii])\r\n".data(using: String.Encoding.utf8)))
                    }
                } else {
                    httpBody.append(safelyUnwrapedData("--\(boundary)\r\n".data(using: String.Encoding.utf8)))
                    httpBody.append(safelyUnwrapedData("Content-Disposition: form-data; name=\"\(parameterKey)\"\r\n\r\n".data(using: String.Encoding.utf8)))
                    httpBody.append(safelyUnwrapedData("\(parameterValue)\r\n".data(using: String.Encoding.utf8)))
                }
            }
        }
        
        // add File data
        if let paths = paths {
            for pathDic in paths {
                guard let pDictUrls = pathDic[MultiPart.pathURLs] as? [String] else { return Data() }
                for path: String in pDictUrls {
                    let filename: String = URL(fileURLWithPath: path).lastPathComponent
                    do {
                        let data = try Data(contentsOf: URL(fileURLWithPath: path))
                        
                        let mimetype: String = mimeType(forPath: path)
                        httpBody.append(safelyUnwrapedData("--\(boundary)\r\n".data(using: String.Encoding.utf8)))
                        httpBody.append(safelyUnwrapedData("Content-Disposition: form-data; name=\"\(pathDic[MultiPart.fieldName] ?? "")\"; filename=\"\(filename)\"\r\n".data(using: String.Encoding.utf8)))
                        httpBody.append(safelyUnwrapedData("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)))
                        httpBody.append(data)
                        httpBody.append(safelyUnwrapedData("\r\n".data(using: String.Encoding.utf8)))
                    } catch {
                        print("Unable to load data: \(error)")
                    }
                }
            }
        }
        httpBody.append(safelyUnwrapedData("--\(boundary)--\r\n".data(using: String.Encoding.utf8)))
        return httpBody
    }
    
    fileprivate func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    fileprivate func mimeType(forPath path: String) -> String {
        // get a mime type for an extension using MobileCoreServices.framework
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (pathExtension ?? "") as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    
}

private func mainThread(_ completion: @escaping () -> Void) {
    DispatchQueue.main.async {
        completion()
    }
}
public class GeneralResponseModel: Decodable {
    var message: String?
    var status: Int?
}


private func safelyUnwrapedData(_ data: Data?) -> Data {
    if let dd = data {
        return dd
    } else {
        return Data()
    }
    
}
