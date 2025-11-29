//
//  FixtureGenerator.swift
//  DBPerformanceTests
//
//  1M 레코드 Fixture 생성기
//  [TM-30] Fixture 파일 포맷: JSON (메타데이터 + 레코드 배열)
//  [TM-32] description 길이 분포: 50-200자(30%), 200-500자(40%), 500-2000자(30%)
//

import Foundation

/// Fixture 생성기
/// - 1M FlatModel 또는 RelationalModel 생성
/// - Zipf 분포 적용
/// - JSON 파일로 저장
struct FixtureGenerator {
    private let seed: UInt64
    private var random: SeededRandomGenerator

    init(seed: UInt64 = 42) {
        self.seed = seed
        self.random = SeededRandomGenerator(seed: seed)
    }

    // MARK: - FlatModel Generation

    /// FlatModel 배열 생성
    /// - Parameter count: 생성할 레코드 수 (기본 1,000,000)
    /// - Returns: FlatModel 배열
    mutating func generateFlatModels(count: Int = 1_000_000) -> [FlatModel] {
        var models: [FlatModel] = []
        models.reserveCapacity(count)

        let nameGen = ZipfianGenerator.nameGenerator
        let categoryGen = ZipfianGenerator.categoryGenerator
        let startDate = Date(timeIntervalSince1970: 1672531200) // 2023-01-01
        let endDate = Date(timeIntervalSince1970: 1735689600)   // 2024-12-31
        let dateRange = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970

        for i in 0..<count {
            let id = String(format: "FLAT-%06d", i + 1)

            // Zipf 분포로 name, category 생성
            let name = nameGen.generate(from: ValueGenerators.productNames, random: random.next())
            let category = categoryGen.generate(from: ValueGenerators.categories, random: random.next())

            // 균등 분포로 price 생성
            let price = random.nextInt(in: 100..<50001)

            // 균등 분포로 date 생성
            let randomDate = startDate.addingTimeInterval(random.next() * dateRange)

            // 혼합 길이로 description 생성
            let description = generateDescription()

            // 70% true, 30% false
            let isActive = random.nextBool(probability: 0.7)

            let model = FlatModel(
                id: id,
                name: name,
                category: category,
                price: price,
                date: randomDate,
                description: description,
                isActive: isActive
            )

            models.append(model)

            // 진행 상황 출력 (100K마다)
            if (i + 1) % 100_000 == 0 {
                print("Generated \(i + 1) / \(count) records...")
            }
        }

        return models
    }

    /// FlatModel Fixture 파일 생성 및 저장
    /// - Parameters:
    ///   - filePath: 저장할 파일 경로
    ///   - count: 생성할 레코드 수
    mutating func generateFlatFixture(to filePath: String, count: Int = 1_000_000) throws {
        print("Generating \(count) FlatModel records...")
        let records = generateFlatModels(count: count)

        print("Creating fixture wrapper...")
        let metadata = FixtureMetadata(
            totalRecords: count,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            datasetVersion: "1.0",
            distribution: FixtureMetadata.DistributionInfo(
                name: "Zipf(s=1.3, k=100)",
                category: "Zipf(s=1.5, k=50)"
            )
        )

        let wrapper = FixtureWrapper(metadata: metadata, records: records)

        print("Encoding to JSON...")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(wrapper)

        print("Writing to file: \(filePath)")
        let url = URL(fileURLWithPath: filePath)
        try data.write(to: url)

        let fileSizeMB = Double(data.count) / 1024.0 / 1024.0
        print("✅ Fixture generated successfully!")
        print("   File size: \(String(format: "%.2f", fileSizeMB)) MB")
        print("   Records: \(count)")
    }

    // MARK: - RelationalModel Generation

    /// ProductRecord 배열 생성
    /// - Parameter count: 생성할 레코드 수
    /// - Returns: ProductRecord 배열
    mutating func generateProductRecords(count: Int = 1_000_000) -> [ProductRecord] {
        var records: [ProductRecord] = []
        records.reserveCapacity(count)

        let nameGen = ZipfianGenerator.nameGenerator
        let categoryGen = ZipfianGenerator.categoryGenerator
        let startDate = Date(timeIntervalSince1970: 1672531200) // 2023-01-01
        let endDate = Date(timeIntervalSince1970: 1735689600)   // 2024-12-31
        let dateRange = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970

        for i in 0..<count {
            let id = String(format: "PROD-%06d", i + 1)

            let name = nameGen.generate(from: ValueGenerators.productNames, random: random.next())
            let category = categoryGen.generate(from: ValueGenerators.categories, random: random.next())
            let price = random.nextInt(in: 100..<50001)
            let randomDate = startDate.addingTimeInterval(random.next() * dateRange)
            let description = generateDescription()
            let isActive = random.nextBool(probability: 0.7)

            // 1~5개 태그 생성 (평균 2.5개)
            let tagCount = random.nextInt(in: 1..<6)
            var tags: [String] = []
            for _ in 0..<tagCount {
                let tag = ValueGenerators.tagNames.randomElement() ?? "tag"
                if !tags.contains(tag) {
                    tags.append(tag)
                }
            }

            let record = ProductRecord(
                id: id,
                name: name,
                category: category,
                price: price,
                date: randomDate,
                description: description,
                isActive: isActive,
                tags: tags
            )

            records.append(record)

            if (i + 1) % 100_000 == 0 {
                print("Generated \(i + 1) / \(count) records...")
            }
        }

        return records
    }

