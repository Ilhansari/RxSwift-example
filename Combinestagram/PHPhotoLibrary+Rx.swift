//
//  PHPhotoLibrary+Rx.swift
//  Combinestagram
//
//  Created by Ilhan Sari on 3.02.2021.
//  Copyright © 2021 Underplot ltd. All rights reserved.
//

import Foundation
import Photos
import RxSwift

extension PHPhotoLibrary {
  static var authorized: Observable<Bool> {
    return Observable.create({ observer in
      DispatchQueue.main.async {
        if authorizationStatus() == .authorized {
          observer.onNext(true)
          observer.onCompleted()
        } else {
          requestAuthorization({ newStatus in
            observer.onNext(newStatus == .authorized)
            observer.onCompleted()
          })
        }
      }
      return Disposables.create()
    })
  }
}