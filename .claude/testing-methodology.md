# Testing Methodology

## 테스트 실행 방식

[TM-01] 공통 인터페이스를 통해 각 데이터베이스를 순차적으로 실행
[TM-02] 실제 데이터베이스 입출력을 테스트 (파일 시스템 I/O 포함)
[TM-03] 각 데이터베이스 테스트 후 메모리 정리 수행
[TM-04] 각 데이터베이스 테스트 후 DB 파일 및 데이터 완전 삭제

## Fixture 로딩

[TM-05] Fixture 파일을 단일 스냅샷으로 로드 (100K 또는 1M 레코드 일괄)
  - 기본 테스트: 100K 레코드 사용 (`flat-100k.json`, `relational-100k.json`)
  - 대규모 검증: 1M 레코드 사용 (`flat-1m.json`, `relational-1m.json`)
  - Flat 모델: Product 객체 배열 (id, name, category, price, stockQuantity, createdAt)
  - Relational 모델: ProductRecord + Tag 관계 (1:N, tag.productId → product.id)
[TM-06] 로딩 시간 측정 (포함: 파일 읽기 + 파싱 + DB 저장)
[TM-07] 로딩 완료 후 모든 데이터가 DB에 존재함을 검증 (기대값: 100,000 또는 1,000,000)

## 검색 시나리오 (4가지)

**참고**: 모든 검색 쿼리 파라미터는 `SearchTestConfig` enum에서 중앙 관리됨. 자세한 내용은 [search-testing.md](.claude/search-testing.md) 참조.

[TM-08] 단순 필드 검색 (Equality Query)
  - 설정: `SearchTestConfig.equalitySearch`
  - 조건: name == "Product-AA" (Zipf rank 1, 가장 빈번한 값)
  - 1회 검색, 1M 기준 13K-17K개 결과 예상
  - 시간 측정: 쿼리 실행부터 결과 반환까지

[TM-09] 범위 검색 (Range Query)
  - 설정: `SearchTestConfig.rangeSearch`
  - 조건: price BETWEEN 1000 AND 5000
  - 1회 검색, 1M 기준 75K-85K개 결과 예상
  - 시간 측정: 쿼리 실행부터 결과 반환까지

[TM-10] 복합 조건 검색 (Complex Condition Query)
  - 설정: `SearchTestConfig.complexSearch`
  - 조건: category="Electronics" AND price BETWEEN 2000-8000 AND date>='2023-01-01'
  - 1회 검색, 1M 기준 6K-14K개 결과 예상
  - 시간 측정: 쿼리 실행부터 결과 반환까지

[TM-11] 전문 검색 (Full-Text Search)
  - 설정: `SearchTestConfig.fullTextSearch`
  - 조건: description CONTAINS 'premium'
  - 1회 검색, 1M 기준 12K-28K개 결과 예상
  - 시간 측정: 쿼리 실행부터 결과 반환까지
  - 주의: DB가 full-text 검색을 지원하지 않는 경우 LIKE 또는 contains 사용

## 검색 변형 (Variations)

[TM-12] 인덱스 적용 vs 미적용 검색
  - 동일 쿼리를 인덱스된 필드(name, category)와 미인덱스 필드로 각각 실행
  - 두 경우 모두 시간 측정하여 인덱스 효과 분석

[TM-13] 결과 개수별 성능 측정
  - Range 검색에서 조건 범위를 조정하여 결과 개수 변화:
    - 10개 결과
    - 100개 결과
    - 1,000개 결과
    - 10,000개 결과
    - 100,000개 결과
    - 500,000개 결과
  - 각 경우마다 쿼리 시간 측정

[TM-14] 리소스 모니터링
  - 각 검색 실행 시 메모리 사용량, CPU 사용률 기록
  - Instruments 또는 시스템 모니터링 도구 사용

## 테스트 실행 순서

[TM-15] 테스트는 단일 실행 (재현성 확보 위해 재시작 후 단회 측정)
  1. 환경 정리 및 기록 (백그라운드 앱 종료, 시스템 재시작 후 2분 대기)
  2. DB 초기화
  3. Fixture 데이터 로드 - 100K 또는 1M (TM-05~07), 참고: [CR-60] 파일 구조
  4. TM-08 단순 필드 검색 실행
  5. TM-09 범위 검색 실행 (기본 조건)
  6. TM-10 복합 조건 검색 실행
  7. TM-11 전문 검색 실행
  8. TM-12 인덱스 비교 (각 검색 재실행)
  9. TM-13 결과 개수별 성능 측정 (범위 검색으로 6회)
 10. TM-14 리소스 모니터링 (위 과정 반복하며 측정)
 11. 결과 파일 저장 (TM-28 파일명 형식 참조)

[TM-16] 데이터베이스 전환: DB 파일 완전 삭제 후 다음 DB 테스트 시작

## 측정 방법 및 정확도

[TM-20] 각 데이터베이스당 1회씩만 측정
[TM-21] 시간 측정 단위는 밀리초(ms)
[TM-22] 데이터 준비 시간 제외, 순수 검색 시간만 측정
[TM-23] 단일 값만 기록 (평균/중앙값 없음)
[TM-24] ContinuousClock 사용하여 시간 측정 (Swift 6.0 표준, 시스템 변경 영향 없음, 타입 안전)
[TM-25] Instruments를 보조 도구로 사용하여 메모리, CPU 사용률 측정 및 결과 검증

## 결과 파일 형식 및 저장

