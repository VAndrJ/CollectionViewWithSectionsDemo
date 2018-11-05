import UIKit
import CoreData


class MainCollectionViewController: UICollectionViewController, UIGestureRecognizerDelegate {

    private var counter = 0
    private var indx: IndexPath?
    private var items: [Item] = []
    private var blockOperations: [BlockOperation] = []
    private var fetchResultsController: NSFetchedResultsController<Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        
        collectionView?.addGestureRecognizer(lpgr)

        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
            fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultsController.delegate = self
            
            do {
                try fetchResultsController.performFetch()
                items = fetchResultsController.fetchedObjects!
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        
        counter = items.count
        print("counter in viewDidLoad is \(counter)")
    }
    
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {}
    
    @IBAction func addNewItemButtonPressed(_ sender: UIBarButtonItem) {
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer!) {
        if gesture.state != .ended {
            return
        }
        
        let p = gesture.location(in: self.collectionView)
        
        if let indexPath = self.collectionView?.indexPathForItem(at: p) {
            let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
            //благодаря такому способу удаляется выбранный пользователем предмет
            fetchRequest.predicate = NSPredicate(format: "name == %@", self.items[indexPath.section * 5 + indexPath.row].name!)
            
            print("self.items[indexPath.section * 5 + indexPath.row].name! is \(self.items[indexPath.section * 5 + indexPath.row].name!)")
           
            do {
                if let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
                    let selectedItem = try context.fetch(fetchRequest)[0]
                    //сохраняем корректное положение предмета в переменную indx, чтобы использовать в performBatchUpdates (в функции didChange anObject: Any)
                    indx = IndexPath(row: indexPath.row, section: indexPath.section)
                    print("indx.section \(indx!.section)")
                    context.delete(selectedItem)
                    
                    do {
                        try context.save()
                        print("Обновление удалось!")
                    } catch let error as NSError {
                        print("Не удалось обновить данные \(error), \(error.userInfo)")
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width:collectionView.frame.size.width, height:50.0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath)
            
            footerView.backgroundColor = UIColor.blue;
            
            return footerView
        default:
            fatalError("Unexpected element kind")
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        print("call numberOfSections")
        
        if items.count % 5 == 0 {
            return items.count / 5
        }
        
        return items.count / 5 + 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //приведенный ниже алгоритм служит для выдачи корректного количества предметов в секции
        print("вызываем numberOfItemsInSection текущ секц равна \(section)")
        counter -= 5
        
        print("result is \(counter)")
        
        if counter > 0 || counter == 0 {
            print("numberOfItemsInSection is (if) \(counter)")
            return 5
        //если меньше нуля, то в последней секции количество предметов будет равным остатку от деления общего количества предметов на 5 (результат всегда будет меньше 5, таким образом возможно отобразить количество предметов в одной секции равным 4,3,2,1
        } else {
            print("numberOfItemsInSection is (else) \(items.count % 5)")
            return items.count % 5
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        
        let item = items[indexPath.section * 5 + indexPath.row]
        
        cell.itemNameTextLabel.text = item.name
        cell.itemImageView.image = UIImage(data: item.image! as Data)

        return cell
    }
}

extension MainCollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: true)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let op: BlockOperation!
        
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            op = BlockOperation { (self.collectionView?.insertItems(at: [newIndexPath])) }
        case .delete:
            guard let indexPath = indexPath else { return }
            //выдает корректное положение предмета. Например [1,1]
            print("self.indx! \(self.indx!)")
            op = BlockOperation { (self.collectionView?.deleteItems(at: [self.indx!])) }
        case .update:
            guard let indexPath = indexPath else { return }
            op = BlockOperation { (self.collectionView?.reloadItems(at: [indexPath])) }
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            op = BlockOperation { (self.collectionView?.moveItem(at: indexPath, to: newIndexPath)) }
        }

        blockOperations.append(op)
        items = controller.fetchedObjects as! [Item]
        counter = items.count
        print("----------counter is: \(counter)----------")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({ [weak self] in
            guard let self = self else { return }
            self.blockOperations.forEach { $0.start() }

            if items.count == 5 {
                self.collectionView.deleteSections(IndexSet(integer: 1))
            }
            
            if items.count == 0 {
                self.collectionView.deleteSections(IndexSet(integer: 0))
            }
            
            print("Запустили self.blockOperations.forEach { $0.start() }")
        }, completion: { (finished) in
            self.blockOperations.removeAll(keepingCapacity: false)
            print("Запустили self.blockOperations.removeAll(keepingCapacity: false)")
        })
    }
}
