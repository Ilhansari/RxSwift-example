/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import RxSwift
import RxRelay

class MainViewController: UIViewController {
  
  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!
  
  private let bag = DisposeBag()
  private let images = BehaviorRelay<[UIImage]>(value: [])
  
  private var imageCache = [Int]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    images
      .throttle(0.5, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak imagePreview] photos in
      guard let preview = imagePreview else { return }
      preview.image = photos.collage(size: preview.frame.size)
    })
    .disposed(by: bag)
    
    images.asObservable().subscribe(onNext: { [weak self] photos in
      self?.updateUI(photos: photos)
    })
    .disposed(by: bag)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    print("resources: \(RxSwift.Resources.total)")
  }
  
  @IBAction func actionClear() {
    images.accept([])
    imageCache = []
  }
  
  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    PhotoWriter.save(image).share()
      .subscribe(onError: { error in
      self.alert("Error").subscribe({ _ in }).disposed(by: self.bag)
    }, onCompleted: { [weak self] in
      guard let self = self else { return }
      self.alert("Saved").subscribe({ _ in }).disposed(by: self.bag)
      self.actionClear()
    }).disposed(by: bag)
  }
  
  @IBAction func actionAdd() {
    if #available(iOS 13.0, *) {
      let photosViewController = storyboard?.instantiateViewController(identifier: "PhotosViewController") as! PhotosViewController
      navigationController?.pushViewController(photosViewController, animated: true)
      photosViewController
        .selectedPhotos
        .share()
        .takeWhile{ [weak self] image in
          return (self?.images.value.count  ?? 0) < 6
        }
        .filter({ [weak self] newImage in
          let len = newImage.pngData()?.count ?? 0
          guard self?.imageCache.contains(len) == false
                  && newImage.size.width > newImage.size.height else {
            return false
          }
          self?.imageCache.append(len)
          return true
        })
        .subscribe(onNext: { [weak self] newImage in
          guard let images = self?.images  else { return }
          images.accept(images.value + [newImage])
        }, onDisposed: {
          print("completed photo selection")
        })
        .disposed(by: bag)
      photosViewController.selectedPhotos.ignoreElements()
        .subscribe(onCompleted: { [weak self] in
          self?.updateNavigationIcon()
        }).disposed(by: photosViewController.bag)
    }
  }
  
  private func updateUI(photos: [UIImage]) {
    buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
    buttonClear.isEnabled = photos.count > 0
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }
  
  private func updateNavigationIcon() {
    let icon = imagePreview.image?.scaled(CGSize(width: 22, height: 22)) .withRenderingMode(.alwaysOriginal)
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
  }
}
