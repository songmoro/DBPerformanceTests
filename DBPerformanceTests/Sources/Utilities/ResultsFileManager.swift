//
//  ResultsFileManager.swift
//  DBPerformanceTests
//
//  결과 파일 관리 유틸리티
//  [CR-15] Sources/Utilities: 유틸리티 클래스
//

import Foundation

/// 결과 파일 관리자
/// [CR-46] 파일 선택: Results 디렉토리에서 *-search.json 파일만 필터링
struct ResultsFileManager: Sendable {
    private let resultsDirectory: URL

    init() {
        let projectDir = FileManager.default.currentDirectoryPath
        self.resultsDirectory = URL(fileURLWithPath: "\(projectDir)/Results")
    }

    /// 검색 벤치마크 파일 목록 조회
    /// [TM-37] 파일 선택: Results 디렉토리에서 *-search.json 파일 수동 선택
    func listSearchBenchmarkFiles() throws -> [SearchBenchmarkFile] {
        let fileManager = FileManager.default

        // Results 디렉토리가 없으면 빈 배열 반환
        guard fileManager.fileExists(atPath: resultsDirectory.path) else {
            return []
        }

        let files = try fileManager.contentsOfDirectory(
            at: resultsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )

        // *-search.json 필터링
        return files
            .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasSuffix("-search.json") }
            .map { url in
                SearchBenchmarkFile(
                    url: url,
                    filename: url.lastPathComponent,
                    timestamp: parseTimestamp(from: url.lastPathComponent),
                    databaseName: parseDatabaseName(from: url.lastPathComponent)
                )
            }
            .sorted { $0.timestamp > $1.timestamp } // 최신순 정렬
    }

    /// 파일명에서 타임스탬프 파싱
    /// 형식: "2025-11-30T10:00:00Z-DatabaseName-search.json"
    private func parseTimestamp(from filename: String) -> Date {
        // ISO8601 포맷: YYYY-MM-DDTHH:MM:SSZ
        // 예: 2025-11-30T10:00:00Z
        if let _ = filename.firstIndex(of: "T"),
           let zIndex = filename.firstIndex(of: "Z") {
            let timestampString = String(filename[..<filename.index(after: zIndex)])
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: timestampString) {
                return date
            }
        }

        return Date()
    }

    /// 파일명에서 DB명 파싱
    /// 형식: "2025-11-30T10:00:00Z-DatabaseName-search.json"
    private func parseDatabaseName(from filename: String) -> String {
        // "Z-" 다음부터 "-search.json" 전까지가 DB명
        if let zRange = filename.range(of: "Z-"),
           let searchRange = filename.range(of: "-search.json") {
            let startIndex = zRange.upperBound
            let endIndex = searchRange.lowerBound
            return String(filename[startIndex..<endIndex])
        }

        return "Unknown"
    }

    /// JSON 파일 로드
    /// [CR-43] ContinuousClock 사용하여 측정
    func loadReport(from url: URL) throws -> SearchBenchmarkReport {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SearchBenchmarkReport.self, from: data)
    }
}
