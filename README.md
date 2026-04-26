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

### GitHub Actions 사용 가이드

1. **저장소 준비**
   - 이 저장소를 fork하거나 clone합니다.
   - 가능하면 private repository에서 실행하세요. 빌드 결과 IPA가 draft release에 올라갑니다.
   - workflow 파일은 기본 브랜치에 있어야 GitHub UI의 `Run workflow` 버튼이 표시됩니다.

2. **IPA URL 준비**
   - 직접 소유하고 있는 앱에서 추출한 decrypted IPA만 사용하세요.
   - `ipa_url`은 GitHub Actions runner가 바로 다운로드할 수 있는 직접 다운로드 URL이어야 합니다.
   - 로그인, 쿠키, 브라우저 확인이 필요한 공유 링크는 실패할 수 있습니다.
   - URL이 공개 로그나 저장소 기록에 남을 수 있으니 민감한 링크는 짧은 만료 시간을 사용하세요.

3. **워크플로 실행**
   - GitHub 저장소 페이지에서 `Actions` 탭을 엽니다.
   - KakaoTalk은 `Build MultiKaTalk`, LINE은 `Build MultiLine`을 선택합니다.
   - `Run workflow`를 누르고 기본 브랜치를 선택합니다.
   - `ipa_url`, `app_suffix`, `display_name`을 입력한 뒤 실행합니다.

4. **입력값 예시**
   - KakaoTalk: `app_suffix=2`, `display_name=KakaoTalk2`
   - LINE: `app_suffix=2`, `display_name=LINE2`
   - `app_suffix`는 번들 ID 뒤에 붙으므로 숫자와 영문처럼 번들 ID에 안전한 값만 권장합니다.
   - 같은 기기에 여러 개를 설치하려면 suffix를 각각 다르게 지정하세요.

5. **결과 다운로드**
   - 빌드가 끝나면 `Releases`에 draft release가 생성됩니다.
   - release asset에서 `{display_name}.ipa`를 다운로드합니다.
   - Feather, AltStore, SideStore 등 사용하는 installer로 설치합니다.

### MultiKaTalk 빌드

- workflow: `Build MultiKaTalk`
- `ipa_url`: Decrypted KakaoTalk IPA URL
- `app_suffix`: 예시 `2`
- `display_name`: 예시 `KakaoTalk2`

### MultiLine 빌드

- workflow: `Build MultiLine`
- `ipa_url`: Decrypted LINE IPA URL
- `app_suffix`: 예시 `2`
- `display_name`: 예시 `LINE2`

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
- 앱 고유 URL schemes에만 -2 접미사 추가
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
- Info.plist의 CFBundleIdentifier를 기준으로 application-identifier 생성
- 메인 실행 파일은 CFBundleExecutable에서 읽어 정확히 선택
- 주입한 dylib와 번들 내부 Mach-O 파일을 ldid로 재서명
- 기존 _CodeSignature 제거 후 재패킹

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
- 브라우저 전용 공유 링크가 아니라 직접 다운로드 URL인지 확인

### GitHub Actions에서 Run workflow 버튼이 보이지 않음
- workflow 파일이 기본 브랜치에 있는지 확인
- 저장소에 write 권한이 있는 계정으로 접속했는지 확인
- Actions가 저장소 설정에서 비활성화되어 있지 않은지 확인

### 앱이 설치되지 않음
- 엔타이틀먼트 확인
- AltStore/SideStore 버전 확인
- 다른 multi app과 app_suffix가 중복되지 않았는지 확인

### Feather에서 아이콘이 생성되지 않거나 실행되지 않음
- CFBundleIdentifier와 application-identifier가 같은 번들 ID를 기준으로 생성되었는지 확인
- CFBundleExecutable 값이 실제 메인 바이너리 파일명과 일치하는지 확인
- 주입된 Dylibs/*.dylib가 재서명되었는지 확인
- 앱 고유 URL scheme만 변경하고 LSApplicationQueriesSchemes는 원본 값을 유지했는지 확인

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
│   ├── create_entitlements.py   # sideload용 엔타이틀먼트 생성
│   ├── modify_plist.py          # Info.plist 수정 스크립트
│   ├── modify_url_schemes.py    # 앱 고유 URL 스킴 수정 스크립트
│   ├── modify_strings.py        # InfoPlist.strings 수정 스크립트
│   └── sign_macho_bundle.sh     # 번들 내부 Mach-O 재서명
├── multikatalkfix-main/         # MultiKaTalkFix Xcode 프로젝트
└── multilinefix-main/           # MultiLineFix Xcode 프로젝트
```

## References

- [GitHub Actions 수동 실행 가이드](https://docs.github.com/actions/using-workflows/manually-running-a-workflow)
- [MultiKaTalkFix](https://gitlab.com/alias20/multikatalkfix) - 원본 dylib 참고 소스
- [optool](https://github.com/alexzielenski/optool) - dylib 주입 도구
- [ldid Homebrew formula](https://formulae.brew.sh/formula/ldid) - CI에서 사용하는 Mach-O 서명 도구

## Disclaimer

이 프로젝트는 교육 및 개인 연구 목적으로 제공됩니다:
- 이 프로젝트는 해독된 IPA 파일을 제공하지 않습니다
- 사용자는 본인이 합법적으로 보유한 앱에서 추출한 IPA만 사용해야 합니다
- 원본 IPA나 수정된 IPA를 공개 저장소, 공개 release, 파일 공유 서비스에 재배포하지 마세요
- 사용자는 각 앱의 이용약관을 준수할 책임이 있습니다
- 이 방식은 앱, installer, 인증서, iOS 버전 변경에 따라 언제든지 동작하지 않을 수 있습니다
- 계정 제한, 데이터 손실, 알림 미동작, 앱 실행 실패 등 사용 결과에 대한 책임은 사용자에게 있습니다
- 결제, DRM, 지역 제한, 서비스 정책을 우회하거나 스팸/남용 목적으로 사용하지 마세요
- 수정된 앱은 공식 업데이트를 받을 수 없습니다
- 이 프로젝트는 Kakao나 LINE과 관련이 없습니다

## License

이 프로젝트의 원작자는 다음과 같습니다:
- MultiKaTalkFix 참고 소스: [alias20](https://gitlab.com/alias20/multikatalkfix)
- MultiLineFix: 이 저장소에 포함된 local adaptation
