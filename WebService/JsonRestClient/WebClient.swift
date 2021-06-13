//
//  Unwrappable.swift
//  Task Manager
//
//  Created by Gagan Mac on 21/09/20.
//  Copyright © 2020 IT Manufactory. All rights reserved.
//


import Foundation
import AppAuth

public typealias JSON = [String: Any]
public typealias HTTPHeaders = [String: String]
public typealias JSONDictionary = [String: Any]

public enum RequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

extension URL {
    init<A, E>(baseUrl: String, resource: Resource<A, E>) {
        var components = URLComponents(string: baseUrl)
        let resourceComponents = URLComponents(string: resource.path.absolutePath)
        // these local variable is for removing this error: Overlapping accesses to 'components', but modification requires exclusive access; consider copying to a local variable
        let localComponent = components
        let localResourceConponent = resourceComponents
        
        components?.path = Path(localComponent?.path ?? "").appending(path: Path(localResourceConponent?.path ?? "")).absolutePath
        components?.queryItems = localResourceConponent?.queryItems
        
        switch resource.method {
        case .get, .delete:
            var queryItems = components?.queryItems ?? []
            queryItems.append(contentsOf: resource.params.map {
                URLQueryItem(name: $0.key, value: String(describing: $0.value))
            })
            components?.queryItems = queryItems
        default:
            break
        }
        if let url = components?.url {
            self = url
        } else {
            self = URL(fileURLWithPath: "")
        }
    }
    
}

extension URLRequest {
    init<A, E>(baseUrl: String, resource: Resource<A, E>, querryParams: Bool = false) {
        let url = URL(baseUrl: baseUrl, resource: resource)
        self.init(url: url)
        
        httpMethod = resource.method.rawValue
        resource.headers.forEach {
            setValue($0.value, forHTTPHeaderField: $0.key)
        }
        if querryParams {
            return
        }
        switch resource.method {
        case .post, .put:
            httpBody = try? JSONSerialization.data(withJSONObject: resource.params, options: [])
        default:
            break
        }
    }
}

open class WebClient {
    private var baseUrl: String
   
    public var commonParams: JSON = [:]
    
    public init(baseUrl: String) {
        self.baseUrl = baseUrl
        // check token expiration
        guard let expTime = DefaultsManager.expireTime else { return }
        if expTime.minutes(from: Date()) <= 2 {
            loadState()
        }
        
    }
    
    public func load<A, CustomError>(resource: Resource<A, CustomError>, querryParamsIncluded: Bool = false, onView: UIView? = nil, showLoading: Bool, completion: @escaping (Response<A, CustomError>) -> Void) -> URLSessionDataTask? {
        let status = Reach().connectionStatus()
        switch status {
        case .unknown, .offline:
            completion(.failure(.noInternetConnection))
            return nil
        case .online(.wwan):
            print("Connected via WWAN")
        case .online(.wiFi):
            print("Connected via WiFi")
        }
        
        var newResouce = resource
        newResouce.params = newResouce.params.merging(commonParams) { spec, _ in
            return spec
        }
        
        // show loader on the onView (viewController's view)
        var spinnerView: UIView?
        if showLoading {
            if let view = onView {
                spinnerView = showSpinner(onView: view)
            }
        }
        
        let request = URLRequest(baseUrl: baseUrl, resource: resource, querryParams: querryParamsIncluded)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, _ in
            // Parsing incoming data
            self.removeSpinner(spinnerView)
            DispatchQueue.main.async {
                
                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(.other))
                    return
                }
                
//                do {
//                    if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? NSDictionary {
//                        print(request)
//                        print(resource.params)
//                        print(convertedJsonIntoDict)
//                    }
//                } catch {
//                    print("no json data")
//                }
                
                if (200..<300) ~= response.statusCode {
                    
                    completion(Response(value: data.flatMap(resource.parse), or: .other))
                   
                } else if response.statusCode == 401 {
                    completion(.failure(.unauthorized))
                } else {
                    completion(.failure(data.flatMap(resource.parseError).map({ .custom($0) }) ?? .other))
                }
            }
        }
        
        task.resume()
        
        return task
        
    }
    
    public func requestData(completionHandler: @escaping (Result<Data, Error>) -> Void) {
        
        guard let url = URL(string: baseUrl) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(.failure(error ?? WebError<Any>.other))
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(.success(data))
            }
        }.resume()
    }
    
    public func downloadData(downloadSession: URLSession, completionHandler: @escaping (Result<Data, Error>) -> Void) {
        
        var request = URLRequest(url: URL(string: baseUrl) ?? URL(fileURLWithPath: ""))
        request.httpMethod = "GET"
        request.setValue(DefaultsManager.bearerToken, forHTTPHeaderField: "Authorization")
        downloadSession.downloadTask(with: request) { tempLocalUrl, response, error in
            DispatchQueue.main.async {
                if let tempLocalUrl = tempLocalUrl, error == nil {
                    // Success
                  if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                
                    }
                    do {
                        let largeImageData = try Data(contentsOf: tempLocalUrl)
                        completionHandler(.success(largeImageData))
                    } catch {
                        print("error")
                    }
                } else {
                    guard let error = error else { return }
                    completionHandler(.failure((error)))
                    print("Failure: %@", error.localizedDescription)
                }
            }
        }.resume()
        
    }
    
    func downloadAttachment(downloadSession: URLSession) {
        var request = URLRequest(url: URL(string: baseUrl) ?? URL(fileURLWithPath: ""))
        request.httpMethod = "GET"
        request.setValue(DefaultsManager.bearerToken, forHTTPHeaderField: "Authorization")
        
        downloadSession.downloadTask(with: request).resume()
    }
    
    func loadState() {
        guard let data = UserDefaults(suiteName: "group.com.itm.da.mobile.TaskManager")?.object(forKey: "authState") as? Data else {
            return
        }
        
        if let authState = NSKeyedUnarchiver.unarchiveObject(with: data) as? OIDAuthState {
            
            refreshToken(with: authState)
        }
    }
    
    func refreshToken(with authState: OIDAuthState) {
        let currentAccessToken = authState.lastTokenResponse?.accessToken
        authState.performAction { accessToken, _, error in
            if error != nil {
                print("Error fetching fresh tokens: \(error?.localizedDescription ?? "ERROR")")
                return
            }

            guard let accessToken = accessToken else {
                print("Error getting accessToken")
                return
            }

            if currentAccessToken != accessToken {
                print("Access token was refreshed automatically from webclient (\(currentAccessToken ?? "CURRENT_ACCESS_TOKEN") to \(accessToken))")
                DefaultsManager.bearerToken = accessToken
                DefaultsManager.saveExpTime(with: accessToken)
            } else {
                print("Access token was fresh and not updated \(accessToken)")
            }
        }
        
    }
    
    func showSpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.clear
        let ai = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        ai.startAnimating()
        ai.center = spinnerView.center
        onView.layoutSubviews()
            
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
            
        return spinnerView
    }
    
    func removeSpinner(_ view : UIView?) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                view?.isHidden = true
            } completion: { _ in
                view?.removeFromSuperview()
            }
            
        }
    }

}
