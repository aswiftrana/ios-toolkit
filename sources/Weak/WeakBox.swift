//
//  WeakBox.swift
//  UpcomingEvents
//
//  Created by Asad Rana on 2/9/20.
//  Copyright © 2020 anrana. All rights reserved.
//

import Foundation

final class WeakBox<T: AnyObject> {
    weak var unbox: T?
    init(_ value: T) {
        unbox = value
    }
}