[TM-26] JSON 포맷으로 결과 저장
[TM-27] 저장 위치는 프로젝트 내 특정 폴더 (Results/)
[TM-28] 파일 네이밍 규칙: `YYYY-MM-DDTHH:MM:SSZ-{DatabaseName}-search.json`
  - 예시: `2025-11-30T14:30:00Z-Realm-search.json`
  - Timestamp: ISO 8601 형식 (UTC)
  - DatabaseName: Realm, CoreData, SwiftData, UserDefaults
  - Suffix: `-search.json` (검색 벤치마크 파일 식별자)
[TM-29] 포함할 메타데이터:
- 테스트 일시 (ISO 8601 형식)
- 데이터베이스 이름 및 버전
- 환경 정보 (CPU 사용률, 메모리 상태, 디스크 상태, 백그라운드 프로세스)
- 데이터 양 정보 (100K 또는 1M)
- 데이터 모델 타입 (Flat 또는 Relational)
- 각 검색 시나리오별 측정 결과 (TM-08 ~ TM-14, TM-38a~e)
- 검색별 결과 개수 기록

## Fixture 생성 규칙

[TM-30] Fixture 파일 포맷: JSON (메타데이터 + 레코드 배열)
[TM-31] Zipf 분포 생성: seed 기반 의사 난수, 반복 가능
[TM-32] description 길이 분포: 50-200자(30%), 200-500자(40%), 500-2000자(30%)
[TM-33] 파일 크기: flat-100k.json ~80MB
[TM-34] 로딩 성능 측정: 파일 읽기 + 파싱 + DB 저장 총 시간(ms)
[TM-35] 로딩 후 데이터 검증: 실제 저장 레코드 수 == 100,000

## Relational Search 방법론

[TM-36] Relational Search 개요
  - 1:N 관계 쿼리 테스트 (ProductRecord ↔ Tags)
  - 5가지 시나리오: TagEquality, RangeWithTag, ComplexWithTag, FullTextWithTag, MultipleTagsSearch
  - 구현체: CoreDataRelationalSearcher, RealmRelationalSearcher, SwiftDataRelationalSearcher
  - Fixture: `relational-100k.json`, `relational-1m.json`
  - 성능 메트릭: [PM-25~32] 참조

[TM-37] Relational 데이터 모델
  - **ProductRecord**: id (Int), name (String), category (String), price (Decimal), createdAt (Date)
  - **Tag**: id (Int), name (String), productId (Int) - Foreign Key
  - **Relationship**: ProductRecord.tags = Tag[] (1:N)
  - **Referential Integrity**: 모든 tag.productId는 유효한 product.id 참조

[TM-38] Relational Search 시나리오

  [TM-38a] Tag Equality Search
    - 조건: 특정 tag.name과 일치하는 ProductRecord 검색
    - 예시: tag.name == "electronics" 인 제품
    - 테스트 포인트: Join 성능, tag.name 인덱스 활용
    - 예상 결과: 1K-10K개 제품

  [TM-38b] Range With Tag
    - 조건: 가격 범위 + tag 필터 조합
    - 예시: tag.name == "sale" AND price >= 10 AND price <= 50
    - 테스트 포인트: 다중 조건 join 쿼리 최적화
    - 예상 결과: 100-5K개 제품

  [TM-38c] Complex With Tag
    - 조건: 여러 테이블 조건 조합
    - 예시: category == "Books" AND tag.name contains "bestseller" AND price < 30
    - 테스트 포인트: 복합 join 최적화
    - 예상 결과: 10-1K개 제품

  [TM-38d] Full-Text With Tag
    - 조건: 제품명 텍스트 검색 + tag 필터
    - 예시: product.name contains "laptop" AND tag.name == "refurbished"
    - 테스트 포인트: Full-text + relationship 쿼리
    - 예상 결과: 50-500개 제품

  [TM-38e] Multiple Tags Search
    - 조건: 2개 이상 특정 tag를 모두 가진 제품 (AND 로직)
    - 예시: tag.name IN ["organic", "local"] - 둘 다 포함
    - 테스트 포인트: 다중 join 집계 성능
    - 예상 결과: 5-200개 제품

[TM-39] Relational Index Variations
  - Indexed: tag.name에 데이터베이스 인덱스 적용
  - Non-indexed: tag.name 인덱스 제거
  - 비교 방법론: [TM-12]와 동일하게 인덱스 효과 분석
  - 성능 메트릭: [PM-31] 참조

[TM-40] Relational Benchmark 실행
  - SearchOrchestrator 메서드 사용:
    - `runRealmRelationalBenchmark()`
    - `runCoreDataRelationalBenchmark()`
    - `runSwiftDataRelationalBenchmark()`
  - 출력 형식: Flat 벤치마크와 동일한 JSON (TM-28)
  - 파일명 접미사: `-search.json` (Flat과 구분 없음, 메타데이터에서 모델 타입 구분)

## 결과 비교 방법론

[TM-41] 비교 대상: SearchBenchmarkReport (검색 벤치마크 결과만)
[TM-42] 파일 선택: Results 디렉토리에서 *-search.json 파일 수동 선택
[TM-43] 선택 제한: 최소 1개, 최대 4개 파일 (차트 가독성 유지)
[TM-44] 시나리오별 비교: Flat 4가지 + Relational 5가지 시나리오 각각 응답시간 비교
[TM-45] 순위 계산: 각 시나리오별 응답시간 기준 오름차순 정렬
[TM-46] 환경 정보 비교: 테스트 일시, CPU, 메모리, macOS 버전 등 메타데이터 비교