    /// RelationalModel Fixture 파일 생성 및 저장
    /// - Parameters:
    ///   - filePath: 저장할 파일 경로
    ///   - count: 생성할 레코드 수
    mutating func generateRelationalFixture(to filePath: String, count: Int = 1_000_000) throws {
        print("Generating \(count) ProductRecord records...")
        let products = generateProductRecords(count: count)

        print("Creating fixture wrapper...")
        let metadata = FixtureMetadata(
            totalRecords: count,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            datasetVersion: "1.0",
            distribution: FixtureMetadata.DistributionInfo(
                name: "Zipf(s=1.3, k=100)",
                category: "Zipf(s=1.5, k=50)"
            )
        )

        let wrapper = RelationalFixtureWrapper(metadata: metadata, products: products, tags: nil)

        print("Encoding to JSON...")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(wrapper)

        print("Writing to file: \(filePath)")
        let url = URL(fileURLWithPath: filePath)
        try data.write(to: url)

        let fileSizeMB = Double(data.count) / 1024.0 / 1024.0
        print("✅ Fixture generated successfully!")
        print("   File size: \(String(format: "%.2f", fileSizeMB)) MB")
        print("   Records: \(count)")
    }

    // MARK: - Description Generation

    /// description 필드 생성
    /// [TM-32] description 길이 분포: 50-200자(30%), 200-500자(40%), 500-2000자(30%)
    /// - Returns: 혼합 길이의 description 문자열
    private mutating func generateDescription() -> String {
        let rand = random.next()
        let targetLength: Int

        if rand < 0.3 {
            // 30%: 짧은 설명 (50~200자)
            targetLength = random.nextInt(in: 50..<201)
        } else if rand < 0.7 {
            // 40%: 중간 설명 (200~500자)
            targetLength = random.nextInt(in: 200..<501)
        } else {
            // 30%: 긴 상세 설명 (500~2000자)
            targetLength = random.nextInt(in: 500..<2001)
        }

        return generateText(length: targetLength)
    }

    /// 텍스트 생성 (사전 기반)
    /// - Parameter length: 목표 길이
    /// - Returns: 생성된 텍스트
    private mutating func generateText(length: Int) -> String {
        let words = DescriptionWords.dictionary
        var text = ""
        var wordCount = 0

        while text.count < length {
            let word = words[random.nextInt(in: 0..<words.count)]
            text += word

            wordCount += 1

            // 문장 부호 추가 (자연스러움)
            if wordCount % 8 == 0 {
                text += ". "
            } else if wordCount % 4 == 0 {
                text += ", "
            } else {
                text += " "
            }
        }

        // 목표 길이에 맞춰 자르기
        let trimmed = String(text.prefix(length))
        return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Description Words Dictionary

/// description 생성용 단어 사전
struct DescriptionWords {
    static let dictionary: [String] = [
        "product", "quality", "excellent", "premium", "innovative", "advanced", "modern", "professional",
        "reliable", "durable", "efficient", "powerful", "versatile", "compact", "lightweight", "portable",
        "feature", "design", "performance", "technology", "solution", "system", "device", "tool",
        "high", "best", "top", "great", "perfect", "ideal", "superior", "outstanding",
        "customer", "satisfaction", "guarantee", "warranty", "support", "service", "experience", "value",
        "easy", "simple", "convenient", "user-friendly", "intuitive", "smart", "quick", "fast",
        "safe", "secure", "trusted", "certified", "approved", "tested", "proven", "verified",
        "new", "latest", "updated", "improved", "enhanced", "upgraded", "revolutionary", "cutting-edge",
        "affordable", "economical", "cost-effective", "budget", "savings", "deal", "offer", "price",
        "includes", "features", "offers", "provides", "delivers", "ensures", "guarantees", "supports",
        "compatible", "works", "fits", "matches", "connects", "integrates", "combines", "pairs",
        "available", "stock", "ready", "shipping", "delivery", "order", "purchase", "buy",
        "material", "construction", "build", "made", "manufactured", "produced", "crafted", "engineered"
    ]
}
