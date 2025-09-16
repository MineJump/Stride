//
//  StrideWidgetsLiveActivity.swift
//  StrideWidgets
//
//  Created by Hendrik Jaritz on 9/16/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StrideWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct StrideWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StrideWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension StrideWidgetsAttributes {
    fileprivate static var preview: StrideWidgetsAttributes {
        StrideWidgetsAttributes(name: "World")
    }
}

extension StrideWidgetsAttributes.ContentState {
    fileprivate static var smiley: StrideWidgetsAttributes.ContentState {
        StrideWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: StrideWidgetsAttributes.ContentState {
         StrideWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: StrideWidgetsAttributes.preview) {
   StrideWidgetsLiveActivity()
} contentStates: {
    StrideWidgetsAttributes.ContentState.smiley
    StrideWidgetsAttributes.ContentState.starEyes
}
