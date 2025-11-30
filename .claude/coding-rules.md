# Coding Rules

## 개발 환경

[CR-01] Swift 6.0 기준으로 개발
[CR-02] Xcode 16.0 이상 사용
[CR-03] macOS 15.0 (Sequoia) 이상 지원
[CR-04] 프로젝트 타입: macOS App

## 프로젝트 구조

[CR-05] 폴더 계층이 내려갈수록 구체화되는 구조 유지
[CR-06] 네이밍 규칙은 Swift 표준 컨벤션 따르되 엄격히 강제하지 않음

## 디렉토리 구조

[CR-07] Sources/Core: 공통 인터페이스 및 프로토콜
[CR-08] Sources/Databases: 각 DB별 구현체 (Realm, CoreData, SwiftData, UserDefaults)
[CR-09] Sources/Benchmarks: 벤치마크 실행 엔진
[CR-10] Sources/Models: 테스트 데이터 모델 및 비교 UI 모델
[CR-11] Sources/Fixtures: 100K 및 1M 레코드 fixture 파일 저장 위치 (JSON)
[CR-12] Results/: JSON 결과 파일 저장 폴더
[CR-13] Sources/Views: UI 컴포넌트 (ResultsComparisonView 및 하위 컴포넌트)
[CR-14] Sources/ViewModels: UI 비즈니스 로직 (ResultsComparisonViewModel)
[CR-15] Sources/Utilities: 유틸리티 클래스 (ResultsFileManager 등)

## 검색 인터페이스 설계

[CR-16] SearchQuery 프로토콜 정의로 통일된 검색 인터페이스 제공
[CR-17] 4가지 검색 타입 지원: Equality, Range, Complex, FullText
[CR-18] 검색 결과 반환 시 결과 개수와 응답 시간을 함께 측정
[CR-19] 인덱스 정보 명시 (indexed: Bool)

## 테스트 데이터 스키마

[CR-20] 검색 최적화 모델: 검색용 필드 포함 (id, name, category, price, date, description)
[CR-21] 인덱스 전략: name, category 필드에 인덱스 적용; price는 범위 검색용
[CR-22] Full-Text 검색용 description 필드 (긴 텍스트)
[CR-23] 모든 데이터는 고유 식별자(ID) 보유

## Fixture 파일 로딩

[CR-24] Fixture 파일 위치: Sources/Fixtures/
[CR-25] JSON 포맷 지원 (flat-100k.json, flat-1m.json, relational-100k.json, relational-1m.json)
[CR-26] 100K 또는 1M 레코드 일괄 로딩 메커니즘 (스트리밍 없음)
[CR-27] 로딩 시간 측정 (파일 읽기 + 파싱 + DB 저장) - [TM-06] 참조
[CR-28] Fixture 상세 규칙은 [CR-60~65] 참조

## 데이터베이스 인덱스 요구사항

[CR-29] 모든 DB는 인덱스 정의 가능해야 함 (indexed vs non-indexed 비교 필수)
[CR-30] 인덱스 적용 필드와 미적용 필드를 명시적으로 구분

## 비교 대상 데이터베이스

[CR-31] Realm
[CR-32] CoreData
[CR-33] SwiftData
[CR-34] UserDefaults

## 데이터셋 스키마

[CR-35] FlatModel 필드 정의: id, name(Indexed), category(Indexed), price, date, description, isActive
[CR-36] RelationalModel: ProductRecord + Tag 1:N 관계
[CR-37] Zipf 분포 파라미터: name(s=1.3, k=100), category(s=1.5, k=50)
[CR-38] Fixture 파일 위치: Sources/Fixtures/ (flat-100k.json, realm_100k.realm, etc.)
[CR-39] Fixture 로딩: 사전 생성된 DB 파일 사용 (검색 시 로딩 불필요)
[CR-40] 인덱스 적용 필드: name, category만
[CR-41] 구체 타입 사용: 프로토콜 제거, DB별 독립 Searcher 클래스
[CR-42] 검색 결과 반환: SearchResult(results, count, responseTimeMs)
[CR-43] ContinuousClock 사용하여 검색 시간 측정

## 결과 비교 UI 규칙

[CR-44] TabView 구조: Benchmarks 탭 + Comparison 탭
  - 상세 컴포넌트 계층: [UI-02] 참조
[CR-45] Comparison 탭: HSplitView (Sidebar 250pt + Main Content)
  - ViewModel 패턴: [UI-03] 참조
