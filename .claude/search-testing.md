# Search Testing Architecture

## Overview

검색 테스트의 설정, 실행, 검증 방법론을 정의한다. 모든 검색 테스트는 `SearchTestConfig` enum을 통해 중앙에서 관리되며, 실제 데이터 분포를 고려한 쿼리 파라미터를 사용한다.

**핵심 원칙:**
- Single Source of Truth: 모든 쿼리 파라미터는 `SearchTestConfig`에서 관리
- 데이터 분포 인식: Zipf/Uniform 분포를 고려한 쿼리 값 사용
- 결과 검증: 통계 기반 기대 결과 개수 검증
- 하드코딩 금지: 모든 값은 `ValueGenerators` 또는 `DatasetConstants`에서 참조

## Configuration-Driven Testing

### Central Configuration: SearchTestConfig

모든 검색 테스트 시나리오는 단일 enum `SearchTestConfig`에 정의됨.

**위치:** `DBPerformanceTests/Sources/Benchmarks/SearchTestConfig.swift`

**사용 예시:**
```swift
let config = SearchTestConfig.equalitySearch
let params = config.queryParams
let result = try searcher.searchByName(params.name!, indexed: true)

// 결과 검증
if !params.expectedCount.validate(result.count) {
    print("⚠️ Warning: \(config) returned \(result.count), expected \(params.expectedCount)")
}
```

### 주요 구성 요소

#### 1. SearchTestConfig (enum)
- 9개 검색 시나리오 정의 (Flat 4개 + Relational 5개)
- 각 케이스는 `queryParams`, `queryCondition`, `description` 제공
- `CustomStringConvertible` 준수로 자동 문서화

#### 2. QueryParameters (struct)
- 타입 안전 파라미터 컨테이너
- 선택적 필드: 각 시나리오에 필요한 필드만 설정
- `ExpectedCount`를 통한 결과 검증 지원

#### 3. DatasetConstants (enum)
- Fixture 생성 상수 중앙 관리
- 날짜 범위, 가격 범위, Zipf 파라미터 등 정의
- 검색 쿼리와 데이터 생성 간 일관성 보장

#### 4. FixtureGenerationConfig (enum)
- Fixture 생성 설정 enum화
- `flat100k`, `flat1m`, `relational100k`, `relational1m` 케이스
- 파일명, 레코드 수, ID 접두사 등 자동 관리

## Search Scenarios

### Flat Model Searches (4 scenarios)

#### 1. Equality Search [TM-08]

**목적:** 인덱스 효과 측정 (고유값 카디널리티에서의 정확 일치 검색)

**쿼리:**
```swift
name == "Product-AA"  // Zipf rank 1, 가장 빈번한 값
```

**데이터 분포:**
- "Product-AA"는 Zipf(s=1.3, k=100)에서 rank 1
- 1M 레코드 기준: ~15,000회 출현 (1.5%)
- 100K 레코드 기준: ~1,500회 출현 (1.5%)

**기대 결과:**
- 1M: 13,000-17,000개
- 100K: 1,300-1,700개

**검증 포인트:**
- name 필드 인덱스 효과
- 고빈도 값에 대한 검색 성능

---

#### 2. Range Search [TM-09]

**목적:** 범위 검색 성능 측정 (인덱스 미적용 필드)

**쿼리:**
```swift
price BETWEEN 1000 AND 5000
```

**데이터 분포:**
- price는 Uniform(100, 50001) 분포
- 범위 커버리지: (5000-1000) / (50001-100) ≈ 8%

**기대 결과:**
- 1M: 75,000-85,000개
- 100K: 7,500-8,500개

**검증 포인트:**
- 범위 쿼리 최적화
- Full table scan 성능

---

#### 3. Complex Search [TM-10]

**목적:** 복합 조건 검색 최적화 (인덱스 + 비인덱스 조합)

**쿼리:**
```swift
category='Electronics' AND
price BETWEEN 2000 AND 8000 AND
date>='2023-01-01'
```

