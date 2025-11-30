//
//  SearchScenarios.swift
//  DBPerformanceTests
//
//  검색 시나리오 실행
//  [TM-08~11] Equality, Range, Complex, Full-Text 검색
//  [TM-36~40] Relational 검색 (Tag 기반)
//  [CR-70~73] SearchTestConfig를 통한 중앙 설정 관리
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

        // [TM-08] Equality Search
        print("[Progress] 25% - Running Equality Search...")
        let equalityConfig = SearchTestConfig.equalitySearch
        let equalityParams = equalityConfig.queryParams
        let equalityResult = try benchmark.measure {
            try searcher.searchByName(equalityParams.name!, indexed: indexed)
        }
        // 결과 검증
        if !equalityParams.expectedCount.validate(equalityResult.count) {
            print("⚠️ Warning: \(equalityConfig) returned \(equalityResult.count), expected \(equalityParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            equalityResult,
            scenario: equalityConfig.description,
            indexed: indexed,
            queryCondition: equalityConfig.queryCondition
        ))

        // [TM-09] Range Search
        print("[Progress] 50% - Running Range Search...")
        let rangeConfig = SearchTestConfig.rangeSearch
        let rangeParams = rangeConfig.queryParams
        let rangeResult = try benchmark.measure {
            try searcher.rangeSearch(priceMin: rangeParams.priceMin!, priceMax: rangeParams.priceMax!)
        }
        if !rangeParams.expectedCount.validate(rangeResult.count) {
            print("⚠️ Warning: \(rangeConfig) returned \(rangeResult.count), expected \(rangeParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeResult,
            scenario: rangeConfig.description,
            indexed: indexed,
            queryCondition: rangeConfig.queryCondition
        ))

        // [TM-10] Complex Condition Search
        print("[Progress] 75% - Running Complex Search...")
        let complexConfig = SearchTestConfig.complexSearch
        let complexParams = complexConfig.queryParams
        let complexResult = try benchmark.measure {
            try searcher.complexSearch(
                category: complexParams.category!,
                priceMin: complexParams.priceMin!,
                priceMax: complexParams.priceMax!,
                dateFrom: complexParams.dateFrom!
            )
        }
        if !complexParams.expectedCount.validate(complexResult.count) {
            print("⚠️ Warning: \(complexConfig) returned \(complexResult.count), expected \(complexParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexResult,
            scenario: complexConfig.description,
            indexed: indexed,
            queryCondition: complexConfig.queryCondition
        ))

        // [TM-11] Full-Text Search
        print("[Progress] 100% - Running Full-Text Search...")
        let fullTextConfig = SearchTestConfig.fullTextSearch
        let fullTextParams = fullTextConfig.queryParams
        let fullTextResult = try benchmark.measure {
            try searcher.fullTextSearch(fullTextParams.keyword!)
        }
        if !fullTextParams.expectedCount.validate(fullTextResult.count) {
            print("⚠️ Warning: \(fullTextConfig) returned \(fullTextResult.count), expected \(fullTextParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextResult,
            scenario: fullTextConfig.description,
            indexed: indexed,
            queryCondition: fullTextConfig.queryCondition
        ))

        return results
    }

    // MARK: - CoreData

    /// CoreData 검색 시나리오 실행
    func runCoreData(searcher: CoreDataSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // [TM-08] Equality Search
        print("[Progress] 25% - Running Equality Search...")
        let equalityConfig = SearchTestConfig.equalitySearch
        let equalityParams = equalityConfig.queryParams
        let equalityResult = try benchmark.measure {
            try searcher.searchByName(equalityParams.name!, indexed: indexed)
        }
        if !equalityParams.expectedCount.validate(equalityResult.count) {
            print("⚠️ Warning: \(equalityConfig) returned \(equalityResult.count), expected \(equalityParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            equalityResult,
            scenario: equalityConfig.description,
            indexed: indexed,
            queryCondition: equalityConfig.queryCondition
        ))

        // [TM-09] Range Search
        print("[Progress] 50% - Running Range Search...")
        let rangeConfig = SearchTestConfig.rangeSearch
        let rangeParams = rangeConfig.queryParams
        let rangeResult = try benchmark.measure {
            try searcher.rangeSearch(priceMin: rangeParams.priceMin!, priceMax: rangeParams.priceMax!)
        }
        if !rangeParams.expectedCount.validate(rangeResult.count) {
            print("⚠️ Warning: \(rangeConfig) returned \(rangeResult.count), expected \(rangeParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeResult,
            scenario: rangeConfig.description,
            indexed: indexed,
            queryCondition: rangeConfig.queryCondition
        ))

        // [TM-10] Complex Condition Search
        print("[Progress] 75% - Running Complex Search...")
        let complexConfig = SearchTestConfig.complexSearch
        let complexParams = complexConfig.queryParams
        let complexResult = try benchmark.measure {
            try searcher.complexSearch(
                category: complexParams.category!,
                priceMin: complexParams.priceMin!,
                priceMax: complexParams.priceMax!,
                dateFrom: complexParams.dateFrom!
            )
        }
        if !complexParams.expectedCount.validate(complexResult.count) {
            print("⚠️ Warning: \(complexConfig) returned \(complexResult.count), expected \(complexParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexResult,
            scenario: complexConfig.description,
            indexed: indexed,
            queryCondition: complexConfig.queryCondition
        ))

        // [TM-11] Full-Text Search
        print("[Progress] 100% - Running Full-Text Search...")
        let fullTextConfig = SearchTestConfig.fullTextSearch
        let fullTextParams = fullTextConfig.queryParams
        let fullTextResult = try benchmark.measure {
            try searcher.fullTextSearch(fullTextParams.keyword!)
        }
        if !fullTextParams.expectedCount.validate(fullTextResult.count) {
            print("⚠️ Warning: \(fullTextConfig) returned \(fullTextResult.count), expected \(fullTextParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextResult,
            scenario: fullTextConfig.description,
            indexed: indexed,
            queryCondition: fullTextConfig.queryCondition
        ))

        return results
    }

    // MARK: - SwiftData

    /// SwiftData 검색 시나리오 실행
    func runSwiftData(searcher: SwiftDataSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // [TM-08] Equality Search
        print("[Progress] 25% - Running Equality Search...")
        let equalityConfig = SearchTestConfig.equalitySearch
        let equalityParams = equalityConfig.queryParams
        let equalityResult = try benchmark.measure {
            try searcher.searchByName(equalityParams.name!, indexed: indexed)
        }
        if !equalityParams.expectedCount.validate(equalityResult.count) {
            print("⚠️ Warning: \(equalityConfig) returned \(equalityResult.count), expected \(equalityParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            equalityResult,
            scenario: equalityConfig.description,
            indexed: indexed,
            queryCondition: equalityConfig.queryCondition
        ))

        // [TM-09] Range Search
        print("[Progress] 50% - Running Range Search...")
        let rangeConfig = SearchTestConfig.rangeSearch
        let rangeParams = rangeConfig.queryParams
        let rangeResult = try benchmark.measure {
            try searcher.rangeSearch(priceMin: rangeParams.priceMin!, priceMax: rangeParams.priceMax!)
        }
        if !rangeParams.expectedCount.validate(rangeResult.count) {
            print("⚠️ Warning: \(rangeConfig) returned \(rangeResult.count), expected \(rangeParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeResult,
            scenario: rangeConfig.description,
            indexed: indexed,
            queryCondition: rangeConfig.queryCondition
        ))

        // [TM-10] Complex Condition Search
        print("[Progress] 75% - Running Complex Search...")
        let complexConfig = SearchTestConfig.complexSearch
        let complexParams = complexConfig.queryParams
        let complexResult = try benchmark.measure {
            try searcher.complexSearch(
                category: complexParams.category!,
                priceMin: complexParams.priceMin!,
                priceMax: complexParams.priceMax!,
                dateFrom: complexParams.dateFrom!
            )
        }
        if !complexParams.expectedCount.validate(complexResult.count) {
            print("⚠️ Warning: \(complexConfig) returned \(complexResult.count), expected \(complexParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexResult,
            scenario: complexConfig.description,
            indexed: indexed,
            queryCondition: complexConfig.queryCondition
        ))

        // [TM-11] Full-Text Search
        print("[Progress] 100% - Running Full-Text Search...")
        let fullTextConfig = SearchTestConfig.fullTextSearch
        let fullTextParams = fullTextConfig.queryParams
        let fullTextResult = try benchmark.measure {
            try searcher.fullTextSearch(fullTextParams.keyword!)
        }
        if !fullTextParams.expectedCount.validate(fullTextResult.count) {
            print("⚠️ Warning: \(fullTextConfig) returned \(fullTextResult.count), expected \(fullTextParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextResult,
            scenario: fullTextConfig.description,
            indexed: indexed,
            queryCondition: fullTextConfig.queryCondition
        ))

        return results
    }

    // MARK: - UserDefaults

    /// UserDefaults 검색 시나리오 실행
    func runUserDefaults(searcher: UserDefaultsSearcher, indexed: Bool = false) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // [TM-08] Equality Search
        print("[Progress] 25% - Running Equality Search...")
        let equalityConfig = SearchTestConfig.equalitySearch
        let equalityParams = equalityConfig.queryParams
        let equalityResult = try benchmark.measure {
            try searcher.searchByName(equalityParams.name!, indexed: indexed)
        }
        if !equalityParams.expectedCount.validate(equalityResult.count) {
            print("⚠️ Warning: \(equalityConfig) returned \(equalityResult.count), expected \(equalityParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            equalityResult,
            scenario: equalityConfig.description,
            indexed: indexed,
            queryCondition: equalityConfig.queryCondition
        ))

        // [TM-09] Range Search
        print("[Progress] 50% - Running Range Search...")
        let rangeConfig = SearchTestConfig.rangeSearch
        let rangeParams = rangeConfig.queryParams
        let rangeResult = try benchmark.measure {
            try searcher.rangeSearch(priceMin: rangeParams.priceMin!, priceMax: rangeParams.priceMax!)
        }
        if !rangeParams.expectedCount.validate(rangeResult.count) {
            print("⚠️ Warning: \(rangeConfig) returned \(rangeResult.count), expected \(rangeParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeResult,
            scenario: rangeConfig.description,
            indexed: indexed,
            queryCondition: rangeConfig.queryCondition
        ))

        // [TM-10] Complex Condition Search
        print("[Progress] 75% - Running Complex Search...")
        let complexConfig = SearchTestConfig.complexSearch
        let complexParams = complexConfig.queryParams
        let complexResult = try benchmark.measure {
            try searcher.complexSearch(
                category: complexParams.category!,
                priceMin: complexParams.priceMin!,
                priceMax: complexParams.priceMax!,
                dateFrom: complexParams.dateFrom!
            )
        }
        if !complexParams.expectedCount.validate(complexResult.count) {
            print("⚠️ Warning: \(complexConfig) returned \(complexResult.count), expected \(complexParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexResult,
            scenario: complexConfig.description,
            indexed: indexed,
            queryCondition: complexConfig.queryCondition
        ))

        // [TM-11] Full-Text Search
        print("[Progress] 100% - Running Full-Text Search...")
        let fullTextConfig = SearchTestConfig.fullTextSearch
        let fullTextParams = fullTextConfig.queryParams
        let fullTextResult = try benchmark.measure {
            try searcher.fullTextSearch(fullTextParams.keyword!)
        }
        if !fullTextParams.expectedCount.validate(fullTextResult.count) {
            print("⚠️ Warning: \(fullTextConfig) returned \(fullTextResult.count), expected \(fullTextParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextResult,
            scenario: fullTextConfig.description,
            indexed: indexed,
            queryCondition: fullTextConfig.queryCondition
        ))

        return results
    }

    // MARK: - Relational Search (Realm)

    /// Realm 관계형 검색 시나리오 실행 (ProductRecord + Tags)
    func runRealmRelational(searcher: RealmRelationalSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // [TM-38a] Tag Equality Search
        print("[Progress] 20% - Running Tag Equality Search...")
        let tagEqConfig = SearchTestConfig.tagEqualitySearch
        let tagEqParams = tagEqConfig.queryParams
        let tagEqualityResult = try benchmark.measure {
            try searcher.searchByTag(tagEqParams.tag!, indexed: indexed)
        }
        if !tagEqParams.expectedCount.validate(tagEqualityResult.count) {
            print("⚠️ Warning: \(tagEqConfig) returned \(tagEqualityResult.count), expected \(tagEqParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            tagEqualityResult,
            scenario: tagEqConfig.description,
            indexed: indexed,
            queryCondition: tagEqConfig.queryCondition
        ))

        // [TM-38b] Range + Tag Search
        print("[Progress] 40% - Running Range + Tag Search...")
        let rangeTagConfig = SearchTestConfig.rangeTagSearch
        let rangeTagParams = rangeTagConfig.queryParams
        let rangeTagResult = try benchmark.measure {
            try searcher.rangeWithTagSearch(
                priceMin: rangeTagParams.priceMin!,
                priceMax: rangeTagParams.priceMax!,
                tag: rangeTagParams.tag!
            )
        }
        if !rangeTagParams.expectedCount.validate(rangeTagResult.count) {
            print("⚠️ Warning: \(rangeTagConfig) returned \(rangeTagResult.count), expected \(rangeTagParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeTagResult,
            scenario: rangeTagConfig.description,
            indexed: indexed,
            queryCondition: rangeTagConfig.queryCondition
        ))

        // [TM-38c] Complex + Tag Search
        print("[Progress] 60% - Running Complex + Tag Search...")
        let complexTagConfig = SearchTestConfig.complexTagSearch
        let complexTagParams = complexTagConfig.queryParams
        let complexTagResult = try benchmark.measure {
            try searcher.complexWithTagSearch(
                category: complexTagParams.category!,
                priceMin: complexTagParams.priceMin!,
                priceMax: complexTagParams.priceMax!,
                dateFrom: complexTagParams.dateFrom!,
                tag: complexTagParams.tag!
            )
        }
        if !complexTagParams.expectedCount.validate(complexTagResult.count) {
            print("⚠️ Warning: \(complexTagConfig) returned \(complexTagResult.count), expected \(complexTagParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexTagResult,
            scenario: complexTagConfig.description,
            indexed: indexed,
            queryCondition: complexTagConfig.queryCondition
        ))

        // [TM-38d] Full-Text + Tag Search
        print("[Progress] 80% - Running Full-Text + Tag Search...")
        let fullTextTagConfig = SearchTestConfig.fullTextTagSearch
        let fullTextTagParams = fullTextTagConfig.queryParams
        let fullTextTagResult = try benchmark.measure {
            try searcher.fullTextWithTagSearch(
                keyword: fullTextTagParams.keyword!,
                tag: fullTextTagParams.tag!
            )
        }
        if !fullTextTagParams.expectedCount.validate(fullTextTagResult.count) {
            print("⚠️ Warning: \(fullTextTagConfig) returned \(fullTextTagResult.count), expected \(fullTextTagParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextTagResult,
            scenario: fullTextTagConfig.description,
            indexed: indexed,
            queryCondition: fullTextTagConfig.queryCondition
        ))

        // [TM-38e] Multiple Tags Search
        print("[Progress] 100% - Running Multiple Tags Search...")
        let multiTagsConfig = SearchTestConfig.multipleTagsSearch
        let multiTagsParams = multiTagsConfig.queryParams
        let multipleTagsResult = try benchmark.measure {
            try searcher.searchByMultipleTags(multiTagsParams.tags!)
        }
        if !multiTagsParams.expectedCount.validate(multipleTagsResult.count) {
            print("⚠️ Warning: \(multiTagsConfig) returned \(multipleTagsResult.count), expected \(multiTagsParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            multipleTagsResult,
            scenario: multiTagsConfig.description,
            indexed: indexed,
            queryCondition: multiTagsConfig.queryCondition
        ))

        return results
    }

    // MARK: - Relational Search (CoreData)

    /// CoreData 관계형 검색 시나리오 실행
    func runCoreDataRelational(searcher: CoreDataRelationalSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // [TM-38a] Tag Equality Search
        print("[Progress] 20% - Running Tag Equality Search...")
        let tagEqConfig = SearchTestConfig.tagEqualitySearch
        let tagEqParams = tagEqConfig.queryParams
        let tagEqualityResult = try benchmark.measure {
            try searcher.searchByTag(tagEqParams.tag!, indexed: indexed)
        }
        if !tagEqParams.expectedCount.validate(tagEqualityResult.count) {
            print("⚠️ Warning: \(tagEqConfig) returned \(tagEqualityResult.count), expected \(tagEqParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            tagEqualityResult,
            scenario: tagEqConfig.description,
            indexed: indexed,
            queryCondition: tagEqConfig.queryCondition
        ))

        // [TM-38b] Range + Tag Search
        print("[Progress] 40% - Running Range + Tag Search...")
        let rangeTagConfig = SearchTestConfig.rangeTagSearch
        let rangeTagParams = rangeTagConfig.queryParams
        let rangeTagResult = try benchmark.measure {
            try searcher.rangeWithTagSearch(
                priceMin: rangeTagParams.priceMin!,
                priceMax: rangeTagParams.priceMax!,
                tag: rangeTagParams.tag!
            )
        }
        if !rangeTagParams.expectedCount.validate(rangeTagResult.count) {
            print("⚠️ Warning: \(rangeTagConfig) returned \(rangeTagResult.count), expected \(rangeTagParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeTagResult,
            scenario: rangeTagConfig.description,
            indexed: indexed,
            queryCondition: rangeTagConfig.queryCondition
        ))

        // [TM-38c] Complex + Tag Search
        print("[Progress] 60% - Running Complex + Tag Search...")
        let complexTagConfig = SearchTestConfig.complexTagSearch
        let complexTagParams = complexTagConfig.queryParams
        let complexTagResult = try benchmark.measure {
            try searcher.complexWithTagSearch(
                category: complexTagParams.category!,
                priceMin: complexTagParams.priceMin!,
                priceMax: complexTagParams.priceMax!,
                dateFrom: complexTagParams.dateFrom!,
                tag: complexTagParams.tag!
            )
        }
        if !complexTagParams.expectedCount.validate(complexTagResult.count) {
            print("⚠️ Warning: \(complexTagConfig) returned \(complexTagResult.count), expected \(complexTagParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexTagResult,
            scenario: complexTagConfig.description,
            indexed: indexed,
            queryCondition: complexTagConfig.queryCondition
        ))

        // [TM-38d] Full-Text + Tag Search
        print("[Progress] 80% - Running Full-Text + Tag Search...")
        let fullTextTagConfig = SearchTestConfig.fullTextTagSearch
        let fullTextTagParams = fullTextTagConfig.queryParams
        let fullTextTagResult = try benchmark.measure {
            try searcher.fullTextWithTagSearch(
                keyword: fullTextTagParams.keyword!,
                tag: fullTextTagParams.tag!
            )
        }
        if !fullTextTagParams.expectedCount.validate(fullTextTagResult.count) {
            print("⚠️ Warning: \(fullTextTagConfig) returned \(fullTextTagResult.count), expected \(fullTextTagParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextTagResult,
            scenario: fullTextTagConfig.description,
            indexed: indexed,
            queryCondition: fullTextTagConfig.queryCondition
        ))

        // [TM-38e] Multiple Tags Search
        print("[Progress] 100% - Running Multiple Tags Search...")
        let multiTagsConfig = SearchTestConfig.multipleTagsSearch
        let multiTagsParams = multiTagsConfig.queryParams
        let multipleTagsResult = try benchmark.measure {
            try searcher.searchByMultipleTags(multiTagsParams.tags!)
        }
        if !multiTagsParams.expectedCount.validate(multipleTagsResult.count) {
            print("⚠️ Warning: \(multiTagsConfig) returned \(multipleTagsResult.count), expected \(multiTagsParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            multipleTagsResult,
            scenario: multiTagsConfig.description,
            indexed: indexed,
            queryCondition: multiTagsConfig.queryCondition
        ))

        return results
    }

    // MARK: - Relational Search (SwiftData)

    /// SwiftData 관계형 검색 시나리오 실행
    func runSwiftDataRelational(searcher: SwiftDataRelationalSearcher, indexed: Bool = true) async throws -> [SearchBenchmarkResult] {
        var results: [SearchBenchmarkResult] = []

        // [TM-38a] Tag Equality Search
        print("[Progress] 20% - Running Tag Equality Search...")
        let tagEqConfig = SearchTestConfig.tagEqualitySearch
        let tagEqParams = tagEqConfig.queryParams
        let tagEqualityResult = try benchmark.measure {
            try searcher.searchByTag(tagEqParams.tag!, indexed: indexed)
        }
        if !tagEqParams.expectedCount.validate(tagEqualityResult.count) {
            print("⚠️ Warning: \(tagEqConfig) returned \(tagEqualityResult.count), expected \(tagEqParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            tagEqualityResult,
            scenario: tagEqConfig.description,
            indexed: indexed,
            queryCondition: tagEqConfig.queryCondition
        ))

        // [TM-38b] Range + Tag Search
        print("[Progress] 40% - Running Range + Tag Search...")
        let rangeTagConfig = SearchTestConfig.rangeTagSearch
        let rangeTagParams = rangeTagConfig.queryParams
        let rangeTagResult = try benchmark.measure {
            try searcher.rangeWithTagSearch(
                priceMin: rangeTagParams.priceMin!,
                priceMax: rangeTagParams.priceMax!,
                tag: rangeTagParams.tag!
            )
        }
        if !rangeTagParams.expectedCount.validate(rangeTagResult.count) {
            print("⚠️ Warning: \(rangeTagConfig) returned \(rangeTagResult.count), expected \(rangeTagParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            rangeTagResult,
            scenario: rangeTagConfig.description,
            indexed: indexed,
            queryCondition: rangeTagConfig.queryCondition
        ))

        // [TM-38c] Complex + Tag Search
        print("[Progress] 60% - Running Complex + Tag Search...")
        let complexTagConfig = SearchTestConfig.complexTagSearch
        let complexTagParams = complexTagConfig.queryParams
        let complexTagResult = try benchmark.measure {
            try searcher.complexWithTagSearch(
                category: complexTagParams.category!,
                priceMin: complexTagParams.priceMin!,
                priceMax: complexTagParams.priceMax!,
                dateFrom: complexTagParams.dateFrom!,
                tag: complexTagParams.tag!
            )
        }
        if !complexTagParams.expectedCount.validate(complexTagResult.count) {
            print("⚠️ Warning: \(complexTagConfig) returned \(complexTagResult.count), expected \(complexTagParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            complexTagResult,
            scenario: complexTagConfig.description,
            indexed: indexed,
            queryCondition: complexTagConfig.queryCondition
        ))

        // [TM-38d] Full-Text + Tag Search
        print("[Progress] 80% - Running Full-Text + Tag Search...")
        let fullTextTagConfig = SearchTestConfig.fullTextTagSearch
        let fullTextTagParams = fullTextTagConfig.queryParams
        let fullTextTagResult = try benchmark.measure {
            try searcher.fullTextWithTagSearch(
                keyword: fullTextTagParams.keyword!,
                tag: fullTextTagParams.tag!
            )
        }
        if !fullTextTagParams.expectedCount.validate(fullTextTagResult.count) {
            print("⚠️ Warning: \(fullTextTagConfig) returned \(fullTextTagResult.count), expected \(fullTextTagParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            fullTextTagResult,
            scenario: fullTextTagConfig.description,
            indexed: indexed,
            queryCondition: fullTextTagConfig.queryCondition
        ))

        // [TM-38e] Multiple Tags Search
        print("[Progress] 100% - Running Multiple Tags Search...")
        let multiTagsConfig = SearchTestConfig.multipleTagsSearch
        let multiTagsParams = multiTagsConfig.queryParams
        let multipleTagsResult = try benchmark.measure {
            try searcher.searchByMultipleTags(multiTagsParams.tags!)
        }
        if !multiTagsParams.expectedCount.validate(multipleTagsResult.count) {
            print("⚠️ Warning: \(multiTagsConfig) returned \(multipleTagsResult.count), expected \(multiTagsParams.expectedCount)")
        }
        results.append(SearchBenchmark.toBenchmarkResult(
            multipleTagsResult,
            scenario: multiTagsConfig.description,
            indexed: indexed,
            queryCondition: multiTagsConfig.queryCondition
        ))

        return results
    }
}
