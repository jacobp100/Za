//
//  IAPViewController.swift
//  Scrabble
//
//  Created by Jacob Parker on 02/05/2017.
//  Copyright © 2017 Jacob Parker. All rights reserved.
//

import UIKit
import Foundation

class IAPViewController: UIViewController {

    @IBOutlet var upgradeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        ScrabbleStore.default.get(product: .noAds) {
            result in
            guard let product = result.retrievedProducts.first else { return }
            guard let priceString = product.localizedPrice else { return }
            self.upgradeButton.setTitle("\(self.upgradeButton.currentTitle ?? "") (\(priceString))", for: .normal)
            self.setLayout()
        }

        setLayout()
    }

    func setLayout() {
        preferredContentSize = view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }

    @IBAction func upgradeButtonPressed(_ sender: Any) {
        ScrabbleStore.default.purchase(product: .noAds)
    }

    @IBAction func restorePurchasesButtonPressed(_ sender: Any) {
        ScrabbleStore.default.restorePurchases()
    }

}
