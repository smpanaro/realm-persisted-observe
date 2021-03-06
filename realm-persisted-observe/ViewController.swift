//
//  ViewController.swift
//  realm-persisted-observe
//
//  Created by Stephen Panaro on 11/6/21.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {

    var oldModel = OldStyleModel()
    var newModel = NewStyleModel()
    var mixedModel = MixedStylesModel()

    var tokens = [NotificationToken]()
    var observations = [NSKeyValueObservation]()

    override func viewDidLoad() {
        super.viewDidLoad()

        let _ = try! Realm()

        observeModels()

        let button = UIButton(primaryAction: UIAction(handler: { [weak self] _ in
            self?.incrementModels()
        }))
        button.setTitle("Increment", for: .normal)
        placeButton(button)
    }

    func observeModels() {
        observations.append(
            oldModel.observe(\OldStyleModel.count, options: [.new]) { _, change in
                print("old model count changed to \(change.newValue!)")
            }
        )

        // Obj-C Style KVO
        newModel.addObserver(self, forKeyPath: "count", options: [.new], context: nil)

        // KVO fails on this line with:
        // Fatal error: Could not extract a String from KeyPath Swift.ReferenceWritableKeyPath<realm_persisted_observe.NewStyleModel, Swift.Int>
//        observations.append(
//            newModel.observe(\NewStyleModel.count, options: [.new]) { _, change in
//                print("new model count changed to \(change.newValue!)")
//            }
//        )

        // Realm observation fails on this line with:
        // Terminating app due to uncaught exception 'RLMException', reason: 'Only objects which are managed by a Realm support change notifications'
//        tokens.append(
//            newModel.observe(keyPaths: [\NewStyleModel.count], on: nil) { [unowned self] change in
//                print("new model count changed to \(self.newModel.count)")
//            }
//        )

        // Swift Style KVO
        // Fails when `mixedModel.count` is incremented with:
        // Simultaneous accesses to <address>, but modification requires exclusive access.
//        observations.append(
//            mixedModel.observe(\MixedStylesModel.count, options: [.new]) { _, change in
//                print("mixed model count changed to \(change.newValue!)")
//            }
//        )
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let newValue = change?[.newKey] {
            print("new model count changed to \(newValue)")
        }
        else {
            print("new model count changed but no value received")
        }
    }

    func incrementModels() {
        oldModel.count += 1
        newModel.count += 1
        mixedModel.count += 1
    }

    func placeButton(_ button: UIButton) {
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    deinit {
        tokens = []
        observations = []
        removeObserver(self, forKeyPath: "count")
    }
}

class OldStyleModel: Object {
    @objc dynamic var count: Int = 0
}

class NewStyleModel: Object {
    @Persisted var count: Int = 0
}

class MixedStylesModel: Object {
    @Persisted @objc dynamic var count: Int = 0
}
