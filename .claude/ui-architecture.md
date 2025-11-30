# UI Architecture

## UI-01: 개요

DBPerformanceTests는 MVVM 패턴 기반 SwiftUI 아키텍처를 사용하여 벤치마크 실행 및 결과 비교 UI를 제공함.

### 주요 구조
- **TabView 아키텍처**: Benchmarks 탭과 Comparison 탭으로 분리
- **MVVM 패턴**: Model-View-ViewModel 분리로 테스트 가능성과 유지보수성 확보
- **파일 기반 결과 로딩**: 1-4개 JSON 파일 선택 및 비교
- **선언적 UI**: SwiftUI 컴포넌트 조합 (composition over inheritance)

### 관련 코딩 규칙
- [CR-44~51]: UI 레이아웃 요구사항
- [CR-52~55]: Swift 6.0 Concurrency 규칙
- [CR-56]: MVVM 패턴 요구사항 (아래 참조)

---

## UI-02: 컴포넌트 계층 구조

### Comparison Tab 구조

```
ResultsComparisonView (root)
├── HSplitView
│   ├── Sidebar (250pt 고정)
│   │   └── FileSelectionView
│   │       ├── List (checkboxes)
│   │       └── Button ("Compare")
│   │
│   └── Content Area
│       ├── Loading State → ProgressView
│       ├── Error State → Text + error message
│       ├── Empty State → Text ("Select files...")
│       └── Data Display State
│           ├── PerformanceChartView
│           ├── PerformanceRankingView
│           └── MetadataComparisonView
```

### 레이아웃 규칙
- **HSplitView**: [CR-45] 참조 - 250pt 사이드바 고정 너비
- **조건부 렌더링**: ViewModel의 상태에 따라 View 전환
- **스크롤 영역**: 메인 콘텐츠는 ScrollView로 감싸 세로 스크롤 지원

---

## UI-03: ViewModels

### ResultsComparisonViewModel

**위치**: `DBPerformanceTests/Sources/ViewModels/ResultsComparisonViewModel.swift`

**역할**: 파일 검색, 로딩, 비교 데이터 집계 및 상태 관리

**주요 속성**:
```swift
@MainActor
class ResultsComparisonViewModel: ObservableObject {
    @Published var availableFiles: [SearchBenchmarkFile]  // 선택 가능한 파일 목록
    @Published var selectedFileIDs: Set<String>            // 선택된 파일 ID
    @Published var comparisonData: ComparisonData?         // 비교 결과 데이터
    @Published var isLoading: Bool                         // 로딩 상태
    @Published var errorMessage: String?                   // 에러 메시지
}
```

**주요 메서드**:
- `loadAvailableFiles()`: Results 디렉토리에서 `*-search.json` 파일 검색
- `compareSelectedFiles()`: 선택된 1-4개 파일 로딩 및 ComparisonData 생성
- `toggleFileSelection(_ id: String)`: 파일 선택/해제 토글

**동시성 규칙**: [CR-56] 준수
- `@MainActor` 격리: 모든 UI 업데이트가 메인 스레드에서 실행
- `ObservableObject` 프로토콜 구현
- `@Published` 프로퍼티로 View 자동 업데이트

**파일 관리 위임**: `ResultsFileManager` 사용 (UI-06 참조)

---

## UI-04: View 컴포넌트

### UI-04a: FileSelectionView

**위치**: `DBPerformanceTests/Sources/Views/Components/FileSelectionView.swift`

**역할**: 사이드바에서 파일 선택 UI 제공

**구성**:
- **List with Checkboxes**: 각 SearchBenchmarkFile을 체크박스 행으로 표시
  - Timestamp (ISO 8601)
  - Database Name (Realm, CoreData, SwiftData, UserDefaults)
  - 파일명 표시
- **Selection Logic**: 1-4개 파일만 선택 가능 (초과 시 비활성화)
- **Compare Button**: 선택된 파일이 1개 이상일 때 활성화
  - 클릭 시 `ViewModel.compareSelectedFiles()` 호출

