//
//  StrideWidgetsBundle.swift
//  StrideWidgets
//
//  Created by Hendrik Jaritz on 9/16/25.
//

import WidgetKit
import SwiftUI

@main
struct StrideWidgetsBundle: WidgetBundle {
    var body: some Widget {
        StrideWidgets()
        StrideWidgetsControl()
        StrideWidgetsLiveActivity()
    }
}
