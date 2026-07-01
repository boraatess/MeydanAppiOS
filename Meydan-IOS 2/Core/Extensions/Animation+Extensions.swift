import SwiftUI

extension Animation {
    static var snappy: Animation {
        .interpolatingSpring(stiffness: 400, damping: 15)
    }
}
