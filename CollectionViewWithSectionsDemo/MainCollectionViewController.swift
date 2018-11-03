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
        if items.count > 10 {
            return 3
        } else if items.count > 5 {
            return 2
        } else {
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //приведенный ниже алгоритм служит для выдачи корректного количества предметов в секции
        var result = 0

        counter = counter - 5
        result = counter
        //если ещё не отображенный в коллекции предметов больше нуля, то в одной секции у нас будет 5 предметов
        if result > 0 || result == 0 {
            return 5
        //если меньше нуля, то в последней секции количество предметов будет равным остатку от деления общего количества предметов на 5 (результат всегда будет меньше 5, таким образом возможно отобразить количество предметов в одной секции равным 4,3,2,1
        } else {
            return items.count % 5
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        
        let item = items[indexPath.section * 5 + indexPath.row]
        //в этом блоке принтов выдается корректное положение предмета
        print("items[indexPath.row] is \(indexPath.row)")
        print("items[indexPath.section] is \(indexPath.section)")
        print("items[indexPath.section * 5 + indexPath.row] is \(items[indexPath.section * 5 + indexPath.row].name!)")
        
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
            op = BlockOperation { (self.collectionView?.insertItems(at: [newIndexPath!])) }
        case .delete:
            guard let indexPath = indexPath else { return }
            //выдает корректное положение предмета. Например [1,1]
            print("self.indx! \(self.indx!)")
            //выдает НЕкорректное положение предмета, если количество секций больше 1 штуки! Например выдает [0,6], тогда как должен выдавать [1,1]
            print("indexPath \(indexPath)")
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
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({
            self.blockOperations.forEach { $0.start() }
            print("Запустили self.blockOperations.forEach { $0.start() }")
        }, completion: { (finished) in
            self.blockOperations.removeAll(keepingCapacity: false)
            print("Запустили self.blockOperations.removeAll(keepingCapacity: false)")
        })
    }
}