**데이터 분포:**
- category="Electronics": Zipf rank 1, ~4% (40,000/1M)
- price 범위: (8000-2000)/(50001-100) ≈ 12% → 교집합 ~4.8%
- date: 2023-01-01은 생성 범위 시작점 → 100% 포함

**기대 결과:**
- 1M: 6,000-14,000개 (복합 조건 선택도 고려)
- 100K: 600-1,400개

**검증 포인트:**
- 인덱스 활용 (category)
- 다중 조건 필터링 효율

---

#### 4. Full-Text Search [TM-11]

**목적:** 텍스트 검색 성능 (LIKE 또는 Full-Text Index)

**쿼리:**
```swift
description CONTAINS 'premium'
```

**데이터 분포:**
- description은 `DescriptionWords` 단어 풀에서 생성
- "premium"은 고빈도 단어로 포함
- 예상 출현율: ~2%

**기대 결과:**
- 1M: 12,000-28,000개
- 100K: 1,200-2,800개

**검증 포인트:**
- Full-text 검색 또는 LIKE 성능
- 긴 텍스트 필드 스캔 효율

---

### Relational Model Searches (5 scenarios)

#### 5. Tag Equality Search [TM-38a]

**목적:** 1:N 관계 Join 성능

**쿼리:**
```swift
tags CONTAINS 'new-tech'
```

**데이터 분포:**
- 200개 고유 태그, 각 제품당 1-5개 (평균 2.5개)
- 총 태그 레코드: 1M × 2.5 = 2.5M 개
- "new-tech" 출현 확률: 1/200 × 2.5 ≈ 0.5%

**기대 결과:**
- 1M: 3,000-7,000개
- 100K: 300-700개

**검증 포인트:**
- Join 쿼리 성능
- tag.name 인덱스 효과

---

#### 6. Range + Tag Search [TM-38b]

**목적:** 범위 검색 + Join 조합 성능

**쿼리:**
```swift
price BETWEEN 1000 AND 5000 AND
tags CONTAINS 'sale-value'
```

**데이터 분포:**
- price 범위: ~8% (Range Search와 동일)
- tag "sale-value": ~0.5%
- 교집합: 8% × 0.5% ≈ 0.04% → 조정: ~0.4% (tag 중복 고려)

**기대 결과:**
- 1M: 2,500-6,000개
- 100K: 250-600개

**검증 포인트:**
- 다중 조건 Join 최적화
- 필터 순서 최적화

---

#### 7. Complex + Tag Search [TM-38c]

**목적:** 복합 조건 + Join 성능

**쿼리:**
```swift
category='Electronics' AND
price BETWEEN 2000 AND 8000 AND
date>='2023-01-01' AND
tags CONTAINS 'hot-deal'
```

**데이터 분포:**
- category ~4%, price 범위 ~12%, tag ~0.5%
- 복합 교집합: ~0.02-0.25%

**기대 결과:**
- 1M: 400-2,500개
- 100K: 40-250개

**검증 포인트:**
- 복합 Join 최적화
- 인덱스 병합 전략

---

#### 8. Full-Text + Tag Search [TM-38d]

**목적:** 텍스트 검색 + Join 조합

**쿼리:**
```swift
description CONTAINS 'premium' AND
tags CONTAINS 'premium-quality'
```

**데이터 분포:**
- description ~2%, tag ~0.5%
- 교집합: ~0.01-0.2% (의미적 연관성 고려)

**기대 결과:**
- 1M: 600-2,000개
- 100K: 60-200개

**검증 포인트:**
- Full-text + relationship 쿼리
- 두 비인덱스 조건 조합

---

#### 9. Multiple Tags Search [TM-38e]

**목적:** 다중 Join 집계 성능 (AND 로직)

**쿼리:**
```swift
tags CONTAINS 'premium-value' AND
tags CONTAINS 'hot-deal'
```

**데이터 분포:**
- 각 태그 ~0.5%
- 두 태그 동시 보유: ~0.003-0.03% (tag 독립 가정 위반 시 더 높음)

