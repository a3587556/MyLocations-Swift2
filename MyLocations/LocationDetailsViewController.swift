import UIKit
import CoreLocation
import CoreData

private let dateFormatter: NSDateFormatter = {
  let formatter = NSDateFormatter()
  formatter.dateStyle = .MediumStyle
  formatter.timeStyle = .ShortStyle
  return formatter
}()

class LocationDetailsViewController: UITableViewController {
  @IBOutlet weak var descriptionTextView: UITextView!
  @IBOutlet weak var categoryLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var addPhotoLabel: UILabel!
  
  var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
  var placemark: CLPlacemark?

  var descriptionText = ""
  var categoryName = "No Category"
  var date = NSDate()
  var observer: AnyObject!
  
  var managedObjectContext: NSManagedObjectContext!
    var image: UIImage? {
        didSet {
            imageView.image = image
            imageView.hidden = false
            imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        }
    }

  var locationToEdit: Location? {
    didSet {
      if let location = locationToEdit {
        descriptionText = location.locationDescription
        categoryName = location.category
        date = location.date
        coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        placemark = location.placemark
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    listenForBackgroundNotification()
    
    if let location = locationToEdit {
        title = "Edit Location"
        if location.hasPhoto {
            if let image = location.photoImage {
                showImage(image)
            }
        }
    }
    
    descriptionTextView.text = descriptionText
    categoryLabel.text = categoryName
    
    latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
    longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
    
    if let placemark = placemark {
      addressLabel.text = stringFromPlacemark(placemark)
    } else {
      addressLabel.text = "No Address Found"
    }
    
    dateLabel.text = formatDate(date)

    let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("hideKeyboard:"))
    gestureRecognizer.cancelsTouchesInView = false
    tableView.addGestureRecognizer(gestureRecognizer)
    
    tableView.backgroundColor = UIColor.blackColor()
    tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
    tableView.indicatorStyle = .White
    
    descriptionTextView.backgroundColor = UIColor.blackColor()
    descriptionTextView.textColor = UIColor.whiteColor()
    
    addPhotoLabel.textColor = UIColor.whiteColor()
    addPhotoLabel.highlightedTextColor = addPhotoLabel.textColor
    
    addressLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
    addressLabel.highlightedTextColor = addressLabel.textColor
  }
  
  func hideKeyboard(gestureRecognizer: UIGestureRecognizer) {
    let point = gestureRecognizer.locationInView(tableView)
    let indexPath = tableView.indexPathForRowAtPoint(point)
    
    if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 {
      return
    }
    
    descriptionTextView.resignFirstResponder()
  }
  
  func stringFromPlacemark(placemark: CLPlacemark) -> String {
    var text = ""
    
    text.addText(placemark.subThoroughfare)
    text.addText(placemark.thoroughfare, withSeparator: ", ")
    text.addText(placemark.locality, withSeparator: ", ")
    text.addText(placemark.administrativeArea, withSeparator: " ")
    text.addText(placemark.postalCode, withSeparator: " ")
    text.addText(placemark.country, withSeparator: ", ")
    
//    if let s = placemark.subThoroughfare {
//      text += s + " "
//    }
//    if let s = placemark.thoroughfare {
//      text += s + ", "
//    }
//    if let s = placemark.locality {
//      text += s + ", "
//    }
//    if let s = placemark.administrativeArea {
//      text += s + " "
//    }
//    if let s = placemark.postalCode {
//      text += s + ", "
//    }
//    if let s = placemark.country {
//      text += s
//    }
    
    return text
  }

  func formatDate(date: NSDate) -> String {
    return dateFormatter.stringFromDate(date)
  }

  @IBAction func done() {
    let hudView = HudView.hudInView(navigationController!.view, animated: true)

    let location: Location
    if let temp = locationToEdit {
      hudView.text = "Updated"
      location = temp
    } else {
      hudView.text = "Tagged"
      location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: managedObjectContext) as! Location
      location.photoID = nil
    }
    
    location.locationDescription = descriptionTextView.text
    location.category = categoryName
    location.latitude = coordinate.latitude
    location.longitude = coordinate.longitude
    location.date = date
    location.placemark = placemark
    
    if let image = image {
        if !location.hasPhoto {
            location.photoID = Location.nextPhotoID()
        }
        
        if let data = UIImageJPEGRepresentation(image, 0.5) {
            do {
                try data.writeToFile(location.photoPath, options: .DataWritingAtomic)
            } catch {
                print("Error writing file: \(error)")
            }
        }
    }
    
    do {
      try managedObjectContext.save()
    } catch {
      fatalCoreDataError(error)
    }

    afterDelay(0.6) {
      self.dismissViewControllerAnimated(true, completion: nil)
    }
  }
  
