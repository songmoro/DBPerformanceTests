//
//  FileSelectionView.swift
//  DBPerformanceTests
//
//  파일 선택 UI 컴포넌트
//  [CR-13] Sources/Views: UI 컴포넌트
//  [CR-45] Comparison 탭: HSplitView (Sidebar 250pt + Main Content)
//

import SwiftUI

/// 파일 선택 사이드바 View
/// [CR-46] 파일 선택: Results 디렉토리에서 *-search.json 파일만 필터링
struct FileSelectionView: View {
    @Binding var availableFiles: [SearchBenchmarkFile]
    @Binding var selectedURLs: Set<URL>
    let onCompare: () -> Void
    let isCompareEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Select Results")
                .font(.headline)
                .padding(.top)

            if availableFiles.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("No results found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Run search benchmarks first")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(availableFiles, id: \.id) { file in
                        Toggle(isOn: binding(for: file.url)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.databaseName)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(formatDate(file.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                }
                .listStyle(.sidebar)

                Divider()

                VStack(spacing: 8) {
                    Text("\(selectedURLs.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Compare Selected") {
                        onCompare()
                    }
                    .disabled(!isCompareEnabled)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .frame(width: 250)
    }

    // MARK: - Helper Methods

    private func binding(for url: URL) -> Binding<Bool> {
        Binding(
            get: { selectedURLs.contains(url) },
            set: { isSelected in
                if isSelected {
                    selectedURLs.insert(url)
                } else {
                    selectedURLs.remove(url)
                }
            }
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
