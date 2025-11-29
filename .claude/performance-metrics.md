# Performance Metrics

## 로딩 성능

[PM-01] Fixture 로딩 시간: 1M 데이터 파일 읽기, 파싱, DB 저장 총 시간 (ms)
[PM-02] 데이터 검증: 로딩된 데이터 개수 확인 (기대값: 1,000,000)

## 검색 응답 시간 (Search Latency)

[PM-03] Equality 검색 응답 시간: 단순 필드 검색 응답 시간 (ms)
[PM-04] Range 검색 응답 시간: 범위 검색 응답 시간 (ms)
[PM-05] Complex 검색 응답 시간: 복합 조건 검색 응답 시간 (ms)
[PM-06] Full-Text 검색 응답 시간: 전문 검색 응답 시간 (ms)

## 검색 결과 개수별 성능 (Result Count Impact)

[PM-07] Equality 결과 개수: 검색된 데이터 개수 (typical: 1-10)
[PM-08] Range 결과 개수: 검색된 데이터 개수 (typical: 50K-200K)
[PM-09] Complex 결과 개수: 검색된 데이터 개수 (typical: 10K-50K)
[PM-10] Full-Text 결과 개수: 검색된 데이터 개수 (typical: 5K-50K)

[PM-11] 결과 개수별 응답 시간 (Range Query 기준):
  - 10개 결과: __ms
  - 100개 결과: __ms
  - 1,000개 결과: __ms
  - 10,000개 결과: __ms
  - 100,000개 결과: __ms
  - 500,000개 결과: __ms

## 인덱스 효과 (Indexing Impact)

[PM-12] Indexed 검색 응답 시간: 인덱스된 필드 검색 (ms)
[PM-13] Non-Indexed 검색 응답 시간: 인덱스 미적용 필드 검색 (ms)
[PM-14] 인덱스 효율성: (Non-Indexed 시간 / Indexed 시간) 배수 계산

[PM-15] Equality on Indexed field: __ms
[PM-16] Equality on Non-Indexed field: __ms
[PM-17] Range on Indexed field: __ms
[PM-18] Range on Non-Indexed field: __ms

## 리소스 사용량 (Resource Consumption)

[PM-19] 로딩 중 메모리 사용량: 최대 메모리 (MB)
[PM-20] 검색 중 메모리 사용량: 평균 메모리 (MB)
[PM-21] 로딩 중 CPU 사용률: 평균 CPU (%)
[PM-22] 검색 중 CPU 사용률: 평균 CPU (%)
[PM-23] 메모리 피크: 로딩/검색 중 최고 메모리 (MB)

## DB 파일 크기

[PM-24] DB 파일 크기: 1M 데이터 저장 후 파일 크기 (MB)

## 통계 정보

[PM-25] 검색 성공률: 검색 실행 성공 비율 (%)
[PM-26] 데이터 무결성: 로딩 후 데이터 개수 vs 예상값 일치 여부
