//
//  SciLineStore.swift
//  SciLine
//
//  Created by Jacob Parker on 24/03/2017.
//  Copyright © 2017 Jacob Parker. All rights reserved.
//

import Foundation
import SwiftyStoreKit

let PurchasesChangedNotification = NSNotification.Name(rawValue: "PurchasesChangedNotification")

enum ScrabbleProduct: String {
    case noAds = "noads"
}

fileprivate let PURCHASE_KEY = "purchases"

class ScrabbleStore {

    static let `default` = ScrabbleStore()

    var purchases = Set<ScrabbleProduct>()

    func loadPurchases() {
        let existingPurchaseNames = (UserDefaults.standard.object(forKey: PURCHASE_KEY) as? [String]) ?? [String]()
        purchases = Set(existingPurchaseNames.map { ScrabbleProduct(rawValue: $0)! })
    }

    func get(product: ScrabbleProduct, completion: @escaping (RetrieveResults) -> Void) {
        SwiftyStoreKit.retrieveProductsInfo([product.rawValue], completion: completion)
    }

    func restorePurchases(completion: (() -> Void)? = nil) {
        SwiftyStoreKit.restorePurchases {
            purchases in
            self.purchases = Set(purchases.restoredProducts.map { ScrabbleProduct(rawValue: $0.productId)! })
            self.updateStoredPurchases()
            self.postNotification()
            completion?()
        }
    }

    func purchase(product: ScrabbleProduct, completion: (() -> Void)? = nil) {
        if TARGET_IPHONE_SIMULATOR == 0 {
            restorePurchases {
                guard !self.purchases.contains(product) else { return }

                SwiftyStoreKit.purchaseProduct(product.rawValue) {
                    result in
                    switch result {
                    case .success(product: let purchase):
                        self.purchases.update(with: ScrabbleProduct(rawValue: purchase.productId) ?? product)
                        self.updateStoredPurchases()
                        self.postNotification()
                    case .error(error: let error):
                        print(error)
                    }
                }
                completion?()
            }
        } else {
            purchases.update(with: product)
            updateStoredPurchases()
            postNotification()
            completion?()
        }
    }


    func steal(product: ScrabbleProduct) {
        purchases.update(with: product)
    }

    fileprivate func updateStoredPurchases() {
        let purchaseNames = Array(self.purchases).map { $0.rawValue }
        UserDefaults.standard.set(purchaseNames, forKey: PURCHASE_KEY)
    }

    fileprivate func postNotification() {
        NotificationCenter.default.post(name: PurchasesChangedNotification, object: nil)
    }

}

extension ScrabbleStore {

    var hasNoAds: Bool { return purchases.contains(.noAds) }
    
}
