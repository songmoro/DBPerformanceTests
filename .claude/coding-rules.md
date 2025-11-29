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
[CR-10] Sources/Models: 테스트 데이터 모델
[CR-11] Sources/Results: 결과 저장 및 비교 로직
[CR-12] Results/: JSON 결과 파일 저장 폴더

## 공통 인터페이스 설계

[CR-13] 공통 인터페이스를 정의하고 각 데이터베이스가 이를 구현
[CR-14] 컴파일 타임에 타입을 확정하여 런타임 오버헤드 방지 (제네릭 또는 associated type 활용)
[CR-15] 프로토콜 기반이 아닌 구체 타입 사용 시 성능 이점 고려

## 테스트 데이터 스키마

[CR-16] 단순 모델: 5개 기본 타입 속성 (String, Int, Double, Bool, Date)
[CR-17] 복잡 모델: 관계 포함 (1:N 관계), 최대 5뎁스까지
[CR-18] 모든 데이터는 고유 식별자(ID) 보유

## 비교 대상 데이터베이스

[CR-19] Realm
[CR-20] CoreData
[CR-21] SwiftData
[CR-22] UserDefaults

## Swift 6.0 동시성

[CR-23] Swift 6.0 동시성 모델을 명시적으로 준수
[CR-24] unchecked 사용을 최대한 지양하고 안전한 동시성 보장

