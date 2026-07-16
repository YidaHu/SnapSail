import SnapSailCore

enum L10n {
    static func text(_ key: AppTextKey) -> String {
        AppLocalization.text(key, language: AppPreferences.shared.language)
    }
}
