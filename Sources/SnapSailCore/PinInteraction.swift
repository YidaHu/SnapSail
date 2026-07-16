public enum PinPrimaryClickAction: Equatable {
    case drag
    case close
}

public enum PinInteraction {
    public static func primaryAction(clickCount: Int) -> PinPrimaryClickAction {
        clickCount >= 2 ? .close : .drag
    }
}
