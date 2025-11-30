//
//  SearchScenarios.swift
//  DBPerformanceTests
//
//  검색 시나리오 실행
//  [TM-08~11] Equality, Range, Complex, Full-Text 검색
//  [TM-36~40] Relational 검색 (Tag 기반)
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
        let totalTests = 4

        // TM-08: Equality Search
        print("[Progress] 25% - Running Equality Search...")
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
        print("[Progress] 50% - Running Range Search...")
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
        print("[Progress] 75% - Running Complex Search...")
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
        print("[Progress] 100% - Running Full-Text Search...")
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
        print("[Progress] 25% - Running Equality Search...")
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
        print("[Progress] 50% - Running Range Search...")
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
        print("[Progress] 75% - Running Complex Search...")
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
        print("[Progress] 100% - Running Full-Text Search...")
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
        print("[Progress] 25% - Running Equality Search...")
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
        print("[Progress] 50% - Running Range Search...")
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
        print("[Progress] 75% - Running Complex Search...")
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
        print("[Progress] 100% - Running Full-Text Search...")
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
        print("[Progress] 25% - Running Equality Search...")
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
        print("[Progress] 50% - Running Range Search...")
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
        print("[Progress] 75% - Running Complex Search...")
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
        print("[Progress] 100% - Running Full-Text Search...")
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

    // MARK: - Relational Search (Realm)

    /// Realm 관계형 검색 시나리오 실행 (ProductRecord + Tags)
    func runRealmRelational(searcher: RealmRelationalSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // TM-36: Tag Equality Search
        print("[Progress] 20% - Running Tag Equality Search...")
        let tagEqualityResult = try benchmark.measure {
            try searcher.searchByTag("electronics", indexed: indexed)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            tagEqualityResult,
            scenario: "Relational-TagEquality",
            indexed: indexed,
            queryCondition: "tags CONTAINS 'electronics'"
        ))

        // TM-37: Range + Tag Search
        print("[Progress] 40% - Running Range + Tag Search...")
        let rangeTagResult = try benchmark.measure {
            try searcher.rangeWithTagSearch(priceMin: 1000, priceMax: 5000, tag: "sale")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeTagResult,
            scenario: "Relational-RangeTag",
            indexed: indexed,
            queryCondition: "price BETWEEN 1000-5000 AND tags CONTAINS 'sale'"
        ))

        // TM-38: Complex + Tag Search
        print("[Progress] 60% - Running Complex + Tag Search...")
        let complexTagResult = try benchmark.measure {
            try searcher.complexWithTagSearch(
                category: "Electronics",
                priceMin: 2000,
                priceMax: 8000,
                dateFrom: Date(timeIntervalSince1970: 1609459200), // 2021-01-01
                tag: "new"
            )
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexTagResult,
            scenario: "Relational-ComplexTag",
            indexed: indexed,
            queryCondition: "category='Electronics' AND price BETWEEN 2000-8000 AND date>='2021-01-01' AND tags CONTAINS 'new'"
        ))

        // TM-39: Full-Text + Tag Search
        print("[Progress] 80% - Running Full-Text + Tag Search...")
        let fullTextTagResult = try benchmark.measure {
            try searcher.fullTextWithTagSearch(keyword: "premium", tag: "electronics")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextTagResult,
            scenario: "Relational-FullTextTag",
            indexed: indexed,
            queryCondition: "description CONTAINS 'premium' AND tags CONTAINS 'electronics'"
        ))

        // TM-40: Multiple Tags Search
        print("[Progress] 100% - Running Multiple Tags Search...")
        let multipleTagsResult = try benchmark.measure {
            try searcher.searchByMultipleTags(["premium", "new"])
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            multipleTagsResult,
            scenario: "Relational-MultipleTags",
            indexed: indexed,
            queryCondition: "tags CONTAINS 'premium' AND tags CONTAINS 'new'"
        ))

        return results
    }

    // MARK: - Relational Search (CoreData)

    /// CoreData 관계형 검색 시나리오 실행
    func runCoreDataRelational(searcher: CoreDataRelationalSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        print("[Progress] 20% - Running Tag Equality Search...")
        let tagEqualityResult = try benchmark.measure {
            try searcher.searchByTag("electronics", indexed: indexed)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            tagEqualityResult,
            scenario: "Relational-TagEquality",
            indexed: indexed,
            queryCondition: "tags CONTAINS 'electronics'"
        ))

        print("[Progress] 40% - Running Range + Tag Search...")
        let rangeTagResult = try benchmark.measure {
            try searcher.rangeWithTagSearch(priceMin: 1000, priceMax: 5000, tag: "sale")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeTagResult,
            scenario: "Relational-RangeTag",
            indexed: indexed,
            queryCondition: "price BETWEEN 1000-5000 AND tags CONTAINS 'sale'"
        ))

        print("[Progress] 60% - Running Complex + Tag Search...")
        let complexTagResult = try benchmark.measure {
            try searcher.complexWithTagSearch(
                category: "Electronics",
                priceMin: 2000,
                priceMax: 8000,
                dateFrom: Date(timeIntervalSince1970: 1609459200),
                tag: "new"
            )
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexTagResult,
            scenario: "Relational-ComplexTag",
            indexed: indexed,
            queryCondition: "category='Electronics' AND price BETWEEN 2000-8000 AND date>='2021-01-01' AND tags CONTAINS 'new'"
        ))

        print("[Progress] 80% - Running Full-Text + Tag Search...")
        let fullTextTagResult = try benchmark.measure {
            try searcher.fullTextWithTagSearch(keyword: "premium", tag: "electronics")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextTagResult,
            scenario: "Relational-FullTextTag",
            indexed: indexed,
            queryCondition: "description CONTAINS 'premium' AND tags CONTAINS 'electronics'"
        ))

        print("[Progress] 100% - Running Multiple Tags Search...")
        let multipleTagsResult = try benchmark.measure {
            try searcher.searchByMultipleTags(["premium", "new"])
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            multipleTagsResult,
            scenario: "Relational-MultipleTags",
            indexed: indexed,
            queryCondition: "tags CONTAINS 'premium' AND tags CONTAINS 'new'"
        ))

        return results
    }

    // MARK: - Relational Search (SwiftData)

    /// SwiftData 관계형 검색 시나리오 실행
    func runSwiftDataRelational(searcher: SwiftDataRelationalSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        print("[Progress] 20% - Running Tag Equality Search...")
        let tagEqualityResult = try benchmark.measure {
            try searcher.searchByTag("electronics", indexed: indexed)
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            tagEqualityResult,
            scenario: "Relational-TagEquality",
            indexed: indexed,
            queryCondition: "tags CONTAINS 'electronics'"
        ))

        print("[Progress] 40% - Running Range + Tag Search...")
        let rangeTagResult = try benchmark.measure {
            try searcher.rangeWithTagSearch(priceMin: 1000, priceMax: 5000, tag: "sale")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeTagResult,
            scenario: "Relational-RangeTag",
            indexed: indexed,
            queryCondition: "price BETWEEN 1000-5000 AND tags CONTAINS 'sale'"
        ))

        print("[Progress] 60% - Running Complex + Tag Search...")
        let complexTagResult = try benchmark.measure {
            try searcher.complexWithTagSearch(
                category: "Electronics",
                priceMin: 2000,
                priceMax: 8000,
                dateFrom: Date(timeIntervalSince1970: 1609459200),
                tag: "new"
            )
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexTagResult,
            scenario: "Relational-ComplexTag",
            indexed: indexed,
            queryCondition: "category='Electronics' AND price BETWEEN 2000-8000 AND date>='2021-01-01' AND tags CONTAINS 'new'"
        ))

        print("[Progress] 80% - Running Full-Text + Tag Search...")
        let fullTextTagResult = try benchmark.measure {
            try searcher.fullTextWithTagSearch(keyword: "premium", tag: "electronics")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextTagResult,
            scenario: "Relational-FullTextTag",
            indexed: indexed,
            queryCondition: "description CONTAINS 'premium' AND tags CONTAINS 'electronics'"
        ))

        print("[Progress] 100% - Running Multiple Tags Search...")
        let multipleTagsResult = try benchmark.measure {
            try searcher.searchByMultipleTags(["premium", "new"])
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            multipleTagsResult,
            scenario: "Relational-MultipleTags",
            indexed: indexed,
            queryCondition: "tags CONTAINS 'premium' AND tags CONTAINS 'new'"
        ))

        return results
    }
}
