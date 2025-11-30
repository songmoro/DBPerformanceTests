//
//  ZipfianGenerator.swift
//  DBPerformanceTests
//
//  Zipf 분포 생성기
//  [CR-36] Zipf 분포 파라미터: name(s=1.3, k=100), category(s=1.5, k=50)
//  [TM-31] Zipf 분포 생성: seed 기반 의사 난수, 반복 가능
//

import Foundation

/// Zipf 분포 생성기
/// - 현실적인 데이터 분포를 위한 Zipfian distribution
/// - P(k) = (1/k^s) / H_n, 여기서 H_n = Σ(1/i^s) for i=1 to n
struct ZipfianGenerator {
    /// skewness 파라미터 (일반적으로 1.0 ~ 2.0)
    let skewness: Double

    /// 고유값 개수
    let uniqueCount: Int

    /// 정규화 상수 (Harmonic number)
    private let harmonicNumber: Double

    /// 누적 확률 테이블 (Binary search 용)
    private let cumulativeProbabilities: [Double]

    /// 초기화
    /// - Parameters:
    ///   - skewness: 편향도 (높을수록 상위 값에 집중)
    ///   - uniqueCount: 고유값 개수
    init(skewness: Double, uniqueCount: Int) {
        self.skewness = skewness
        self.uniqueCount = uniqueCount

        // Harmonic number 계산 (정규화 상수)
        var sum = 0.0
        for i in 1...uniqueCount {
            sum += 1.0 / pow(Double(i), skewness)
        }
        self.harmonicNumber = sum

        // 누적 확률 테이블 생성
        var cumulative = 0.0
        var table: [Double] = []
        for i in 1...uniqueCount {
            let probability = (1.0 / pow(Double(i), skewness)) / harmonicNumber
            cumulative += probability
            table.append(cumulative)
        }
        self.cumulativeProbabilities = table
    }

    /// Zipf 분포를 따르는 인덱스 생성 (0-based)
    /// - Parameter random: 0.0 ~ 1.0 사이의 랜덤값
    /// - Returns: 0 ~ (uniqueCount-1) 사이의 인덱스
    func generateIndex(random: Double) -> Int {
        // Binary search로 누적 확률 테이블에서 인덱스 찾기
        var low = 0
        var high = cumulativeProbabilities.count - 1

        while low < high {
            let mid = (low + high) / 2
            if cumulativeProbabilities[mid] < random {
                low = mid + 1
            } else {
                high = mid
            }
        }

        return low
    }

    /// Zipf 분포를 따르는 값 생성
    /// - Parameters:
    ///   - values: 값 배열 (크기 = uniqueCount)
    ///   - random: 0.0 ~ 1.0 사이의 랜덤값
    /// - Returns: Zipf 분포에 따라 선택된 값
    func generate<T>(from values: [T], random: Double) -> T {
        precondition(values.count == uniqueCount, "Values count must match uniqueCount")
        let index = generateIndex(random: random)
        return values[index]
    }

    /// 빈도 분포 계산 (테스트용)
    /// - Parameter totalCount: 전체 생성 개수
    /// - Returns: 각 인덱스별 예상 빈도
    func expectedFrequencies(totalCount: Int) -> [Int] {
        var frequencies: [Int] = []
        for i in 1...uniqueCount {
            let probability = (1.0 / pow(Double(i), skewness)) / harmonicNumber
            let frequency = Int(round(probability * Double(totalCount)))
            frequencies.append(frequency)
        }
        return frequencies
    }
}

// MARK: - Seeded Random Generator

/// Seed 기반 의사 난수 생성기
/// - 동일한 seed로 동일한 난수 시퀀스 생성
/// - [TM-31] 반복 가능한 데이터 생성
struct SeededRandomGenerator {
    private var state: UInt64

    /// 초기화
    /// - Parameter seed: 시드값
    init(seed: UInt64) {
        self.state = seed
    }

    /// 다음 난수 생성 (0.0 ~ 1.0)
    /// - Linear Congruential Generator (LCG)
    mutating func next() -> Double {
        // LCG 파라미터 (Numerical Recipes)
        let a: UInt64 = 1664525
        let c: UInt64 = 1013904223
        let m: UInt64 = UInt64.max

        state = (a &* state &+ c) % m
        return Double(state) / Double(m)
    }

    /// 범위 내 정수 생성
    /// - Parameter range: 범위 (예: 0..<100)
    mutating func nextInt(in range: Range<Int>) -> Int {
        let random = next()
        let value = Int(random * Double(range.count))
        return range.lowerBound + value
    }

    /// Bool 생성 (확률 기반)
    /// - Parameter probability: true 확률 (0.0 ~ 1.0)
    mutating func nextBool(probability: Double = 0.5) -> Bool {
        return next() < probability
    }
}

// MARK: - Preset Generators

extension ZipfianGenerator {
    /// name 필드용 Zipf 생성기 (s=1.3, k=100)
    static let nameGenerator = ZipfianGenerator(skewness: 1.3, uniqueCount: 100)

    /// category 필드용 Zipf 생성기 (s=1.5, k=50)
    static let categoryGenerator = ZipfianGenerator(skewness: 1.5, uniqueCount: 50)
}

// MARK: - Value Generators

struct ValueGenerators {
    /// 상품명 목록 (100개)
    static let productNames: [String] = {
        var names: [String] = []
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for i in 0..<100 {
            let char1 = alphabet[alphabet.index(alphabet.startIndex, offsetBy: i / 26)]
            let char2 = alphabet[alphabet.index(alphabet.startIndex, offsetBy: i % 26)]
            names.append("Product-\(char1)\(char2)")
        }
        return names
    }()