**기대 결과:**
- 1M: 30-300개
- 100K: 3-30개

**검증 포인트:**
- 다중 Join 집계 성능
- Self-join 최적화

---

## Data Distribution Awareness

### Zipf Distribution

Zipf 분포는 현실 세계 데이터의 빈도 분포를 모델링한다.

**공식:** P(k) = (1/k^s) / H_n

**name 필드 (s=1.3, k=100):**
- Rank 1 ("Product-AA"): ~15,000회 (1.5%)
- Rank 10: ~3,500회 (0.35%)
- Rank 50: ~1,200회 (0.12%)
- Rank 100: ~800회 (0.08%)

**category 필드 (s=1.5, k=50):**
- Rank 1 ("Electronics"): ~40,000회 (4%)
- Rank 10: ~5,000회 (0.5%)
- Rank 25: ~2,500회 (0.25%)
- Rank 50: ~1,600회 (0.16%)

**예상 빈도 계산:**
```swift
let freq = ValueGenerators.expectedFrequency(forNameRank: 0, totalRecords: 1_000_000)
// Returns: ~15,000
```

### Uniform Distribution

균등 분포 필드는 모든 값이 동일한 확률로 나타난다.

**price (100-50,000):**
- 범위 1000-5000: (5000-1000)/(50000-100) ≈ 8%
- 범위 2000-8000: (8000-2000)/(50000-100) ≈ 12%

**date (2023-01-01 to 2024-12-31):**
- 총 730일 범위
- 2023-01-01 이후: 100% (전체 범위 시작점)
- 2024-01-01 이후: ~50%

### Tag Distribution

**태그 생성 방식:**
- 200개 고유 태그 (prefix-base 조합)
- 각 제품당 1-5개 태그 (균등 분포)
- 평균 2.5개/제품

**태그 출현 확률:**
- 단일 태그: 1/200 × 2.5 ≈ 0.0125 (1.25%)
- 두 태그 동시: ~0.003-0.03% (독립 가정 하)

---

## Dataset Constants

모든 Fixture 생성 파라미터는 `DatasetConstants`에 중앙 관리됨.

**위치:** `DBPerformanceTests/Sources/Benchmarks/DatasetConstants.swift`

```swift
DatasetConstants.dateRange.start        // 2023-01-01
DatasetConstants.dateRange.end          // 2024-12-31
DatasetConstants.priceRange.min         // 100
DatasetConstants.priceRange.max         // 50001 (exclusive)
DatasetConstants.nameDistribution       // (skewness: 1.3, uniqueCount: 100)
DatasetConstants.categoryDistribution   // (skewness: 1.5, uniqueCount: 50)
DatasetConstants.defaultSeed            // 42
```

**보장 사항:**
- 검색 쿼리는 DatasetConstants 값을 참조
- 데이터 생성도 동일한 상수 사용
- 쿼리-데이터 불일치 방지

---

## Query Parameter Validation

### Expected Count Validation

각 시나리오는 기대 결과 개수를 정의하며, 실행 시 자동 검증됨.

**ExpectedCount enum:**
```swift
.exact(Int)               // 정확히 N개
.range(min:max:)          // min-max 범위
.any                      // 검증 불필요
```

**검증 로직:**
```swift
let config = SearchTestConfig.equalitySearch
let params = config.queryParams
let result = try searcher.searchByName(params.name!)

if !params.expectedCount.validate(result.count) {
    print("⚠️ Warning: \(config) returned \(result.count), expected \(params.expectedCount)")
}
```

**목적:**
- 데이터 생성 버그 조기 발견
- 검색 구현 정확성 검증
- 데이터 분포 변경 감지

---

## Migration from Hardcoded Values

### Before (Problematic)

