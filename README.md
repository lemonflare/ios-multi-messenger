# iOS Multi Messenger Builder

GitHub Actions를 사용하여 멀티 메신저 앱(KakaoTalk, LINE)을 빌드하는 프로젝트입니다.

## Features

- **MultiKaTalk**: 카카오톡 여러 개 사용
- **MultiLine**: LINE 여러 개 사용
- **자동화**: GitHub Actions로 완전 자동화된 빌드 프로세스
- **안전성**: 키체인, 앱 그룹, URL 스킴 분리로 충돌 방지

## Prerequisites

### 1. 탈옥된 iOS 장비에서 앱 덤프 뜨기

다음 도구 중 하나를 사용하여 앱을 덤프:
- [TrollDecrypt](https://github.com/alfiecg24/TrollDecrypt)
- [TrollDecryptJB](https://github.com/alfiecg24/TrollDecryptJB)
- [flexdecrypt](https://github.com/ichitaso/flexdecrypt)

### 2. Decrypted IPA 확보

덤프한 IPA 파일의 URL이 필요합니다:
- GitHub Releases에 업로드
- Google Drive, Dropbox 등의 공유 링크
- 직접 호스팅하는 파일 URL

## Usage

### MultiKaTalk 빌드

1. **GitHub Actions 실행**
   - Repository → Actions → "Build MultiKaTalk" 선택
   - "Run workflow" 클릭

2. **파라미터 입력**
   - `ipa_url`: Decrypted KakaoTalk IPA URL (필수)
   - `app_suffix`: 앱 접미사 (예: "2" → KakaoTalk2)
   - `display_name`: 표시 이름 (예: "KakaoTalk2")

3. **빌드 대기**
   - 약 5-10분 소요
   - 완료 시 Release에 draft로 생성

4. **IPA 다운로드**
   - Releases 페이지에서 다운로드
   - AltStore/SideStore로 설치

### MultiLine 빌드

1. **GitHub Actions 실행**
   - Repository → Actions → "Build MultiLine" 선택
   - "Run workflow" 클릭

2. **파라미터 입력**
   - `ipa_url`: Decrypted LINE IPA URL (필수)
   - `app_suffix`: 앱 접미사 (예: "2" → LINE2)
   - `display_name`: 표시 이름 (예: "LINE2")

3. **빌드 대기 및 다운로드**
   - MultiKaTalk와 동일

## Build Process

빌드 프로세스는 다음 단계를 자동화합니다:

### 1. IPA 다운로드 및 검증
- URL에서 IPA 다운로드
- 파일 형식 검증

### 2. 추출 및 Info.plist 수정
```
수정 내용:
- CFBundleIdentifier: com.iwilab.KakaoTalk → com.iwilab.KakaoTalk2
- CFBundleDisplayName: KakaoTalk → KakaoTalk2
- APP_GROUPS_IDENTIFIER: group.com.iwilab.KakaoTalk → group.com.iwilab.KakaoTalk2
- 모든 URL schemes에 -2 접미사 추가
```

### 3. InfoPlist.strings 수정
- CFBundleDisplayName 변경
- 다국어 지원

### 4. 불필요한 폴더 삭제
- Watch 폴더 삭제
- PlugIns 폴더 삭제
- 용량 최적화

### 5. MultiKaTalkFix/MultiLineFix.dylib 빌드
- Xcode 프로젝트 빌드
- 키체인 충돌 방지
- 앱 그룹 충돌 방지
- Siri 충돌 방지

### 6. dylib 주입
- optool을 사용하여 dylib 주입
- @executable_path/Dylibs/ 경로에 복사

### 7. 엔타이틀먼트 적용
- 무료 개발자 계정용 엔타이틀먼트
- ldid로 서명

### 8. IPA 생성
- Payload 폴더 압축
- .zip → .ipa 변환

## Troubleshooting

### 빌드 실패: "dylib not found"
- Xcode 프로젝트 경로 확인
- scheme 이름 확인

### 빌드 실패: "IPA validation failed"
- IPA URL이 정상인지 확인
- 파일이 완전히 다운로드되었는지 확인

### 앱이 설치되지 않음
- 엔타이틀먼트 확인
- AltStore/SideStore 버전 확인

### 앱 충돌
- dylib가 제대로 주입되었는지 확인
- 엔타이틀먼트가 올바른지 확인

## Project Structure

```
multi/
├── .github/
│   └── workflows/
│       ├── multikatalk.yml      # MultiKaTalk 빌드 워크플로우
│       └── multiline.yml        # MultiLine 빌드 워크플로우
├── scripts/
│   ├── modify_url_schemes.py    # URL 스킴 수정 스크립트
│   └── modify_strings.py        # InfoPlist.strings 수정 스크립트
├── multikatalkfix-main/         # MultiKaTalkFix Xcode 프로젝트
├── multilinefix-main/           # MultiLineFix Xcode 프로젝트
└── info_diff.txt                # Info.plst 차이점 예시
```

## References

- [MultiKaTalkFix](https://gitlab.com/alias20/MultiKaTalkFix) - dylib 소스 코드
- [optool](https://github.com/alexzielenski/optool) - dylib 주입 도구
- [ldid](https://github.com/ichitaso/ldid) - 엔타이틀먼트 서명 도구

## Disclaimer

이 프로젝트는 교육 목적으로 제공됩니다:
- 이 프로젝트는 해독된 IPA 파일을 제공하지 않습니다
- 사용자는 각 앱의 이용약관을 준수할 책임이 있습니다
- 수정된 앱은 공식 업데이트를 받을 수 없습니다
- 이 프로젝트는 Kakao나 LINE과 관련이 없습니다

## License

이 프로젝트의 원작자는 다음과 같습니다:
- MultiKaTalkFix: [alias20](https://gitlab.com/alias20/MultiKaTalkFix)
- MultiLineFix: [alias20](https://gitlab.com/alias20/multikatalkfix)