    /// 카테고리 목록 (50개)
    static let categories: [String] = [
        "Electronics", "Books", "Home", "Sports", "Toys",
        "Clothing", "Food", "Beauty", "Automotive", "Garden",
        "Health", "Music", "Movies", "Games", "Office",
        "Pet", "Baby", "Tools", "Jewelry", "Shoes",
        "Luggage", "Grocery", "Handmade", "Industrial", "Arts",
        "Crafts", "Outdoors", "Kitchen", "Furniture", "Appliances",
        "Software", "Computers", "Cameras", "CellPhones", "Accessories",
        "Musical", "Instruments", "VideoGames", "Watches", "Collectibles",
        "Fine Art", "Wine", "Magazines", "Gift Cards", "Fashion",
        "Smart Home", "Hobby", "Wellness", "Stationery", "Subscription"
    ]

    /// 태그 목록 (200개)
    static let tagNames: [String] = {
        var tags: [String] = []
        let prefixes = ["new", "sale", "hot", "premium", "limited", "eco", "pro", "mini", "max", "ultra"]
        let bases = ["tech", "quality", "value", "best", "top", "choice", "pick", "deal", "offer", "buy"]
        let suffixes = ["2024", "2023", "today", "now", "special", "plus", "extra", "super", "mega", "grand"]

        for prefix in prefixes {
            for base in bases {
                tags.append("\(prefix)-\(base)")
                if tags.count >= 200 { return tags }
            }
        }

        for suffix in suffixes {
            for base in bases {
                tags.append("\(base)-\(suffix)")
                if tags.count >= 200 { return tags }
            }
        }

        return tags
    }()
}

// MARK: - Test Helper Extension

extension ValueGenerators {

    // MARK: - Most Frequent Values

    /// Get the most frequent product name (Zipf rank 1)
    /// Zipf 분포에서 가장 높은 빈도로 나타나는 상품명
    /// - Returns: "Product-AA" (rank 1, ~1.5% of 1M records)
    static var mostFrequentName: String {
        productNames[0]
    }

    /// Get the most frequent category (Zipf rank 1)
    /// Zipf 분포에서 가장 높은 빈도로 나타나는 카테고리
    /// - Returns: "Electronics" (rank 1, ~4% of 1M records)
    static var mostFrequentCategory: String {
        categories[0]
    }

    // MARK: - Access by Rank

    /// Get a specific name by Zipf rank
    /// - Parameter rank: Zipf 순위 (0-based, 0이 가장 빈번)
    /// - Returns: 해당 순위의 상품명
    static func nameByRank(_ rank: Int) -> String {
        guard rank >= 0 && rank < productNames.count else {
            return productNames[0]
        }
        return productNames[rank]
    }

    /// Get a specific category by Zipf rank
    /// - Parameter rank: Zipf 순위 (0-based, 0이 가장 빈번)
    /// - Returns: 해당 순위의 카테고리
    static func categoryByRank(_ rank: Int) -> String {
        guard rank >= 0 && rank < categories.count else {
            return categories[0]
        }
        return categories[rank]
    }

    /// Get a specific tag by index
    /// - Parameter index: Tag index (0-based)
    /// - Returns: 해당 인덱스의 태그명
    static func tagByIndex(_ index: Int) -> String {
        guard index >= 0 && index < tagNames.count else {
            return tagNames[0]
        }
        return tagNames[index]
    }

    // MARK: - Expected Frequency Calculations

    /// Get expected frequency for a name at given rank
    /// Zipf 분포를 기반으로 특정 순위의 상품명이 나타날 예상 빈도
    /// - Parameters:
    ///   - rank: Zipf 순위 (0-based)
    ///   - totalRecords: 전체 레코드 수 (기본값: 1,000,000)
    /// - Returns: 예상 출현 횟수
    static func expectedFrequency(forNameRank rank: Int, totalRecords: Int = 1_000_000) -> Int {
        let generator = ZipfianGenerator.nameGenerator
        let frequencies = generator.expectedFrequencies(totalCount: totalRecords)
        guard rank >= 0 && rank < frequencies.count else {
            return 0
        }
        return frequencies[rank]
    }

    /// Get expected frequency for a category at given rank
    /// Zipf 분포를 기반으로 특정 순위의 카테고리가 나타날 예상 빈도
    /// - Parameters:
    ///   - rank: Zipf 순위 (0-based)
    ///   - totalRecords: 전체 레코드 수 (기본값: 1,000,000)
    /// - Returns: 예상 출현 횟수
    static func expectedFrequency(forCategoryRank rank: Int, totalRecords: Int = 1_000_000) -> Int {
        let generator = ZipfianGenerator.categoryGenerator
        let frequencies = generator.expectedFrequencies(totalCount: totalRecords)
        guard rank >= 0 && rank < frequencies.count else {
            return 0
        }
        return frequencies[rank]
    }

    // MARK: - Validation Helpers

    /// Check if a name exists in the generated pool
    /// - Parameter name: 확인할 상품명
    /// - Returns: 존재 여부
    static func isValidName(_ name: String) -> Bool {
        productNames.contains(name)
    }

    /// Check if a category exists in the generated pool
    /// - Parameter category: 확인할 카테고리
    /// - Returns: 존재 여부
    static func isValidCategory(_ category: String) -> Bool {
        categories.contains(category)
    }

    /// Check if a tag exists in the generated pool
    /// - Parameter tag: 확인할 태그
    /// - Returns: 존재 여부
    static func isValidTag(_ tag: String) -> Bool {
        tagNames.contains(tag)
    }
}