```swift
// SearchScenarios.swift:27
let equalityResult = try benchmark.measure {
    try searcher.searchByName("Product_12345", indexed: indexed)
}
// ❌ 문제: "Product_12345"는 실제 데이터에 존재하지 않음 → 0 results

// SearchScenarios.swift:55
let complexResult = try benchmark.measure {
    try searcher.complexSearch(
        category: "Electronics",
        priceMin: 2000,
        priceMax: 8000,
        dateFrom: Date(timeIntervalSince1970: 1609459200) // 2021-01-01
    )
}
// ❌ 문제: 2021-01-01은 데이터 범위(2023-2024) 밖 → no matches
```

### After (Configuration-Driven)

```swift
// SearchScenarios.swift (refactored)
let config = SearchTestConfig.equalitySearch
let params = config.queryParams
let equalityResult = try benchmark.measure {
    try searcher.searchByName(params.name!, indexed: indexed)
}
// ✅ params.name = "Product-AA" (ValueGenerators.mostFrequentName)
// ✅ 보장된 결과: ~15,000개 (1M 기준)

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
// ✅ dateFrom = 2023-01-01 (DatasetConstants.dateRange.start)
// ✅ category = "Electronics" (ValueGenerators.mostFrequentCategory)
```

---

## File Organization

```
DBPerformanceTests/
├── Sources/
│   ├── Benchmarks/
│   │   ├── SearchTestConfig.swift           ⭐ NEW: 중앙 설정
│   │   ├── QueryParameters.swift            ⭐ NEW: 파라미터 타입
│   │   ├── DatasetConstants.swift           ⭐ NEW: 데이터 상수
│   │   ├── FixtureGenerationConfig.swift    ⭐ NEW: 생성 설정
│   │   ├── SearchScenarios.swift            🔧 REFACTORED
│   │   └── ...
│   ├── Utilities/
│   │   ├── ZipfianGenerator.swift           🔧 ENHANCED: Test helpers
│   │   ├── FixtureGenerator.swift           🔧 REFACTORED
│   │   └── GenerateFixtures.swift           🔧 REFACTORED
│   └── ...
└── .claude/
    ├── search-testing.md                    ⭐ NEW: 본 문서
    ├── testing-methodology.md               🔧 UPDATED: 참조 추가
    └── coding-rules.md                      🔧 UPDATED: CR-70~74
```

---

## Testing Workflow

### Step 1: Generate Fixtures (One-time Setup)

```swift
// FixtureGenerationConfig를 사용한 enum 기반 생성
await FixtureGenerationConfig.flat100k.generate()
await FixtureGenerationConfig.relational1m.generate()
```

**생성 파일:**
- JSON: `flat-100k.json`, `relational-1m.json`
- Realm: `realm_100k.realm`, `realm_1m.realm`
- CoreData: `coredata_100k.sqlite`, `coredata_1m.sqlite`
- SwiftData: `swiftdata_100k.sqlite`, `swiftdata_1m.sqlite`
- UserDefaults: `fixture_100k` suite (100K만)

### Step 2: Run Search Tests

```swift
let scenarios = SearchScenarios()

// Flat model 검색 (4 scenarios)
let realmResults = try await scenarios.runRealm(searcher: realmSearcher)

// Relational model 검색 (5 scenarios)
let realmRelResults = try await scenarios.runRealmRelational(searcher: realmRelSearcher)
```

### Step 3: Validate Results

**자동 검증:**
- 각 시나리오 실행 시 `ExpectedCount.validate()` 호출
- 범위 벗어난 결과는 경고 출력
- 로그 예시:
  ```
  ⚠️ Warning: Equality returned 342, expected 13000-17000
  ```

**수동 검증:**
- 결과 파일 (`*-search.json`) 확인
- 각 시나리오별 `resultCount` 필드 검토
- Comparison Tab에서 여러 결과 비교

---

## Expected Result Calculation

### Zipf 분포 기반 계산

```swift
// Rank 0 ("Product-AA")의 예상 빈도
let generator = ZipfianGenerator(skewness: 1.3, uniqueCount: 100)
let frequencies = generator.expectedFrequencies(totalCount: 1_000_000)
let rank0Freq = frequencies[0]  // ~15,000

// Helper 사용
let freq = ValueGenerators.expectedFrequency(forNameRank: 0, totalRecords: 1_000_000)
// Returns: ~15,000
```

