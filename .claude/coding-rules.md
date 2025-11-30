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
[CR-11] Sources/Fixtures: 1M 레코드 fixture 파일 저장 위치 (JSON/CSV)
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
[CR-25] JSON 포맷 지원 및 각 DB별 파일 사전 생성
[CR-26] 100K 레코드 일괄 로딩 메커니즘
[CR-27] 메모리 효율성 고려한 스트리밍 로드 옵션
[CR-28] 로딩 시간 측정 (파일 읽기 + 파싱 + DB 저장)

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
[CR-45] Comparison 탭: HSplitView (Sidebar 250pt + Main Content)
[CR-46] 파일 선택: Results 디렉토리에서 *-search.json 파일만 필터링
[CR-47] 선택 제한: 최소 1개, 최대 4개 파일 선택 가능
[CR-48] 차트: SwiftUI Charts 사용, BarMark로 시나리오별 비교
[CR-49] DB별 색상: Realm(Blue), CoreData(Green), SwiftData(Orange), UserDefaults(Purple)
[CR-50] 순위 표시: 시나리오별 Top 3 표시 (1st 금, 2nd 은, 3rd 동)
[CR-51] 메타데이터 비교: Grid 레이아웃으로 환경 정보 테이블 표시

## Swift 6.0 동시성

[CR-52] Swift 6.0 동시성 모델을 명시적으로 준수
[CR-53] unchecked 사용을 최대한 지양하고 안전한 동시성 보장
[CR-54] @MainActor로 UI 관련 ViewModel 격리
[CR-55] Sendable 프로토콜 준수 (모든 데이터 모델)

