# DBPerformanceTests - Project SSOT

## 프로젝트 개요

macOS 플랫폼에서 Swift 데이터베이스 프레임워크 및 라이브러리의 검색 성능을 측정하는 프로젝트.
100K 및 1M 레코드 환경에서 다양한 검색 시나리오별 응답 시간을 측정하여 각 솔루션의 검색 성능을 비교 분석함.

### 데이터셋 규모 전략
- **100K 레코드**: 기본 테스트 및 개발 시 사용 (Primary testing)
- **1M 레코드**: 대규모 데이터에서의 성능 검증 (Scale validation)
- 자세한 Fixture 구조는 [TM-15] 참조

## 문서 구조

이 프로젝트는 도메인 프리픽스 기반 태그 방식으로 SSOT를 관리함.

### 도메인 프리픽스

TM-XX: Testing Methodology - 테스트 방법론
PM-XX: Performance Metrics - 성능 측정 지표
ENV-XX: Environment - 테스트 환경 설정
CR-XX: Coding Rules - 코딩 규칙

### 규칙 참조 방법

코드 리뷰/커밋: [TM-01] 형식으로 참조
문서 간 참조: 자세한 내용은 [TM-01] 참조
각 도메인별 상세 내용은 별도 문서에 정의됨

### SSOT 문서 목록

- [README.md](.claude/README.md): 프로젝트 개요 및 규칙 인덱스
- [coding-rules.md](.claude/coding-rules.md): [CR-XX] 규칙 정의 (최우선 참조)
- [testing-methodology.md](.claude/testing-methodology.md): [TM-XX] 규칙 정의 (CR 참조)
- [performance-metrics.md](.claude/performance-metrics.md): [PM-XX] 측정 지표 정의 (TM 참조)
- [environment.md](.claude/environment.md): [ENV-XX] 환경 설정 정의 (TM 참조)
- [ui-architecture.md](.claude/ui-architecture.md): [UI-XX] UI 컴포넌트 구조, MVVM 패턴, 상태 관리

문서 의존 관계: CR → TM → PM/ENV, CR → UI

## 핵심 원칙

신뢰성: 모든 측정 결과는 재현 가능하고 검증 가능해야 함
일관성: 동일한 조건과 환경에서 모든 프레임워크를 테스트함
객관성: 개인 성능 비교용이지만 공정한 벤치마크 조건을 유지함

## UI 아키텍처

프로젝트는 MVVM 패턴 기반 SwiftUI로 구현된 벤치마크 실행 및 결과 비교 UI를 제공함.

### 주요 UI 기능
- **Benchmarks Tab**: 실시간 벤치마크 실행 인터페이스
  - 데이터베이스 선택 (Realm, CoreData, SwiftData, UserDefaults)
  - Fixture 로딩 및 검색 시나리오 실행
  - 진행 상태 표시 및 결과 파일 저장

- **Comparison Tab**: 다중 파일 결과 비교 및 시각화
  - 1-4개 결과 파일 선택 (HSplitView: 250pt 사이드바)
  - **성능 차트**: 시나리오별 응답시간 막대 그래프 (SwiftUI Charts)
  - **Top 3 순위**: 각 시나리오별 🥇🥈🥉 메달 표시
  - **환경 메타데이터 비교**: Hardware/Software/Resource 정보 그리드

### 기술 스택
- **MVVM 패턴**: ViewModel (@MainActor) + View (SwiftUI) 분리
- **Swift 6.0 Concurrency**: 엄격한 동시성 체크, Sendable 프로토콜
- **컴포넌트 조합**: 재사용 가능한 View 컴포넌트 (FileSelectionView, PerformanceChartView 등)

자세한 컴포넌트 구조 및 상태 플로우는 [UI Architecture](.claude/ui-architecture.md) 참조.

## 프로젝트 목표

각 데이터베이스 프레임워크의 검색 성능을 측정하고 파일로 내보냄 (100K 및 1M 레코드 기준)
Flat 및 Relational(1:N) 데이터 모델 모두 테스트
4가지 기본 검색 시나리오 + 5가지 Relational 검색 시나리오별 응답 시간 및 결과 개수 측정
인덱스 적용 여부에 따른 검색 성능 차이 분석
시스템 리소스 상태를 고려한 공정한 비교를 위해 테스트 당시 환경 정보를 함께 기록함

