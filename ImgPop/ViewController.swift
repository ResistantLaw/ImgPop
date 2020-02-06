//
//  ViewController.swift
//  ImgPop
//
//  Created by Austin Whitelaw on 1/25/20.
//  Copyright © 2020 Austin Whitelaw. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController {
    
    var backgroundView: UIView!
    var imageView: UIImageView!
    var filterSwipeView: FilterSwipeView!
    var titleScrollView: UIScrollView!
    var titleSwipeView: UICollectionView!
    
    var currentImage: UIImage!
    var context: CIContext!
    var currentFilter: CIFilter!
    
    let slider = UISlider()
    let slider2 = UISlider()
    var point0: CIVector!
    var point1: CIVector!
    var step = 0
    var saturation: Float = 1.5  // 0-10
    var unsharpMaskRadius: Float = 2.5  // 0-10
    var unsharkMaskIntensity: Float = 0.5  // 0-10
    var radius: Float = 6.0  // 0-30
    
    var allFiltersArray: [CIFilter] = []
    var selectedArray: [Int] = []
    let edgeSpacing: CGFloat = 30
    let pageCellId = "pageCell"
    let titleId = "titleId"
    
    enum FilterSet: String {
        case Sepia = "CISepiaTone"
        case Vignette = "CIVignette"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        for x in 0..<10 {
            if let filter = x % 2 == 0 ? CIFilter(name: FilterSet.Sepia.rawValue) : CIFilter(name: FilterSet.Vignette.rawValue) {
                allFiltersArray.append(filter)
            }
        }
        print(allFiltersArray)
        
        title = "ImgPop"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPicture))
        
        imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = .darkGray
        view.addSubview(imageView)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: edgeSpacing).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: edgeSpacing).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -edgeSpacing).isActive = true
        
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        filterSwipeView = FilterSwipeView(frame: CGRect(x: 0, y: 0, width: 200, height: 50), collectionViewLayout: layout)
        view.addSubview(filterSwipeView)
        
        let titleLayout = UICollectionViewFlowLayout()
        titleLayout.scrollDirection = .horizontal
        titleSwipeView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 50), collectionViewLayout: titleLayout)
        view.addSubview(titleSwipeView)
        titleSwipeView.translatesAutoresizingMaskIntoConstraints = false
        titleSwipeView.bounces = false
        titleSwipeView.isPagingEnabled = true // may or may not be needed
        titleSwipeView.backgroundColor = .green
        titleSwipeView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        titleSwipeView.topAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
        titleSwipeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: edgeSpacing).isActive = true
        titleSwipeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -edgeSpacing).isActive = true
        titleSwipeView.delegate = self
        titleSwipeView.dataSource = self
        titleSwipeView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: titleId)
        titleSwipeView.setContentOffset(CGPoint(x: -75, y: 0), animated: false)
        //titleSwipeView.contentInset = UIEdgeInsets(top: 0, left: 75, bottom: 0, right: 0)
        
        filterSwipeView.backgroundColor = .purple
        filterSwipeView.layer.borderColor = UIColor.white.cgColor
        filterSwipeView.layer.borderWidth = 1
        filterSwipeView.bounces = false
        filterSwipeView.translatesAutoresizingMaskIntoConstraints = false
        filterSwipeView.heightAnchor.constraint(equalToConstant: 170).isActive = true
        filterSwipeView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -edgeSpacing).isActive = true
        filterSwipeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: edgeSpacing).isActive = true
        filterSwipeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -edgeSpacing).isActive = true
        filterSwipeView.topAnchor.constraint(equalTo: titleSwipeView.bottomAnchor).isActive = true
        filterSwipeView.register(FilterCell.self, forCellWithReuseIdentifier: pageCellId)
        filterSwipeView.isPagingEnabled = true
        filterSwipeView.delegate = self
        filterSwipeView.dataSource = self
        
        context = CIContext()
        currentFilter = CIFilter(name: "CICrystallize")