  @IBAction func cancel() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "PickCategory" {
      let controller = segue.destinationViewController as! CategoryPickerViewController
      controller.selectedCategoryName = categoryName
    }
  }
  
  @IBAction func categoryPickerDidPickCategory(segue: UIStoryboardSegue) {
    let controller = segue.sourceViewController as! CategoryPickerViewController
    categoryName = controller.selectedCategoryName
    categoryLabel.text = categoryName
  }
  
  // MARK: - UITableViewDelegate
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    switch (indexPath.section, indexPath.row) {
    case (0, 0):
        return 88
        
    case (1, _):
        return imageView.hidden ? 44 : 280
        
    case (2, 2):
        addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 10000)
        addressLabel.sizeToFit()
        addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
        return addressLabel.frame.size.height + 20
        
    default:
        return 44
    }
    
//    if indexPath.section == 0 && indexPath.row == 0 {
//      return 88
//      
//    } else if indexPath.section == 1 {
//        if imageView.hidden {
//            return 44
//        } else {
//            return 280
//        }
//    } else if indexPath.section == 2 && indexPath.row == 2 {
//      addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 10000)
//      addressLabel.sizeToFit()
//      addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
//      return addressLabel.frame.size.height + 20
//      
//    } else {
//      return 44
//    }
  }
  
  override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
    if indexPath.section == 0 || indexPath.section == 1 {
      return indexPath
    } else {
      return nil
    }
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.section == 0 && indexPath.row == 0 {
      descriptionTextView.becomeFirstResponder()
    } else if indexPath.section == 1 && indexPath.row == 0 {
      //takePhotoWithCamera()
      //choosePhotoFromLibrary()
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        pickPhoto()
    }
  }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.blackColor()
        
        if let textLabel = cell.textLabel {
            textLabel.textColor = UIColor.whiteColor()
            textLabel.highlightedTextColor = textLabel.textColor
        }
        
        if let detailLabel = cell.detailTextLabel {
            detailLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
            detailLabel.highlightedTextColor = detailLabel.textColor
        }
        
        let selectionView = UIView(frame: CGRect.zero)
        selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        cell.selectedBackgroundView = selectionView
        
        if indexPath.row == 2 {
            let addressLabel = cell.viewWithTag(100) as! UILabel
            addressLabel.textColor = UIColor.whiteColor()
            addressLabel.highlightedTextColor = addressLabel.textColor
        }
    }
    
    func showImage(image: UIImage) {
        imageView.image = image
        imageView.hidden = false
        imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        addPhotoLabel.hidden = true
    }
    
    func listenForBackgroundNotification() {
       observer = NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] _ in
            if let strongSelf = self {
              if strongSelf.presentedViewController != nil {
                strongSelf.dismissViewControllerAnimated(false, completion: nil)
              }
              strongSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
    
    deinit {
        print("*** deinit \(self)")
        NSNotificationCenter.defaultCenter().removeObserver(observer)
    }
}

extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func takePhotoWithCamera() {
        let imagePicker = MyImagePickerController()
        imagePicker.sourceType = .Camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.view.tintColor = view.tintColor
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = MyImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.view.tintColor = view.tintColor
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        image = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if let image = image {
            //showImage(image) //use a didSet property observer on the image instance variable
        }
        
        tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .Default, handler: { _ in self.takePhotoWithCamera() })
        alertController.addAction(takePhotoAction)
        
        let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library", style: .Default, handler: { _ in self.choosePhotoFromLibrary() })
        alertController.addAction(chooseFromLibraryAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
}

