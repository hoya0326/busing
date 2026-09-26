//
//  BusingWidgetBundle.swift
//  BusingWidget
//
//  Created by hoyeong on 9/23/26.
//

import WidgetKit
import SwiftUI

@main
@available(iOS 18.0, *)
struct BusingWidgetBundle: WidgetBundle {
    var body: some Widget {
        BusingWidget()
        BusingWidgetControl()
    }
}
