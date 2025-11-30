# Performance Metrics

## 로딩 성능

[PM-01] Fixture 로딩 시간: 데이터 파일 읽기, 파싱, DB 저장 총 시간 (ms)
  - 100K 레코드: 기본 테스트용
  - 1M 레코드: 대규모 검증용
[PM-02] 데이터 검증: 로딩된 데이터 개수 확인
  - 기대값: 100,000 (100K fixture) 또는 1,000,000 (1M fixture)
[PM-03] DB 파일 크기: 데이터 저장 후 파일 크기 (MB)
  - 100K 기준과 1M 기준 각각 측정
[PM-04] 데이터셋 규모 비교: 100K vs 1M 로딩 성능 델타
  - 계산: (1M 로딩 시간 / 100K 로딩 시간) 비율

## Flat 검색 응답 시간 (Search Latency)

[PM-05] Equality 검색 응답 시간: 단순 필드 검색 응답 시간 (ms) - [TM-08] 참조
[PM-06] Range 검색 응답 시간: 범위 검색 응답 시간 (ms) - [TM-09] 참조
[PM-07] Complex 검색 응답 시간: 복합 조건 검색 응답 시간 (ms) - [TM-10] 참조
[PM-08] Full-Text 검색 응답 시간: 전문 검색 응답 시간 (ms) - [TM-11] 참조

## Flat 검색 결과 개수별 성능 (Result Count Impact)

[PM-09] Equality 결과 개수: 검색된 데이터 개수 (typical: 1-10)
[PM-10] Range 결과 개수: 검색된 데이터 개수 (typical: 50K-200K)
[PM-11] Complex 결과 개수: 검색된 데이터 개수 (typical: 10K-50K)
[PM-12] Full-Text 결과 개수: 검색된 데이터 개수 (typical: 5K-50K)

[PM-13] 결과 개수별 응답 시간 (Range Query 기준) - [TM-13] 참조:
  - 10개 결과: __ms
  - 100개 결과: __ms
  - 1,000개 결과: __ms
  - 10,000개 결과: __ms
  - 100,000개 결과: __ms
  - 500,000개 결과: __ms

## Flat 검색 인덱스 효과 (Indexing Impact)

[PM-14] Indexed 검색 응답 시간: 인덱스된 필드 검색 (ms) - [TM-12] 참조
[PM-15] Non-Indexed 검색 응답 시간: 인덱스 미적용 필드 검색 (ms)
[PM-16] 인덱스 효율성: (Non-Indexed 시간 - Indexed 시간) / Non-Indexed 시간 × 100%

[PM-17] Equality on Indexed field (name, category): __ms
[PM-18] Equality on Non-Indexed field: __ms
[PM-19] Range on Indexed field (price): __ms
[PM-20] Range on Non-Indexed field: __ms

## 리소스 사용량 (Resource Consumption)

[PM-21] 로딩 중 메모리 사용량: 최대 메모리 (MB) - [TM-14] 참조
[PM-22] 검색 중 메모리 사용량: 평균 메모리 (MB)
[PM-23] 로딩 중 CPU 사용률: 평균 CPU (%)
[PM-24] 검색 중 CPU 사용률: 평균 CPU (%)

## Relational Search 성능 메트릭

[PM-25] Tag Equality 응답 시간: 단일 tag.name 검색 (ms) - [TM-38a] 참조
  - 측정: 특정 태그를 가진 ProductRecord 검색 시간
  - 계산: 쿼리 실행 시작 ~ 결과 반환 종료

[PM-26] Range With Tag 응답 시간: 가격 범위 + tag 필터 (ms) - [TM-38b] 참조
  - 측정: 복합 조건 join 쿼리 실행 시간
  - 예시: price 10-50 AND tag=="sale"

[PM-27] Complex With Tag 응답 시간: 다중 테이블 조건 join (ms) - [TM-38c] 참조
  - 측정: 여러 조건 조합 join 쿼리 실행 시간
  - 예시: category=="Books" AND tag contains "bestseller" AND price < 30

[PM-28] Full-Text With Tag 응답 시간: 텍스트 + tag 검색 (ms) - [TM-38d] 참조
  - 측정: Full-text search와 relationship 결합 쿼리 시간
  - 예시: name contains "laptop" AND tag=="refurbished"

[PM-29] Multiple Tags 응답 시간: 다중 tag AND 검색 (ms) - [TM-38e] 참조
  - 측정: 2개 이상 태그 모두 가진 제품 검색 시간
  - 예시: tags contain ["organic", "local"] - 둘 다 필요

[PM-30] Relational 결과 개수별 성능
  - Tag Equality: 1K-10K개 제품 예상
  - Range With Tag: 100-5K개 제품 예상
  - Complex With Tag: 10-1K개 제품 예상
  - Full-Text With Tag: 50-500개 제품 예상
  - Multiple Tags: 5-200개 제품 예상
  - 분석: 응답 시간 vs 결과 개수 상관관계

[PM-31] Relational Indexing Impact
  - 측정: tag.name 인덱스 적용 vs 미적용 성능 델타 - [TM-39] 참조
  - 계산: (NonIndexed 시간 - Indexed 시간) / NonIndexed 시간 × 100%
  - 목표: Tag Equality 검색에서 >70% 성능 향상
  - 적용 시나리오: TM-38a~e 모두 인덱스 비교

[PM-32] Join Complexity Overhead
  - 측정: Relational vs Flat 검색 시간 비교
  - 계산: Relational 검색 시간 / Flat 검색 시간 비율
  - 목적: 관계 탐색 비용 정량화
  - 예시: Tag Equality (relational) vs Name Equality (flat) 시간 비교

## 통계 정보

[PM-33] 검색 성공률: 검색 실행 성공 비율 (%)
[PM-34] 데이터 무결성: 로딩 후 데이터 개수 vs 예상값 일치 여부
[PM-35] Relational 무결성: tag.productId 참조 무결성 검증률 (%)
