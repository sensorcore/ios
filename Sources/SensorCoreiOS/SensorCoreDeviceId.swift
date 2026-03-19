import Foundation

/// Generates and persists a stable anonymous device identifier.
///
/// The identifier is a UUID v4 string stored in `UserDefaults`. It is created
/// on first access and reused across all subsequent app launches. This ensures
/// every log entry always has a `user_id`, even when the developer does not
/// provide one explicitly.
///
/// ## Lifecycle
/// - **Created**: Automatically on first `SensorCoreDeviceId.id` access.
/// - **Persists**: Across app relaunches (stored in `UserDefaults`).
/// - **Cleared**: On app reinstall (standard `UserDefaults` behavior) or
///   by calling ``reset()``.
///
/// ## Thread Safety
/// `UserDefaults.standard` is thread-safe on Apple platforms. The worst-case
/// race (two threads both see `nil` and write) results in one write winning,
/// which is fine — both UUIDs are valid, and subsequent reads will always
/// return the winner.
///
/// ## Why `UserDefaults` over Keychain?
/// - No entitlements or capabilities required.
/// - Reinstall = new device ID, which is the correct semantic for anonymous
///   tracking (Keychain survives reinstalls, which would be unexpected).
/// - Simpler API with no error handling needed.
public enum SensorCoreDeviceId {

    /// The `UserDefaults` key used to store the device identifier.
    private static let storageKey = "com.sensorcore.device_id"

    /// A stable, auto-generated UUID string for this device.
    ///
    /// On first access, generates a new UUID v4 and saves it to `UserDefaults`.
    /// All subsequent calls return the same value, even across app launches.
    ///
    /// ```swift
    /// let id = SensorCoreDeviceId.id  // e.g. "A1B2C3D4-E5F6-..."
    /// ```
    public static var id: String {
        if let existing = UserDefaults.standard.string(forKey: storageKey),
           !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: storageKey)
        return newId
    }

    /// Removes the stored device identifier so a new one is generated on next access.
    ///
    /// Call this when the user logs out if you want the next anonymous session
    /// to be tracked as a different End-User in SensorCore analytics.
    ///
    /// ```swift
    /// // On logout
    /// SensorCore.resetDeviceId()
    /// SensorCore.shared.config?.defaultUserId = nil
    /// ```
    public static func reset() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
