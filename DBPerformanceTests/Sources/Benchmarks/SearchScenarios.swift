//
//  SearchScenarios.swift
//  DBPerformanceTests
//
//  4가지 검색 시나리오 실행
//  [TM-08~11] Equality, Range, Complex, Full-Text 검색
//

import Foundation

/// 검색 시나리오 실행기
@MainActor
struct SearchScenarios {
    private let benchmark = SearchBenchmark()

    // MARK: - Realm

    /// Realm 검색 시나리오 실행
    func runRealm(searcher: RealmSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // TM-08: Equality Search
        let equalityResult = try benchmark.measure {
            try searcher.searchByName("Product_12345", indexed: indexed)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            equalityResult,
            scenario: "Equality",
            indexed: indexed,
            queryCondition: "name == 'Product_12345'"
        ))

        // TM-09: Range Search
        let rangeResult = try benchmark.measure {
            try searcher.rangeSearch(priceMin: 1000, priceMax: 5000)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeResult,
            scenario: "Range",
            indexed: indexed,
            queryCondition: "price BETWEEN 1000 AND 5000"
        ))

        // TM-10: Complex Condition Search
        let complexResult = try benchmark.measure {
            try searcher.complexSearch(
                category: "Electronics",
                priceMin: 2000,
                priceMax: 8000,
                dateFrom: Date(timeIntervalSince1970: 1609459200) // 2021-01-01
            )
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexResult,
            scenario: "Complex",
            indexed: indexed,
            queryCondition: "category='Electronics' AND price BETWEEN 2000-8000 AND date>='2021-01-01'"
        ))

        // TM-11: Full-Text Search
        let fullTextResult = try benchmark.measure {
            try searcher.fullTextSearch("premium")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextResult,
            scenario: "FullText",
            indexed: indexed,
            queryCondition: "description CONTAINS 'premium'"
        ))

        return results
    }

    // MARK: - CoreData

    /// CoreData 검색 시나리오 실행
    func runCoreData(searcher: CoreDataSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // TM-08: Equality Search
        let equalityResult = try benchmark.measure {
            try searcher.searchByName("Product_12345", indexed: indexed)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            equalityResult,
            scenario: "Equality",
            indexed: indexed,
            queryCondition: "name == 'Product_12345'"
        ))

        // TM-09: Range Search
        let rangeResult = try benchmark.measure {
            try searcher.rangeSearch(priceMin: 1000, priceMax: 5000)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeResult,
            scenario: "Range",
            indexed: indexed,
            queryCondition: "price BETWEEN 1000 AND 5000"
        ))

        // TM-10: Complex Condition Search
        let complexResult = try benchmark.measure {
            try searcher.complexSearch(
                category: "Electronics",
                priceMin: 2000,
                priceMax: 8000,
                dateFrom: Date(timeIntervalSince1970: 1609459200)
            )
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexResult,
            scenario: "Complex",
            indexed: indexed,
            queryCondition: "category='Electronics' AND price BETWEEN 2000-8000 AND date>='2021-01-01'"
        ))

        // TM-11: Full-Text Search
        let fullTextResult = try benchmark.measure {
            try searcher.fullTextSearch("premium")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextResult,
            scenario: "FullText",
            indexed: indexed,
            queryCondition: "description CONTAINS 'premium'"
        ))

        return results
    }

    // MARK: - SwiftData

    /// SwiftData 검색 시나리오 실행
    func runSwiftData(searcher: SwiftDataSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // TM-08: Equality Search
        let equalityResult = try benchmark.measure {
            try searcher.searchByName("Product_12345", indexed: indexed)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            equalityResult,
            scenario: "Equality",
            indexed: indexed,
            queryCondition: "name == 'Product_12345'"
        ))

        // TM-09: Range Search
        let rangeResult = try benchmark.measure {
            try searcher.rangeSearch(priceMin: 1000, priceMax: 5000)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeResult,
            scenario: "Range",
            indexed: indexed,
            queryCondition: "price BETWEEN 1000 AND 5000"
        ))

        // TM-10: Complex Condition Search
        let complexResult = try benchmark.measure {
            try searcher.complexSearch(
                category: "Electronics",
                priceMin: 2000,
                priceMax: 8000,
                dateFrom: Date(timeIntervalSince1970: 1609459200)
            )
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexResult,
            scenario: "Complex",
            indexed: indexed,
            queryCondition: "category='Electronics' AND price BETWEEN 2000-8000 AND date>='2021-01-01'"
        ))

        // TM-11: Full-Text Search
        let fullTextResult = try benchmark.measure {
            try searcher.fullTextSearch("premium")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextResult,
            scenario: "FullText",
            indexed: indexed,
            queryCondition: "description CONTAINS 'premium'"
        ))

        return results
    }

    // MARK: - UserDefaults

    /// UserDefaults 검색 시나리오 실행
    func runUserDefaults(searcher: UserDefaultsSearcher, indexed: Bool = false) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // TM-08: Equality Search
        let equalityResult = try benchmark.measure {
            try searcher.searchByName("Product_12345", indexed: indexed)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            equalityResult,
            scenario: "Equality",
            indexed: indexed,
            queryCondition: "name == 'Product_12345'"
        ))

        // TM-09: Range Search
        let rangeResult = try benchmark.measure {
            try searcher.rangeSearch(priceMin: 1000, priceMax: 5000)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeResult,
            scenario: "Range",
            indexed: indexed,
            queryCondition: "price BETWEEN 1000 AND 5000"
        ))

        // TM-10: Complex Condition Search
        let complexResult = try benchmark.measure {
            try searcher.complexSearch(
                category: "Electronics",
                priceMin: 2000,
                priceMax: 8000,
                dateFrom: Date(timeIntervalSince1970: 1609459200)
            )
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexResult,
            scenario: "Complex",
            indexed: indexed,
            queryCondition: "category='Electronics' AND price BETWEEN 2000-8000 AND date>='2021-01-01'"
        ))

        // TM-11: Full-Text Search
        let fullTextResult = try benchmark.measure {
            try searcher.fullTextSearch("premium")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextResult,
            scenario: "FullText",
            indexed: indexed,
            queryCondition: "description CONTAINS 'premium'"
        ))

        return results
    }
}