//        for item in currentFilter.attributes {
//            print(item)
//        }
    }
    
    @objc func radiusChanged() {
        radius = slider.value
        applyProcessing()
    }
    
    @objc func saturationChanged() {
        saturation = slider2.value
        applyProcessing()
    }
    
    func convertTapToImg(_ point: CGPoint) -> CGPoint? {
        let xRatio = imageView.frame.width / currentImage.size.width
        let yRatio = imageView.frame.height / currentImage.size.height
        let ratio = min(xRatio, yRatio)
        let imgWidth = currentImage.size.width * ratio
        let imgHeight = currentImage.size.height * ratio

        var tap = point
        var borderWidth: CGFloat = 0
        var borderHeight: CGFloat = 0
        // detect border
        if ratio == yRatio {
            // border is left and right
            borderWidth = (imageView.frame.size.width - imgWidth) / 2
            tap.x -= borderWidth
        } else {
            // border is top and bottom
            borderHeight = (imageView.frame.size.height - imgHeight) / 2
            tap.y -= borderHeight
        }
        
        if point.x < borderWidth || point.x > borderWidth + imgWidth {
            return nil
        }
        if point.y < borderHeight || point.y > borderHeight + imgHeight {
            return nil
        }

        let xScale = tap.x / (imageView.frame.width - 2 * borderWidth)
        let yScale = tap.y / (imageView.frame.height - 2 * borderHeight)
        let pixelX = currentImage.size.width * xScale
        let pixelY = currentImage.size.height * yScale
        return CGPoint(x: pixelX, y: pixelY)
   	 }
    
    
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == filterSwipeView {
            let cell = filterSwipeView.dequeueReusableCell(withReuseIdentifier: pageCellId, for: indexPath) as! FilterCell
            
            if selectedArray.contains(indexPath.row) {
                cell.checkButton.isSelected = true
            } else {
                cell.checkButton.isSelected = false
            }
            
            //cell.backgroundColor = indexPath.row % 2 == 0 ? .blue : .red
            cell.backgroundColor = cell.checkButton.isSelected ? .green : .red
            
            cell.buttonAction = {
                cell.checkButton.isSelected.toggle()
                cell.backgroundColor = cell.checkButton.isSelected ? .green : .red
                
                if cell.checkButton.isSelected {
                    self.selectedArray.append(indexPath.row)
                } else {
                    if let itemIndex = self.selectedArray.firstIndex(of: indexPath.row) {
                        self.selectedArray.remove(at: itemIndex)
                    }
                }
                self.applyProcessing()
            }
            return cell
        }
        
        if collectionView == titleSwipeView {
            let cell = titleSwipeView.dequeueReusableCell(withReuseIdentifier: titleId, for: indexPath)
            cell.backgroundColor = indexPath.row % 2 == 0 ? .red : .blue
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == filterSwipeView {
            return CGSize(width: filterSwipeView.frame.width, height: filterSwipeView.frame.height)
        } else {
            return CGSize(width: 200, height: titleSwipeView.frame.height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == filterSwipeView {
            titleSwipeView.contentOffset = CGPoint(x: scrollView.contentOffset.x * (200/354), y: 0)
        }
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        
        dismiss(animated: true)
        currentImage = image
        
        imageView.image = currentImage // temporary change
        //applyProcessing()
    }
    
    func applyProcessing() {
        
        let beginImage = CIImage(image: currentImage)
        
        var processingImage = beginImage
        
        if selectedArray.count == 0 {
            self.imageView.image = currentImage
        } else {
            for index in selectedArray {
                let filter = allFiltersArray[index]
                filter.setValue(processingImage, forKey: kCIInputImageKey)
                processingImage = filter.outputImage
            }
            
            if let finalIndex = selectedArray.last {
                let finalFilter = allFiltersArray[finalIndex]
                if let processedImage = context.createCGImage(finalFilter.outputImage!, from: finalFilter.outputImage!.extent) {
                    let finishedImage = UIImage(cgImage: processedImage, scale: currentImage.scale, orientation: currentImage.imageOrientation)
                    self.imageView.image = finishedImage
                }
            }
        }
        
//        if let cgimg = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
//            let processedImage = UIImage(cgImage: cgimg)
//            self.imageView.image = processedImage
//        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
    }
    
}
