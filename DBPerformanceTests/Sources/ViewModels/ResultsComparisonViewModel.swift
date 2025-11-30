//
//  ResultsComparisonViewModel.swift
//  DBPerformanceTests
//
//  결과 비교 화면 ViewModel
//  [CR-14] Sources/ViewModels: UI 비즈니스 로직
//  [CR-54] @MainActor로 UI 관련 ViewModel 격리
//

import Foundation
import SwiftUI
import Combine

/// 결과 비교 ViewModel
/// [CR-54] @MainActor로 UI 관련 ViewModel 격리
@MainActor
final class ResultsComparisonViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var availableFiles: [SearchBenchmarkFile] = []
    @Published var selectedFileURLs: Set<URL> = []
    @Published var comparisonData: ComparisonData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let fileManager = ResultsFileManager()

    // MARK: - Initialization

    init() {
        loadAvailableFiles()
    }

    // MARK: - Public Methods

    /// 파일 목록 로드
    /// [TM-37] 파일 선택: Results 디렉토리에서 *-search.json 파일 수동 선택
    func loadAvailableFiles() {
        do {
            availableFiles = try fileManager.listSearchBenchmarkFiles()
        } catch {
            errorMessage = "Failed to load files: \(error.localizedDescription)"
        }
    }

    /// 선택된 파일들을 비교 데이터로 변환
    /// [TM-38] 선택 제한: 최소 1개, 최대 4개 파일 (차트 가독성 유지)
    func loadComparisonData() {
        guard !selectedFileURLs.isEmpty else {
            errorMessage = "Please select at least one file"
            return
        }

        guard selectedFileURLs.count <= 4 else {
            errorMessage = "Please select up to 4 files"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                var reports: [SearchBenchmarkReport] = []

                for url in selectedFileURLs {
                    let report = try fileManager.loadReport(from: url)
                    reports.append(report)
                }

                comparisonData = ComparisonData(reports: reports)
                isLoading = false
            } catch {
                errorMessage = "Failed to load reports: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    /// 파일 선택 토글
    func toggleFileSelection(_ fileURL: URL) {
        if selectedFileURLs.contains(fileURL) {
            selectedFileURLs.remove(fileURL)
        } else {
            selectedFileURLs.insert(fileURL)
        }
    }

    /// 비교 버튼 활성화 여부
    /// [CR-47] 선택 제한: 최소 1개, 최대 4개 파일 선택 가능
    var isCompareButtonEnabled: Bool {
        !selectedFileURLs.isEmpty && selectedFileURLs.count <= 4
    }
}
