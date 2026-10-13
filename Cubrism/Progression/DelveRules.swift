import Foundation

enum DelveError: Error, Equatable {
    case invalidValue(String)
    case invalidTransition
    case staleFloor
    case invalidLoot
    case invalidEquipment
    case samplingFailed
}

enum DelveRarity: Int, CaseIterable, Codable {
    case common, uncommon, rare, epic, legendary

    var statMultiplier: Double { [1, 1.25, 1.5, 2, 2.5][rawValue] }
}

struct DelvePerformance: Equatable {
    let speed: Double
    let accuracy: Double
    let avoidance: Double

    // Inputs are normalized combat measurements. Measuring shots, active
    // time, and damage in SpriteKit is a separate integration step.
    init(speed: Double, accuracy: Double, avoidance: Double) throws {
        guard [speed, accuracy, avoidance].allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
            throw DelveError.invalidValue("performance")
        }
        self.speed = speed
        self.accuracy = accuracy
        self.avoidance = avoidance
    }

    var score: Double { 0.4 * speed + 0.4 * accuracy + 0.2 * avoidance }
}

struct DelveRewardRoll: Equatable {
    let power: Double
    let rarity: DelveRarity
}

struct DelveRules: Codable, Equatable {
    // Challenge adjustment is a starting tuning value, not playtested balance.
    // Storing the rules in the account snapshot keeps an in-flight floor from
    // changing its settlement rules merely because the app was relaunched.
    var challengeExponent = 1.0
    var difficultySpread = 0.05

    func validate() throws {
        guard challengeExponent.isFinite, challengeExponent >= 0,
              difficultySpread.isFinite, difficultySpread > 0 else {
            throw DelveError.invalidValue("rules")
        }
    }

    static func validateScore(_ score: Double) throws {
        guard score.isFinite, score >= 1 else { throw DelveError.invalidValue("Delve") }
    }

    static func scalingInput(_ difficulty: Double) throws -> Double {
        try validateScore(difficulty)
        return (difficulty - 1) / 100
    }

    static func continuationBonus(depth: Int) throws -> Double {
        guard depth >= 1 else { throw DelveError.invalidValue("depth") }
        return 0.1 * Double(min(depth - 1, 5))
    }

    func sampleDifficulty<R: RandomNumberGenerator>(rating: Double, using random: inout R) throws -> Double {
        try Self.validateScore(rating)
        try validate()
        // Box-Muller followed by rejection below the floor minimum. There is
        // no upper difficulty cap. The retry limit detects a broken RNG/input.
        for _ in 0..<1000 {
            let u = 1 - Double.random(in: 0..<1, using: &random)
            let v = Double.random(in: 0..<1, using: &random)
            let normal = sqrt(-2 * log(u)) * cos(2 * Double.pi * v)
            let sample = rating * (1 + difficultySpread * normal)
            if sample.isFinite && sample >= 1 { return sample }
        }
        throw DelveError.samplingFailed
    }

    static func rarityProbabilities(difficulty: Double, depth: Int = 1) throws -> [Double] {
        try validateScore(difficulty)
        guard depth >= 1 else { throw DelveError.invalidValue("depth") }
        let t = min((difficulty - 1) / 9999, 1)
        let growth = t * (2 - t)
        let base = [0.49 - 0.44 * growth, 0.30 + 0.075 * growth,
                    0.15 + 0.225 * growth, 0.05 + 0.10 * growth, 0.01 + 0.04 * growth]
        var cumulative = 0.0
        var previousBest = 0.0
        return base.enumerated().map { index, probability in
            cumulative += probability
            // Best of d independent draws, evaluated without a depth-sized loop.
            let best = index == base.count - 1 ? 1 : pow(min(cumulative, 1), Double(depth))
            defer { previousBest = best }
            return max(0, best - previousBest)
        }
    }

    static func rollRewards<R: RandomNumberGenerator>(difficulty: Double, depth: Int,
                                                      using random: inout R) throws -> [DelveRewardRoll] {
        let probabilities = try rarityProbabilities(difficulty: difficulty, depth: depth)
        let thirdChance = try 2 * continuationBonus(depth: depth)
        let count = 2 + (Double.random(in: 0..<1, using: &random) < thirdChance ? 1 : 0)
        return (0..<count).map { _ in
            let draw = Double.random(in: 0..<1, using: &random)
            var cumulative = 0.0
            for (rarity, probability) in zip(DelveRarity.allCases, probabilities) {
                cumulative += probability
                if draw < cumulative { return DelveRewardRoll(power: difficulty, rarity: rarity) }
            }
            return DelveRewardRoll(power: difficulty, rarity: .legendary)
        }
    }

    func winGain(entryRating: Double, difficulty: Double, depth: Int,
                 performance: DelvePerformance) throws -> Double {
        try Self.validateScore(entryRating)
        try Self.validateScore(difficulty)
        try validate()
        let result = try 10 * pow(difficulty / entryRating, challengeExponent)
            * (1 + Self.continuationBonus(depth: depth)) * (1 + 0.1 * performance.score)
        guard result.isFinite else { throw DelveError.invalidValue("gain") }
        return result
    }

    func loss(entryRating: Double, difficulty: Double) throws -> Double {
        try Self.validateScore(entryRating)
        try Self.validateScore(difficulty)
        try validate()
        let baseLoss = min(20, 2 + 8 * ((entryRating - 1) / 2499))
        let result = baseLoss * pow(entryRating / difficulty, challengeExponent)
        guard result.isFinite else { throw DelveError.invalidValue("loss") }
        return result
    }
}
