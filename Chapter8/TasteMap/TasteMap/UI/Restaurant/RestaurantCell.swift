//
//  RestaurantCell.swift
//  TasteMap
//
//  Created by Kevin McNeish on 8/28/24.
//

import UIKit

class RestaurantCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblCuisine: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblNeighborhood: UILabel!
    @IBOutlet weak var lblHours: UILabel!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    var restaurant: RestaurantEntity?
    
    var photos = [Data]() // Array to hold the photo data
        
    override func awakeFromNib() {
        super.awakeFromNib()
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
    }
    
    // UICollectionViewDataSource methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        // Convert Data to UIImage and set it in the photo cell
        let photoData = photos[indexPath.row]
        if let image = UIImage(data: photoData) {
            photoCell.imgPhoto.image = image
        }
        
        return photoCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Define the size of each PhotoCell inside the imageCollectionView
        return CGSize(width: 128.0, height: 128.0) // Square images
    }
    
}
