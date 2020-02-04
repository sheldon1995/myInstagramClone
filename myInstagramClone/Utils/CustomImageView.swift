//
//  CustomImageView.swift
//  InstgramClone
//
//  Created by Sheldon on 1/13/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
/*
 
To fix image flicker. The actual photo we want is not the loading photo, which means the url called in the function is not the right url after compared with url.absoluteString.
 
 */
var imageCache = [String:UIImage]()

class CustomImageView:UIImageView{
    var lastImageUrlUsedToLoad:String?
    // Using image cache, we only want to load the image once.
    func loadImage(with urlString:String) {
        
        // set image to nil
        self.image = nil
        
        lastImageUrlUsedToLoad = urlString
        
        // Check if image exists in cache
        if let cachedImage = imageCache[urlString] {
            self.image = cachedImage
            return
        }
        
        // url for image location
        guard let url = URL(string: urlString) else {return}
        
        // Fetch contents of URL
        URLSession.shared.dataTask(with: url) {(data,response,error) in
            // Handle error
            
            if let error = error{
                print("Failed to load image with error: ",error.localizedDescription)
            }
            
            // To make sure the image url that is being to load the image is actually equal to the post image that we are loading.
            //  This function is called until we get the right url parameter.
            if self.lastImageUrlUsedToLoad != url.absoluteString{
                return
            }
            // Image data
            guard let imageData = data else {return}
            
            // Set image using image data
            let photoImage = UIImage(data: imageData)
            
            // Set key and value for image cache
            imageCache[url.absoluteString] = photoImage
            
            // Set image
            DispatchQueue.main.async {
                self.image = photoImage
            }
            // Resume(), to make sure the process continue until the image is loaded.
        }.resume()
    }
    
}
