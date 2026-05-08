import SwiftUI

extension Animation {
    static func liftBounce(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeOut(duration: 0.12)
            : .spring(response: 0.3, dampingFraction: 0.5)
    }

    static func liftSpring(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeOut(duration: 0.15)
            : .spring(response: 0.5, dampingFraction: 0.6)
    }

    static func liftEaseOut(duration: Double, reduceMotion: Bool) -> Animation {
        .easeOut(duration: reduceMotion ? min(duration, 0.12) : duration)
    }

    static func liftEaseInOut(duration: Double, reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeOut(duration: min(duration, 0.12))
            : .easeInOut(duration: duration)
    }
}