[CR-46] 파일 선택: Results 디렉토리에서 *-search.json 파일만 필터링
  - FileSelectionView: [UI-04a] 참조
[CR-47] 선택 제한: 최소 1개, 최대 4개 파일 선택 가능 - [TM-43]
[CR-48] 차트: SwiftUI Charts 사용, BarMark로 시나리오별 비교
  - PerformanceChartView: [UI-04b] 참조
[CR-49] 순위 표시: 시나리오별 Top 3 표시 (1st 금🥇, 2nd 은🥈, 3rd 동🥉)
  - PerformanceRankingView: [UI-04c] 참조
[CR-50] 메타데이터 비교: Grid 레이아웃으로 환경 정보 테이블 표시
  - MetadataComparisonView: [UI-04d] 참조
[CR-51] DB별 색상 코드:
  - Realm: Blue (#0066CC)
  - CoreData: Green (#34C759)
  - SwiftData: Orange (#FF9500)
  - UserDefaults: Purple (#AF52DE)

## Swift 6.0 동시성

[CR-52] Swift 6.0 동시성 모델을 명시적으로 준수
[CR-53] unchecked 사용을 최대한 지양하고 안전한 동시성 보장
[CR-54] @MainActor로 UI 관련 ViewModel 격리
[CR-55] Sendable 프로토콜 준수 (모든 데이터 모델)

## MVVM 패턴 요구사항

[CR-56] ViewModel 규칙:
  - `@MainActor` 격리 필수 (모든 ViewModel 클래스)
  - `ObservableObject` 프로토콜 구현
  - `@Published` 프로퍼티로 상태 변화 발행
  - 비즈니스 로직과 상태 관리만 담당 (UI 렌더링 책임 없음)
  - 예시: ResultsComparisonViewModel - [UI-03] 참조

[CR-57] View 규칙:
  - SwiftUI 선언적 문법 사용
  - Composition over Inheritance (컴포넌트 조합)
  - ViewModel에 대한 의존성만 가짐 (직접 데이터 로딩 금지)
  - 상태는 ViewModel의 `@Published` 프로퍼티 관찰
  - 재사용 가능한 작은 컴포넌트로 분리
  - 예시: FileSelectionView, PerformanceChartView - [UI-04a~d] 참조

[CR-58] Model 규칙:
  - `Sendable` 프로토콜 준수 (Swift 6.0 동시성)
  - 불변 데이터 구조 선호 (let 사용)
  - 비즈니스 로직 포함 가능 (계산 메서드)
  - 예시: ComparisonData.calculateRankings() - [UI-05] 참조

[CR-59] 상태 플로우:
  - User Action → View Event → ViewModel Method → Model Update → Published Property → View Re-render
  - 단방향 데이터 흐름 유지
  - 상세 플로우: [UI-07] 참조

## Fixture 파일 표준

[CR-60] Fixture 디렉토리 구조:
  - 위치: `{ProjectRoot}/Sources/Fixtures/`
  - Flat 데이터셋: `flat-100k.json`, `flat-1m.json`
  - Relational 데이터셋: `relational-100k.json`, `relational-1m.json`
  - 참조: [TM-05] Fixture 로딩 방법론

[CR-61] Flat Fixture 스키마:
  - 구조: JSON 배열 (Product 객체들)
  - 필수 필드: `id` (Int), `name` (String), `category` (String), `price` (Decimal), `stockQuantity` (Int), `createdAt` (Date)
  - 인덱스 필드: `name`, `category` (DB별 인덱스 설정)
  - 예시:
    ```json
    [
      {
        "id": 1,
        "name": "Product A",
        "category": "Electronics",
        "price": 99.99,
        "stockQuantity": 50,
        "createdAt": "2024-01-01T00:00:00Z"
      }
    ]
    ```

[CR-62] Relational Fixture 스키마:
  - 구조: JSON 객체 (products 배열 + tags 배열)
  - **ProductRecord**: `id` (Int), `name` (String), `category` (String), `price` (Decimal), `createdAt` (Date)
  - **Tag**: `id` (Int), `name` (String), `productId` (Int) - Foreign Key
  - 관계: `ProductRecord.tags = Tag[]` (1:N)
  - 참조 무결성: 모든 `tag.productId`는 유효한 `product.id` 참조
  - 예시:
    ```json
    {
      "products": [
        { "id": 1, "name": "Laptop", "category": "Electronics", "price": 999.99, "createdAt": "2024-01-01T00:00:00Z" }
      ],
      "tags": [
        { "id": 1, "name": "sale", "productId": 1 },
        { "id": 2, "name": "featured", "productId": 1 }
      ]
    }
    ```
  - 참조: [TM-37] Relational 데이터 모델

[CR-63] 데이터 생성 규칙:
  - **결정적 시딩**: 동일 seed → 동일 데이터 (재현성 보장)
  - **현실적 분포**:
    - Category: Zipf 분포 (상위 카테고리 집중)
    - Price: 로그 정규 분포 (10-10000 범위)
    - CreatedAt: 최근 2년간 균등 분포
  - **Tag Cardinality**: 제품당 0-5개 태그 (평균 2개)
  - **Fixture 생성 도구**: `GenerateFixtures.swift` 사용

[CR-64] Fixture 검증 규칙:
  - **스키마 검증**: 로딩 시 필수 필드 존재 확인
  - **참조 무결성**: Relational fixture에서 tag.productId 유효성 검증
  - **레코드 개수**: 정확히 100,000 또는 1,000,000개 (오차 없음)
  - **중복 ID 검증**: product.id와 tag.id 모두 고유해야 함
  - 검증 실패 시 로딩 중단 및 에러 표시

[CR-65] Fixture 사용 규칙:
  - **로딩 단계**: 데이터베이스 setUp 단계에서 fixture 로딩 ([TM-15] 참조)
  - **불변성**: 벤치마크 실행 중 fixture 데이터 수정 금지
  - **시간 측정 제외**: Fixture 로딩 시간은 검색 성능 측정에서 제외 ([TM-22] 참조)
  - **파일 크기**: flat-100k.json ~80MB, relational-100k.json ~100MB (참고용)

## Search Test Configuration

[CR-70] 검색 테스트 쿼리 파라미터는 `SearchTestConfig` enum에서 중앙 관리
  - **위치**: `DBPerformanceTests/Sources/Benchmarks/SearchTestConfig.swift`
  - **목적**: 하드코딩된 쿼리 값 제거, 단일 진실 공급원(Single Source of Truth)
  - **사용 예시**: `let config = SearchTestConfig.equalitySearch; let params = config.queryParams`
  - **금지**: 검색 시나리오 코드에서 직접 값 하드코딩 (예: `"Product_12345"`)

[CR-71] 모든 검색 쿼리는 실제 데이터 분포(Zipf, Uniform)를 고려한 값 사용
  - **Zipf 분포 값**: `ValueGenerators.productNames`, `ValueGenerators.categories`에서 참조
  - **Uniform 분포 값**: `DatasetConstants.dateRange`, `DatasetConstants.priceRange`에서 참조
  - **Tag 값**: `ValueGenerators.tagNames`에서 인덱스 기반 참조
  - **목적**: 검색 쿼리와 생성된 fixture 데이터 간 일치 보장

[CR-72] 기대 결과 개수는 `QueryParameters.expectedCount`로 검증
  - **ExpectedCount enum**: `.exact(Int)`, `.range(min:max:)`, `.any`
  - **검증 로직**: 검색 실행 후 `expectedCount.validate(actual)` 호출
  - **경고 출력**: 실제 결과가 기대 범위 밖이면 `⚠️ Warning` 출력
  - **목적**: 데이터 생성 버그 조기 발견, 검색 구현 정확성 검증

[CR-73] 하드코딩된 쿼리 값 사용 금지 - 반드시 `SearchTestConfig` 사용
  - **금지 예시**: `try searcher.searchByName("Product_12345")` ❌
  - **권장 예시**: `let params = SearchTestConfig.equalitySearch.queryParams; try searcher.searchByName(params.name!)` ✅
  - **적용 범위**: `SearchScenarios.swift`의 모든 검색 메서드
  - **검증 방법**: 코드 리뷰 시 하드코딩된 문자열/숫자 리터럴 금지

[CR-74] Fixture 생성은 `FixtureGenerationConfig` enum 사용 권장
  - **위치**: `DBPerformanceTests/Sources/Benchmarks/FixtureGenerationConfig.swift`
  - **케이스**: `.flat100k`, `.flat1m`, `.relational100k`, `.relational1m`
  - **사용 예시**: `await FixtureGenerationConfig.flat100k.generate()`
  - **기존 함수**: `generateFixtures()`, `generateFixtures1M()` 등은 유지하되 주석으로 enum 권장
  - **목적**: 일관된 파일명, 레코드 수, ID 접두사 관리

**참고**: 검색 테스트 상세 내용은 [search-testing.md](.claude/search-testing.md) 참조

