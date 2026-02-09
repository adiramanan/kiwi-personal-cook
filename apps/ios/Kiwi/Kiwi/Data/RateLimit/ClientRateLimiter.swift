import Foundation

struct ClientRateLimiter {
    private let limit = 4
    private let storageKey = "kiwi.scan.timestamps"
    private let calendar = Calendar(identifier: .gregorian)

    func canScan() -> Bool {
        remaining() > 0
    }

    func recordScan() {
        var timestamps = loadTimestamps()
        timestamps.append(Date())
        save(timestamps: timestamps)
    }

    func remaining() -> Int {
        let timestamps = loadTimestamps()
        let today = timestamps.filter { calendar.isDate($0, inSameDayAs: Date()) }
        return max(0, limit - today.count)
    }

    private func loadTimestamps() -> [Date] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let dates = try? JSONDecoder().decode([Date].self, from: data) else {
            return []
        }
        return dates
    }

    private func save(timestamps: [Date]) {
        let data = try? JSONEncoder().encode(timestamps)
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
