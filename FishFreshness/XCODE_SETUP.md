# Xcode 프로젝트 셋업 가이드

## 1. 새 프로젝트 생성

1. Xcode → File → New → Project
2. **iOS App** 선택
3. Product Name: `FishFreshness`
4. Bundle Identifier: `com.yourname.fishfreshness`
5. Interface: **SwiftUI**
6. Language: **Swift**
7. Storage: **SwiftData** 체크 (또는 나중에 수동 추가)

## 2. 타겟 설정

- Deployment Target: **iOS 26.0**
- Minimum Deployments → iOS 26.0

## 3. 파일 추가

생성된 프로젝트에서 기존 ContentView.swift 삭제 후,
`FishFreshness/` 폴더의 Swift 파일들을 Xcode 프로젝트에 추가:

```
FishFreshnessApp.swift
Models/
  FreshnessGrade.swift
  FreshnessAnalysisResult.swift
  FishScanRecord.swift
ViewModels/
  HomeViewModel.swift
  AnalysisViewModel.swift
  HistoryViewModel.swift
Services/
  FreshnessAnalysisService.swift
  VisionPreprocessingService.swift
Views/
  ContentView.swift
  Home/HomeView.swift
  Analysis/AnalysisLoadingView.swift
  Result/ResultView.swift
  Result/Components/ScoreGaugeView.swift
  Result/Components/GradeTagView.swift
  Result/Components/IndicatorRowView.swift
  History/HistoryView.swift
  History/HistoryRowView.swift
```

## 4. 리소스 추가

`Resources/fish_analysis_prompt.txt`를 프로젝트에 추가 시:
- **Add to target: FishFreshness** 체크
- Copy items if needed 체크

## 5. 필수 프레임워크 (자동 링크됨)

- `FoundationModels` — 자동 (iOS 26.0+)
- `Vision` — 자동 (모든 iOS)
- `SwiftData` — 자동 (iOS 17+)
- `PhotosUI` — 자동

## 6. Info.plist 권한 추가

Xcode Build Settings 또는 Info 탭에서 아래 키가 설정되어 있는지 확인하세요.
(프로젝트에 이미 `INFOPLIST_KEY_*`로 포함되어 있습니다.)

```xml
<!-- 카메라 권한 -->
<key>NSCameraUsageDescription</key>
<string>생선 사진을 촬영하여 신선도를 분석합니다.</string>

<!-- 사진 라이브러리 권한 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>갤러리의 생선 사진으로 신선도를 분석합니다.</string>
```

## 7. Apple Intelligence 요구사항

Foundation Models는 **Apple Intelligence 지원 기기**에서만 동작합니다:
- iPhone 15 Pro / Pro Max 이상
- iOS 26.0 이상
- Apple Intelligence 활성화 필요 (설정 > Apple Intelligence & Siri)
- 영어 또는 지원 언어 설정

미지원 기기에서는 `AnalysisError.modelUnavailable` 에러 처리됩니다.

## 8. Swift 버전

Swift 6 모드 권장. Sendability 경고 발생 시:
- Build Settings → Swift Language Version → Swift 6
