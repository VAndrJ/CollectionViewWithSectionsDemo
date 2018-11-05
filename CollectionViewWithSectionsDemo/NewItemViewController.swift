import UIKit
import CoreData

class NewItemViewController: UIViewController {

    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        
        
        performSegue(withIdentifier: "unwindSegue", sender: self)
    }
}