**검증 규칙**: [TM-43] 참조
- 최소 1개 파일 필요
- 최대 4개 파일 제한 (차트 가독성 유지)

---

### UI-04b: PerformanceChartView

**위치**: `DBPerformanceTests/Sources/Views/Components/PerformanceChartView.swift`

**역할**: 시나리오별 응답시간을 막대 그래프로 시각화

**구성**:
- **SwiftUI Charts 프레임워크** 사용
- **4가지 시나리오별 차트** (Flat 검색):
  - Equality 검색 응답시간
  - Range 검색 응답시간
  - Complex 검색 응답시간
  - Full-Text 검색 응답시간
- **데이터베이스별 색상 구분**: [CR-51] 참조
  - Realm: Blue (#0066CC)
  - CoreData: Green (#34C759)
  - SwiftData: Orange (#FF9500)
  - UserDefaults: Purple (#AF52DE)
- **Bar Chart 스타일**:
  - X축: 데이터베이스 이름
  - Y축: 응답 시간 (ms)
  - 범례: 자동 생성

**데이터 소스**: `ComparisonData.chartData` (UI-05 참조)

---

### UI-04c: PerformanceRankingView

**위치**: `DBPerformanceTests/Sources/Views/Components/PerformanceRankingView.swift`

**역할**: 각 시나리오별 Top 3 순위 표시

**구성**:
- **시나리오별 섹션**: Equality, Range, Complex, Full-Text
- **순위 표시** (각 시나리오당):
  - 🥇 **1st Place**: 가장 빠른 응답시간 (Gold)
  - 🥈 **2nd Place**: 두 번째 응답시간 (Silver)
  - 🥉 **3rd Place**: 세 번째 응답시간 (Bronze)
- **표시 정보**:
  - 데이터베이스 이름
  - 응답시간 (ms)
  - 결과 개수

**순위 계산**: [TM-45] 참조
- 응답시간 오름차순 정렬 (낮을수록 좋음)
- 동일 시간은 데이터베이스 이름 알파벳 순

**데이터 소스**: `ComparisonData.rankings` (UI-05 참조)

---

### UI-04d: MetadataComparisonView

**위치**: `DBPerformanceTests/Sources/Views/Components/MetadataComparisonView.swift`

**역할**: 테스트 환경 메타데이터를 그리드로 비교

**구성**:
- **Grid Layout**: 각 파일별 환경 정보를 열로 표시
- **표시 항목** ([TM-46] 참조):
  - **테스트 일시**: ISO 8601 타임스탬프
  - **Hardware 정보**:
    - CPU 모델명
    - CPU 코어 수
    - RAM 용량 (GB)
    - 디스크 타입 (SSD/HDD)
  - **Software 정보**:
    - macOS 버전
    - Swift 버전
    - Xcode 버전
    - 데이터베이스 프레임워크 버전
  - **System Resource 상태**:
    - CPU 사용률 (%)
    - 메모리 사용률 (%)
    - 디스크 여유 공간 (GB)

**목적**: 테스트 환경 차이를 고려한 공정한 비교

**데이터 소스**: `SearchBenchmarkReport.environment` ([ENV-XX] 참조)

---

## UI-05: 데이터 모델 (ComparisonModels.swift)

**위치**: `DBPerformanceTests/Sources/Models/ComparisonModels.swift`

### Scenario (enum)
```swift
enum Scenario: String, CaseIterable {
    case equality = "Equality"
    case range = "Range"
    case complex = "Complex"
    case fullText = "Full-Text"
}
```

### SearchBenchmarkFile
```swift
struct SearchBenchmarkFile: Identifiable {
    let id: String                 // 파일명 기반 고유 ID
    let filename: String            // "2025-11-30T14:30:00Z-Realm-search.json"
    let timestamp: Date             // 파일명에서 파싱한 타임스탬프
    let databaseName: String        // "Realm", "CoreData", "SwiftData", "UserDefaults"
}
```
- **파싱 로직**: `ResultsFileManager.parseFilename()` (UI-06 참조)
- **파일명 형식**: [TM-28] 참조

### ChartDataPoint
```swift
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let database: String            // 데이터베이스 이름
    let scenario: Scenario          // 검색 시나리오
    let responseTime: Double        // 응답 시간 (ms)
    let resultCount: Int            // 검색 결과 개수
}
```
- **용도**: PerformanceChartView 렌더링 데이터 (UI-04b)

### RankingEntry
```swift
struct RankingEntry: Identifiable {
    let id = UUID()
    let rank: Int                   // 1, 2, 3
    let database: String
    let responseTime: Double
    let resultCount: Int
}
```
- **용도**: PerformanceRankingView Top 3 표시 (UI-04c)

### ComparisonData
```swift
struct ComparisonData {
    let reports: [SearchBenchmarkReport]     // 로딩된 벤치마크 보고서
    let chartData: [ChartDataPoint]          // 차트 렌더링용 데이터
    let rankings: [Scenario: [RankingEntry]] // 시나리오별 Top 3 순위

    init(reports: [SearchBenchmarkReport]) {
        self.reports = reports
        self.chartData = Self.calculateChartData(from: reports)
        self.rankings = Self.calculateRankings(from: reports)
    }
}
```
- **집계 로직**:
  - `calculateChartData()`: 각 보고서에서 시나리오별 응답시간 추출
  - `calculateRankings()`: 시나리오별 응답시간 정렬 후 Top 3 선택

### DatabaseColor
```swift
struct DatabaseColor {
    static func color(for database: String) -> Color {
        switch database {
        case "Realm": return .blue         // #0066CC
        case "CoreData": return .green     // #34C759
        case "SwiftData": return .orange   // #FF9500
        case "UserDefaults": return .purple // #AF52DE
        default: return .gray
        }
    }
}
```
- **색상 규칙**: [CR-51] 준수

---

## UI-06: 파일 관리 (ResultsFileManager.swift)

**위치**: `DBPerformanceTests/Sources/Utilities/ResultsFileManager.swift`

**역할**: Results 디렉토리에서 벤치마크 결과 파일 검색 및 로딩

### 주요 메서드

#### `discoverFiles() -> [SearchBenchmarkFile]`
- **동작**: Results 디렉토리에서 `*-search.json` 패턴 파일 검색
- **반환**: 파일명 파싱 후 `SearchBenchmarkFile` 배열
- **정렬**: 타임스탬프 역순 (최신 파일 먼저)

#### `parseFilename(_ filename: String) -> (timestamp: Date, databaseName: String)?`
- **입력**: "2025-11-30T14:30:00Z-Realm-search.json"
- **출력**: `(Date(2025-11-30 14:30:00 UTC), "Realm")`
- **파싱 규칙**: [TM-28] 파일명 형식 준수
  - ISO 8601 타임스탬프 파싱 (YYYY-MM-DDTHH:MM:SSZ)
  - DatabaseName 추출 (타임스탬프와 `-search.json` 사이)

#### `loadReport(filename: String) throws -> SearchBenchmarkReport`
- **동작**: JSON 파일 디코딩하여 `SearchBenchmarkReport` 객체 생성
- **에러 처리**:
  - 파일 없음: `FileNotFoundError`
  - JSON 파싱 실패: `DecodingError`
  - 잘못된 형식: `InvalidFormatError`

### 의존성
- **파일 위치**: `{ProjectRoot}/Results/` ([TM-27] 참조)
- **JSON 스키마**: `SearchBenchmarkReport` 구조 ([TM-29] 참조)

---

## UI-07: 상태 플로우 (State Flow)

### 초기 상태
1. 앱 실행 → `ResultsComparisonView` 렌더링
2. `ResultsComparisonViewModel.loadAvailableFiles()` 호출
3. `ResultsFileManager.discoverFiles()` → 파일 목록 로딩
4. `availableFiles` 업데이트 → `FileSelectionView` 렌더링

### 파일 선택 플로우
1. 사용자가 체크박스 클릭 (1-4개)
2. `ViewModel.toggleFileSelection(_ id:)` 호출
3. `selectedFileIDs` 업데이트
4. "Compare" 버튼 활성화 (selectedFileIDs.count >= 1)

### 비교 실행 플로우
1. 사용자가 "Compare" 버튼 클릭
2. `ViewModel.compareSelectedFiles()` 호출
3. **로딩 상태**: `isLoading = true` → ProgressView 표시
4. **파일 로딩**:
   - 각 선택된 파일에 대해 `ResultsFileManager.loadReport()` 호출
   - 에러 발생 시 → `errorMessage` 설정 → Error State 표시
5. **데이터 집계**:
   - `ComparisonData(reports:)` 생성
   - `chartData` 및 `rankings` 계산
6. **완료 상태**: `isLoading = false`, `comparisonData` 설정
7. **UI 렌더링**:
   - PerformanceChartView 표시
   - PerformanceRankingView 표시
   - MetadataComparisonView 표시

### 에러 처리 플로우
- 파일 로딩 실패 → `errorMessage = "Failed to load: {filename}"`
- JSON 파싱 오류 → `errorMessage = "Invalid format: {details}"`
- 에러 상태 → 메인 콘텐츠 영역에 에러 메시지 표시
- 사용자는 다른 파일 선택하여 재시도 가능

---

## UI-08: Concurrency 및 성능 최적화

### @MainActor 격리
- **ViewModel**: `@MainActor class ResultsComparisonViewModel` ([CR-52] 준수)
- **모든 UI 업데이트**: 자동으로 메인 스레드에서 실행
- **Swift 6.0 엄격 모드**: 컴파일 타임에 데이터 레이스 방지

### Sendable 프로토콜
- **ComparisonData**: `Sendable` 준수 ([CR-53])
- **SearchBenchmarkFile**: `Sendable` 준수
- **스레드 안전성**: 불변 데이터 구조 사용

### 성능 고려사항
- **파일 로딩**: 비동기 작업이지만 파일 크기가 작아 빠름 (JSON ~1-5MB)
- **차트 렌더링**: SwiftUI Charts의 자동 최적화 사용
- **메모리 관리**: 최대 4개 보고서만 메모리에 유지 (제한적)

---

## UI-09: 테스트 가능성

### ViewModel 단위 테스트
- **Mock ResultsFileManager** 주입 가능
- **상태 변화 검증**:
  ```swift
  func testCompareFiles() async {
      let viewModel = ResultsComparisonViewModel(fileManager: MockFileManager())
      await viewModel.compareSelectedFiles()
      XCTAssertNotNil(viewModel.comparisonData)
  }
  ```

### View 프리뷰
- **SwiftUI Previews** 지원:
  ```swift
  #Preview {
      ResultsComparisonView(viewModel: ResultsComparisonViewModel())
  }
  ```
- **Mock 데이터** 사용하여 다양한 상태 프리뷰 가능

---

## UI-10: 확장성

### 향후 추가 가능한 기능
- **Relational Search 결과 비교**: [TM-36~40] 시나리오 추가
- **Export 기능**: 비교 결과를 PDF/CSV로 내보내기
- **필터링**: 특정 시나리오만 차트에 표시
- **다크 모드**: 시스템 테마 자동 추종

### 아키텍처 확장 포인트
- **새 ViewModel**: 다른 비교 타입 (예: Loading Performance Comparison)
- **새 View 컴포넌트**: 모듈화된 구조로 쉽게 추가 가능
- **데이터 모델 확장**: `ComparisonData` 계산 로직만 수정

---

## 관련 문서 참조

- **코딩 규칙**: [CR-44~51] UI 레이아웃, [CR-52~55] Concurrency, [CR-56] MVVM 패턴
- **테스팅 방법론**: [TM-28] 파일명 형식, [TM-43~46] 결과 비교 방법론
- **성능 메트릭**: [PM-05~08] Flat 검색 메트릭, [PM-25~29] Relational 메트릭
- **환경 정보**: [ENV-XX] 시스템 환경 수집 규칙
