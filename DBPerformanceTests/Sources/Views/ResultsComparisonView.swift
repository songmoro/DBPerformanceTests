//
//  ResultsComparisonView.swift
//  DBPerformanceTests
//
//  결과 비교 메인 화면
//  [CR-44] TabView 구조: Benchmarks 탭 + Comparison 탭
//  [CR-45] Comparison 탭: HSplitView (Sidebar 250pt + Main Content)
//

import SwiftUI

/// 결과 비교 메인 View
@MainActor
struct ResultsComparisonView: View {
    @StateObject private var viewModel = ResultsComparisonViewModel()

    var body: some View {
        HSplitView {
            // Sidebar: 파일 선택
            FileSelectionView(
                availableFiles: $viewModel.availableFiles,
                selectedURLs: $viewModel.selectedFileURLs,
                onCompare: viewModel.loadComparisonData,
                isCompareEnabled: viewModel.isCompareButtonEnabled
            )

            // Main Content
            mainContent
        }
        .frame(minWidth: 1000, minHeight: 700)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            // 로딩 상태
            VStack(spacing: 15) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
            // 에러 상태
            VStack(spacing: 15) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)

                Text("Error")
                    .font(.headline)

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Try Again") {
                    viewModel.loadComparisonData()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let comparisonData = viewModel.comparisonData {
            // 비교 데이터 표시
            ScrollView {
                VStack(spacing: 40) {
                    PerformanceChartView(comparisonData: comparisonData)

                    Divider()

                    PerformanceRankingView(comparisonData: comparisonData)

                    Divider()

                    MetadataComparisonView(comparisonData: comparisonData)
                }
                .padding()
            }
        } else {
            // 빈 상태
            VStack(spacing: 15) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)

                Text("No Comparison Data")
                    .font(.headline)

                Text("Select files from the sidebar to compare results")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ResultsComparisonView()
}
