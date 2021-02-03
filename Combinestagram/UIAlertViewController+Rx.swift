//
//  UIAlertViewController+Rx.swift
//  Combinestagram
//
//  Created by Ilhan Sari on 1.02.2021.
//  Copyright © 2021 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {
  func alert(_ title: String, description: String? = nil) -> Observable<UIAlertAction> {
    return Observable.create { observer in
      let alertController = UIAlertController(title: title, message: description, preferredStyle: .alert)
      let alertAction = UIAlertAction(title: title, style: .default, handler: { _ in
        observer.onCompleted()
      })
      alertController.addAction(alertAction)
      self.present(alertController, animated: true, completion: nil)
      return Disposables.create { alertController.dismiss(animated: true, completion: nil) }
    }
  }
}
