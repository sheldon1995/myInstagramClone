//
//  SelectImageVC.swift
//  InstgramClone
//
//  Created by Sheldon on 1/11/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
import Photos


private let reusePhotoCellIdentifier = "SelectPhotoCell"
private let headerIdentifier = "SelectPhotoHeader"
class SelectImageVC : UICollectionViewController, UICollectionViewDelegateFlowLayout{
    
    // MARK: Properties
    var images = [UIImage]()
    // PHAsset is a representation of an image, video, or Live Photo in the Photos library.
    var assets = [PHAsset]()
    var setSelectedImage : UIImage?
    var header: SelectPhotoHeader?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //
        
        // Register cell classes.
        self.collectionView!.register(SelectPhotoCell.self, forCellWithReuseIdentifier: reusePhotoCellIdentifier)
        
        // Register collection header.
        self.collectionView!.register(SelectPhotoHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerIdentifier)
        
        // Change colleciton view background color.
        collectionView.backgroundColor = .white
        
        // Add left and right navigation item button.
        configureNavigationButtons()
        
        // Fetch photos and set to collection view.
        fetchPhotos()
        
    }
    
    // MARK: UICollectionViewFlowLayout
    
    // Set size of header
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.width)
    }
    
    // Set collection view lay out for cell
    // We want divide up into four cells per row.
    // 3 is to account for three kind of separating line.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 3) / 4
        return CGSize(width: width, height: width)
    }
    
    // Asks the delegate for the spacing between successive items in the rows
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    // Cell spacing
    // Asks the delegate for the spacing between successive rows 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusePhotoCellIdentifier, for: indexPath) as! SelectPhotoCell
        
        cell.photoImageView.image = images[indexPath.row]
        return cell
    }
    
    // Show the selected image as the header's image.
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerIdentifier, for: indexPath) as! SelectPhotoHeader
        
        if let selectedImage = self.setSelectedImage
        {
            if let index = self.images.firstIndex(of: selectedImage){
                let selectedAsses = self.assets[index]
                let imageManager = PHImageManager.default()
                let targetSize = CGSize(width: 800, height: 800)
                imageManager.requestImage(for: selectedAsses, targetSize: targetSize, contentMode: .default, options: nil, resultHandler: {(
                    image,info) in
                    //header.imageView = ImageZoomView(frame: CGRect(x: 0, y: 0, width: 800, height: 800), image: selectedImage)
                   
                    header.photoImageView.image = selectedImage
                })
            }
        }
        
        self.header = header
        return header
        
    }
    
    // Select one image.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Select one image and let it shown at the header.
        
        self.setSelectedImage = images[indexPath.row]
        self.collectionView.reloadData()

        // When select one image, the screen scroll up to the top, at the item 0.
        let indexPath = IndexPath(item:0,section:0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }
    
    func configureNavigationButtons(){
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(handleNext))
    }
    // MARK: Handlers
    
    @objc func handleCancel(){
        // Dismiss the view controller we presented and take us back to the main interface.
        self.dismiss(animated: true, completion: nil)
    }
    
    // Jump to post view controller by clicking next.
    @objc func handleNext(){
        let upLoadPostVC =  PostViewController()
        // Have access to the header.
        upLoadPostVC.selectedImage = header?.photoImageView.image
        upLoadPostVC.uploadAction = .init(index: 0)
        navigationController?.pushViewController(upLoadPostVC, animated: true)
    }
    
    
    // Get an option that affect the filtering
    func getAssetFetchOptions() ->PHFetchOptions{
        /*
         A set of options that affect the filtering, sorting, and management of results that Photos returns when you fetch asset or collection objects.
         */
        
        let options = PHFetchOptions()
        
        // Fetch the number of first 30 photos
        options.fetchLimit = 30
        
        
        // Sort these photos and get the newest.
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        
        // Set sort descriptor for options
        options.sortDescriptors = [sortDescriptor]
        return options
    }
    
    // Fetch photos from photo library
    func fetchPhotos(){
        // fetchAssets(with: .image, ) Retrieves assets with the specified media type (audio, image, video).
        let allPhotos = PHAsset.fetchAssets(with: .image, options: getAssetFetchOptions())
        
        // Fetch images on background thread
        DispatchQueue.global(qos: .background).async {
            // Enumerate each photo individually and fetch first and continuing to the last one.
            allPhotos.enumerateObjects({ (asset,count,stop) in
                
                // Count starts from 0 to ...
                let imageManager = PHImageManager.default()
                let targetSize = CGSize(width: 800, height: 800)
                let options = PHImageRequestOptions()
                
                // We want to fetch in order
                options.isSynchronous = true
                
                // Request image representaion
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: {(image, info) in
                    // Load the image from the data source into our collection view.
                    // Check if the image exists
                    if let image = image {
                        // Append image to data sourece.
                        
                        self.images.append(image)
                        // Append asset associated with the image to data source.
                        self.assets.append(asset)
                        
                        // Set selected image with first image.
                        if self.setSelectedImage == nil{
                            self.setSelectedImage = image
                        }
                        
                        // Reload collection view with image conce count has completed.
                        if count == allPhotos.count - 1 {
                            
                            // Reload collection view on mian thread.
                            // Need to reload on main thread.
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        }
                        
                    }
                })
                
            })
        }
    }
}
