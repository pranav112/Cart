//    Cart.swift
//
//    Copyright 2017 Fco Daniel BR.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//    documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
//    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
//    and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
//    Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//    WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import RxSwift
import RxCocoa

/// An object that coordinate the products to sell.
open class Cart<T: ProductProtocol> {
    
    static func shared() -> Cart<T> { return Cart<T>() }
    private init() {
        self.seedCart()
        self.setUpObservers()
    }
    
    /// Describes the product and quantity.
    public struct Item: Codable {
        var product: T
        var quantity: Int
    }
    //public typealias Item = (product: T, quantity: Int)
    
    private let disposeBag = DisposeBag()
    private func setUpObservers() {
        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.persistCart()
            })
            .disposed(by: self.disposeBag)
        
    }
    
    private func seedCart() {
        if let data = UserDefaults.standard.value(forKey: Constants.UserDefaultsKeys.cart) as? Data,
        let items = try? PropertyListDecoder().decode([Item].self, from: data) {
            self.items.accept(items)
        }
    }
    
    private func persistCart() {
        UserDefaults.standard.set(try? PropertyListEncoder().encode(self.itemsDataSource), forKey: Constants.UserDefaultsKeys.cart)
    }

    /// Counts the number of items without regard to quantity of each one.
    /// Use this to know the number of items in a list, e.g. To get the number of rows in a table view.
    public var count: Int {
        get {
            return itemsDataSource.count
        }
    }

    /// Counts the number of products regarding the quantity of each one.
    /// Use this to know the total of products e.g. To display the number of products in cart.
    public var countQuantities: Int {
        get {
            var numberOfProducts = 0
            for item in itemsDataSource {
                numberOfProducts += item.quantity
            }
            return numberOfProducts
        }
    }

    /// The amount to charge.
    open var amount: Double {
        var total: Double = 0
        for item in itemsDataSource {
            total += (item.product.price.toDouble() * Double(item.quantity))
        }
        return total
    }

    /// The list of products to sell.
    private let items = BehaviorRelay<[Item]>(value: [])
    var itemsObservable: Observable<[Item]> {
        return items.asObservable()
    }
    var itemsDataSource: [Item] {
        return items.value
    }
    /// Gets the item at index.
    public subscript(index: Int) -> Item {
        return itemsDataSource[index]
    }

    /// Adds a product to the items.
    /// if the product already exists, increments the quantity, otherwise adds as new one.
    ///
    /// - parameter product: The product to add.
    /// - parameter quantity: How many times will add the products. Default is 1.
    ///
    public func add(_ product: T, quantity: Int = 1) {
        var items = itemsDataSource
        for (index, item) in items.enumerated() {
            if product == item.product {
                items[index].quantity += quantity
                self.items.accept(items)
                return
            }
        }
        items.append(Item(product: product, quantity: quantity))
        self.items.accept(items)
    }

    /// Increments the quantity of an item at index in 1.
    ///
    /// - parameter index: The index of the product to increment.
    ///
    public func increment(at index: Int) {
        var items = itemsDataSource
        items[index].quantity += 1
        self.items.accept(items)
    }

    /// Increments the quantity of the product item.
    ///
    /// - parameter product: The product to increment the quantity.
    ///
    public func increment(_ product: T)  {
        for (index, item) in itemsDataSource.enumerated() {
            if product == item.product {
                increment(at: index)
                break
            }
        }
    }

    /// Decrements the quantity of an item at index in 1, removes from items if the quantity downs to 0.
    ///
    /// - parameter index: The index of the product to reduce.
    ///
    public func decrement(at index: Int) {
        var items = itemsDataSource
        if items[index].quantity > 1 {
            items[index].quantity -= 1
            self.items.accept(items)
        } else {
            remove(at: index)
        }
    }

    /// Decrements the quantity of a product item.
    ///
    /// - parameter product:  The product to reduce the quantity.
    ///
    public func decrement(_ product: T)  {
        for (index, item) in itemsDataSource.enumerated() {
            if product == item.product {
                decrement(at: index)
                break
            }
        }
    }

    /// Removes completely the product at index from the items list, not matter the quantity.
    ///
    /// - parameter index: The index of the product to remove.
    ///
    public func remove(at index: Int) {
        var items = itemsDataSource
        items.remove(at: index)
        self.items.accept(items)
    }

    /// Removes all products from the items list.
    open func clean() {
        self.items.accept([])
    }
}
