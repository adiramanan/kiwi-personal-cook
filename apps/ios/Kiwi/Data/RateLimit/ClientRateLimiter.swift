import Foundation

final class ClientRateLimiter {
    private let defaults: UserDefaults
    private let dailyLimit = 4
    private let timestampsKey = "kiwi_scan_timestamps"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Returns whether the user can perform a scan based on client-side tracking.
    /// Note: The server is authoritative. This is a UX convenience only.
    func canScan() -> Bool {
        return remaining() > 0
    }

    /// Records a scan timestamp.
    func recordScan() {
        var timestamps = getTodayTimestamps()
        timestamps.append(Date())
        saveTodayTimestamps(timestamps)
    }

    /// Returns the number of remaining scans for today.
    func remaining() -> Int {
        let todayCount = getTodayTimestamps().count
        return max(0, dailyLimit - todayCount)
    }

    // MARK: - Private

    private func getTodayTimestamps() -> [Date] {
        guard let timestamps = defaults.array(forKey: timestampsKey) as? [Double] else {
            return []
        }

        let today = midnightUTC()
        return timestamps
            .map { Date(timeIntervalSince1970: $0) }
            .filter { $0 >= today }
    }

    private func saveTodayTimestamps(_ timestamps: [Date]) {
        let today = midnightUTC()
        let todayTimestamps = timestamps
            .filter { $0 >= today }
            .map { $0.timeIntervalSince1970 }
        defaults.set(todayTimestamps, forKey: timestampsKey)
    }

    private func midnightUTC() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.startOfDay(for: Date())
    }
}