### 균등 분포 기반 계산

```swift
// Price range 1000-5000 out of 100-50000
let coverage = Double(5000 - 1000) / Double(50000 - 100)  // ~0.08 (8%)
let expected = Int(1_000_000 * coverage)  // 80,000
```

### 복합 조건 계산

```swift
// category (~4%) AND price range (~12%)
// 독립 가정: P(A ∩ B) = P(A) × P(B)
let categoryProb = 0.04
let priceProb = 0.12
let combinedProb = categoryProb * priceProb  // 0.0048 (0.48%)
let expected = Int(1_000_000 * combinedProb)  // 4,800

// 실제는 상관관계 고려하여 범위로 설정:
// .range(min: 6000, max: 14000)
```

---

## Benefits

### 1. Correctness
- ✅ 쿼리는 실제 데이터와 일치하는 값 사용
- ✅ 날짜 범위 정확히 맞춤 (2023-2024)
- ✅ 기대 결과 검증으로 구현 정확성 확인

### 2. Maintainability
- ✅ Single Source of Truth (SearchTestConfig)
- ✅ 파라미터 변경 시 1곳만 수정
- ✅ 4개 DB 구현체 자동으로 동일한 값 사용

### 3. Verifiability
- ✅ 통계 기반 기대값으로 조기 버그 발견
- ✅ Zipf 빈도 계산으로 검증 가능
- ✅ 경고 메시지로 불일치 즉시 감지

### 4. Documentation
- ✅ CustomStringConvertible로 자동 문서화
- ✅ 전용 문서 (본 파일)로 지식 전달
- ✅ TM-XX 코드 참조로 일관성 유지

### 5. Reproducibility
- ✅ Seed=42로 결정론적 데이터 생성
- ✅ 동일한 쿼리로 재현 가능
- ✅ 버전 관리된 설정

---

## Related Documents

- [testing-methodology.md](.claude/testing-methodology.md): [TM-08~11, TM-36~40] 검색 시나리오 정의
- [performance-metrics.md](.claude/performance-metrics.md): [PM-05~12, PM-25~32] 성능 메트릭
- [coding-rules.md](.claude/coding-rules.md): [CR-70~74] 검색 설정 규칙
- [environment.md](.claude/environment.md): 테스트 환경 설정

---

## Validation Checklist

### Fixture Generation
- [ ] DatasetConstants 값이 FixtureGenerator에 반영됨
- [ ] ID 형식: "FLAT-000001" (flat), "PROD-000001" (relational)
- [ ] 날짜 범위: 2023-01-01 ~ 2024-12-31
- [ ] 가격 범위: 100 ~ 50000
- [ ] Seed=42로 재현 가능

### Search Queries
- [ ] 모든 name 검색은 ValueGenerators.productNames에서 참조
- [ ] 모든 category 검색은 ValueGenerators.categories에서 참조
- [ ] 모든 tag 검색은 ValueGenerators.tagNames에서 참조
- [ ] 날짜 필터는 DatasetConstants.dateRange 사용
- [ ] 가격 범위는 DatasetConstants.priceRange 내

### Result Validation
- [ ] Equality search: ~1.5% (1M 기준 13K-17K)
- [ ] Range search: ~8% (1M 기준 75K-85K)
- [ ] Complex search: ~0.6-1.4% (1M 기준 6K-14K)
- [ ] FullText search: ~1.2-2.8% (1M 기준 12K-28K)
- [ ] Tag equality: ~0.3-0.7% (1M 기준 3K-7K)

### Code Standards
- [ ] SearchScenarios.swift에 하드코딩된 값 없음
- [ ] 모든 쿼리는 SearchTestConfig 사용
- [ ] 결과 검증 로그 출력
- [ ] TM-XX 코드 주석 포함
