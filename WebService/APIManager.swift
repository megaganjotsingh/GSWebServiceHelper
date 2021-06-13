//
//  APIManager.swift
//  Task Manager
//
//  Created by Gagan Mac on 21/09/20.
//  Copyright © 2020 IT Manufactory. All rights reserved.
//

import Foundation
import AVFoundation
import AppAuth

extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}

class APIManager {
    
    static let shared = APIManager()
    private var notificationView: UIView?
    
    /**
         Tell the type of error to the user
         - parameter error: give the param of type error as web error
         */
            
    func handleError(_ error: WebError<CustomError>) {
            
        switch error {
        case .noInternetConnection:
            APIManager.shared.addAlert(fromTop: "The internet connection is lost")
        case .unauthorized:
            break
        case .other:
            APIManager.shared.addAlert(fromTop: "Something went wrong")
        case .custom(let error):
            APIManager.shared.addAlert(fromTop: error.message)
        }
    }
    
    func addAlert(fromTop text: String?) {
      
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let sceneDelegate = windowScene.delegate as? SceneDelegate
        else {
          return
        }
        
        guard let window = sceneDelegate.window else { return }
        let view = window.viewWithTag(909090)
        if let view = view {
            view.removeFromSuperview()
        }

        let statusBarHeight = window.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let viewHeight = 44.0 + statusBarHeight
        let width = UIScreen.main.bounds.width
        let tap = UITapGestureRecognizer(target: self, action: #selector(handle(tap:)))

        let topNotificationView = UIView(frame: CGRect(x: 0, y: -viewHeight, width: width, height: viewHeight))
        topNotificationView.backgroundColor = UIColor.clear
        topNotificationView.tag = 909090
        notificationView = topNotificationView
        topNotificationView.addGestureRecognizer(tap)
        

        let messageBackLabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: viewHeight))
        messageBackLabel.backgroundColor = UIColor.daBlue
        messageBackLabel.addGestureRecognizer(tap)
        topNotificationView.addSubview(messageBackLabel)

        let messageLabel = UILabel(frame: CGRect(x: 10, y: 10, width: width - 20, height: viewHeight))
        messageLabel.textColor = UIColor.white
        messageLabel.backgroundColor = UIColor.clear
        messageLabel.numberOfLines = 2
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.SFRounded(ofSize: 15, style: .regular)
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.minimumScaleFactor = 8
        messageLabel.text = text
        topNotificationView.addSubview(messageLabel)
        messageLabel.addGestureRecognizer(tap)
        window.addSubview(topNotificationView)
        
        // making a vibration
        let impactGenerator = UINotificationFeedbackGenerator()
        impactGenerator.notificationOccurred(.error)

        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            options: .allowUserInteraction,
            animations: {
//                AudioServicesPlaySystemSoundWithCompletion(1104, nil)
                topNotificationView.frame = CGRect(x: 0, y: 0, width: width, height: viewHeight)
            }, completion: { _ in })

        UIView.animate(
            withDuration: 0.3,
            delay: 4.0,
            options: .allowUserInteraction,
            animations: {
//                AudioServicesPlaySystemSoundWithCompletion(1104, nil)
                topNotificationView.frame = CGRect(x: 0, y: -viewHeight, width: width, height: viewHeight)
            }, completion: { _ in
                topNotificationView.removeFromSuperview()
            }
        )
        
    }
    
    @objc
    func handle(tap: UISwipeGestureRecognizer) {
        print("tappeddddd")
    }
    
}

extension APIManager {
    
    /**
    Will fetch all tasks that should be shown in the upcoming section
       - usedBy: MyTasksVC
       - Parameters:
           - completion: it has API response
    */
    
    func sampleApi(onView: UIView, showLoading: Bool, completion: @escaping (Result<BaseTask, WebError<CustomError>>) -> Void) {
        var task: URLSessionDataTask?
        task?.cancel()
        
        let url = WebClient(baseUrl: APIConstants.baseUrl)
                
        let resource = Resource<BaseTask, CustomError>(path: "apiEndPoint", method: .get, params: [:], headers: [:])
        
        task = url.load(resource: resource, onView: onView, showLoading: showLoading) { response in
            if let value = response.value {
                completion(.success(value))
            } else if let error = response.error {
                completion(.failure(error))
            }
            
        }
        
    }
    
}


struct BaseTask {
    
}

struct CustomError {
    let message: String?
}