## 제약사항 및 범위

macOS 플랫폼에 한정하며 iOS/watchOS/tvOS는 테스트 범위에서 제외함.
검색 성능 측정에만 집중하며 다음 요소는 고려하지 않음:
- 보안성
- 개발자 경험 (DX)
- 커뮤니티 활성도
- 라이선스 및 비용
- 유지보수성

테스트 방식의 제약사항:
- 단일 실행 측정 (평균값이나 반복 측정 없음)
- Fixture 파일 기반 데이터 (점진적 생성 없음)
- 100K 또는 1M 레코드 고정 (중간 데이터 양 변화 없음)

## 검색 테스트 전제 조건

100K 및 1M 레코드의 fixture 파일이 사전에 준비되어 있어야 함
Fixture 파일 위치: Sources/Fixtures/
지원 포맷: JSON (flat-100k.json, flat-1m.json, relational-100k.json, relational-1m.json)
검색용 필수 필드:
  - Flat 모델: id, name, category, price, stockQuantity, createdAt
  - Relational 모델: ProductRecord (id, name, category, price, createdAt) + Tag (id, name, productId)
인덱스 적용 필드: name, category, tag.name (DB별로 인덱스 설정 가능해야 함)

## 도메인별 개요

### Testing Methodology

Fixture 파일에서 100K 또는 1M 레코드를 일괄 로드한 후 검색 시나리오를 실행하여 응답 시간 측정.
- Flat 검색: 4가지 시나리오 (Equality, Range, Complex, Full-Text) - [TM-01~09]
- Relational 검색: 5가지 시나리오 (TagEquality, RangeWithTag, ComplexWithTag, FullTextWithTag, MultipleTagsSearch) - [TM-36~40]
상세 내용은 [Testing Methodology](.claude/testing-methodology.md) 참조.

### Performance Metrics

다음 성능 지표를 측정함:
- Flat 검색 응답 시간 [PM-05~09]: Equality, Range, Complex, Full-Text
- Relational 검색 응답 시간 [PM-25~29]: Tag 기반 검색 5가지 시나리오
- 결과 개수별 성능 [PM-11, PM-30]
- 인덱스 효과 [PM-12~18, PM-31]
- 데이터셋 규모 비교 [PM-24]: 100K vs 1M 성능 델타
- 리소스 사용량 [PM-19~23]: 메모리/CPU
- Fixture 로딩 시간 [PM-04], DB 파일 크기 [PM-02]
상세 내용은 [Performance Metrics](.claude/performance-metrics.md) 참조.

### Environment

테스트 당시 시스템 리소스 상태(CPU/메모리 사용률, 백그라운드 프로세스, 디스크 상태)를 함께 기록하여 결과 비교 시 참고.
상세 내용은 environment.md 참조.

### Coding Rules

프로젝트 개발 환경, 디렉토리 구조, 공통 인터페이스 설계 원칙을 정의.
상세 내용은 coding-rules.md 참조.

## 작업 시 필수 체크리스트

### 코드 작성 전

SSOT 문서 확인: 관련 도메인 문서 먼저 읽기
공통 인터페이스 준수: 새 DB 추가 시 인터페이스 구현 확인
기존 패턴 참고: 다른 DB 구현체 참고하여 일관성 유지

### 테스트 실행 전

환경 정리: 백그라운드 앱 종료, 시스템 재시작 후 2분 대기
Fixture 파일 존재 확인: 100K/1M 레코드 파일이 올바른 위치에 있는지 검증 (flat-*.json, relational-*.json)
환경 정보 기록: 테스트 전 시스템 리소스 상태 확인

### 결과 저장 시

메타데이터 포함: 테스트 일시, 환경 정보, DB 버전, 검색 시나리오별 결과
파일 네이밍: 일관된 명명 규칙 사용
재현 가능성: 동일 조건 재현에 필요한 모든 정보 기록

### 비교 분석 시

환경 차이 확인: 테스트 환경이 유사한지 검증
결과 개수 확인: 검색 시나리오별 반환된 결과 개수 기록
인덱스 효과 분석: 인덱스 적용/미적용 간 성능 차이 분석


