import Foundation

struct ClientRateLimiter: Sendable {
    private static let key = "com.kiwi.scanTimestamps"
    private let dailyLimit: Int

    init(dailyLimit: Int = 4) {
        self.dailyLimit = dailyLimit
    }

    func canScan() -> Bool {
        remaining() > 0
    }

    func remaining() -> Int {
        max(0, dailyLimit - todayScans().count)
    }

    func recordScan() {
        var timestamps = todayScans()
        timestamps.append(Date())
        UserDefaults.standard.set(
            timestamps.map { $0.timeIntervalSince1970 },
            forKey: Self.key
        )
    }

    private func todayScans() -> [Date] {
        let stored = UserDefaults.standard.array(forKey: Self.key) as? [TimeInterval] ?? []
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return stored
            .map { Date(timeIntervalSince1970: $0) }
            .filter { $0 >= startOfDay }
    }
}
