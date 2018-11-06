//
//  ItemsArray.swift
//  CollectionViewWithSectionsDemo
//
//  Created by VAndrJ on 11/7/18.
//  Copyright © 2018 Artyom Grigoryan. All rights reserved.
//

import Foundation

struct ItemsArray: Equatable, Collection {
    let items: [Item]
    let sectionIndex: Int

    typealias Index = Int

    ///Нарезаем массив здесь, чтобы каждый раз не писать
    static func split(items: [Item], capacity: Int = 5) -> [ItemsArray] {
        let chunkedArray = items.chunked(into: capacity).enumerated().map({ItemsArray(items: $1, sectionIndex: $0)})
        return chunkedArray
    }

    var startIndex: Int {
        return items.startIndex
    }

    var endIndex: Int {
        return items.endIndex
    }

    subscript(i: Int) -> Item {
        return items[i]
    }

    public func index(after i: Int) -> Int {
        return items.index(after: i)
    }

    ///Чтобы секции с одним и тем же номером не перезагружались из-за изменения элементов в секции
    static func ==(lhs: ItemsArray, rhs: ItemsArray) -> Bool {
        return lhs.sectionIndex == rhs.sectionIndex
    }
}
