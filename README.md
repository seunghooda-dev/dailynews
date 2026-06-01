# Dailynews

한국 시장 전용 경제 뉴스 수집, AI 구조화 요약, Firestore 적재, Flutter 모바일 대시보드를 한 레포에서 관리합니다.

## Backend Pipeline

크롤러는 네이버페이 증권, 매일경제, 한국경제의 증권/금융 섹션을 대상으로 동작합니다. 키워드 필터는 코드에 고정하지 않고 JSON 설정으로 주입합니다.

```bash
py -3 -m pip install -r requirements.txt
copy .env.example .env
$env:LLM_API_KEY="..."
$env:FIREBASE_CREDENTIALS_PATH="C:\path\to\serviceAccountKey.json"
py -3 scripts/check_env.py
py -3 main.py --filter-config filter.example.json
```

필수 환경 변수:

- `LLM_API_KEY`: OpenAI 호환 Chat Completions API 키
- `FIREBASE_CREDENTIALS_PATH`: Firebase 서비스 계정 JSON 경로

선택 환경 변수:

- `LLM_MODEL`: 기본값 `gpt-4o-mini`
- `LLM_BASE_URL`: 기본값 `https://api.openai.com/v1`
- `ARTICLE_LIMIT_PER_SOURCE`: 매체별 수집 기사 수, 기본값 `8`
- `REQUEST_TIMEOUT_SECONDS`: 크롤링 요청 타임아웃, 기본값 `20`
- `LLM_TIMEOUT_SECONDS`: LLM 요청 타임아웃, 기본값 `60`
- `MAX_LLM_RETRIES`: LLM 재시도 횟수, 기본값 `4`

Firestore 저장 경로는 `korea_economy_news/{YYYY-MM-DD}`이며, 문서 안의 `articles` 배열에 중복 URL을 제외하고 병합됩니다.

Firebase Admin SDK에서 보이는 `client_email` 값만으로는 인증할 수 없습니다. 로컬 실행에는 서비스 계정 JSON 전체 파일이 필요하고, GitHub Actions에는 같은 JSON 전체 문자열을 Secret으로 넣어야 합니다.

키 없이 로컬 기사 카드만 확인하려면 오늘자 스냅샷을 만들고 정적 웹 서버를 띄웁니다. 이 스크립트는 한국 시장용 `web/news_snapshot.json`과 월드 시장용 `web/world_news_snapshot.json`을 함께 갱신합니다.

```powershell
.\scripts\refresh_news.ps1
```

## Flutter App

앱은 Firestore의 지정 날짜 문서를 읽어 선택형 뉴스 카드와 상세 분석 패널로 렌더링합니다. Firebase 설정이 없으면 로컬 샘플 데이터로 먼저 실행됩니다.
상단의 `Korea Market` / `World Market` 토글로 한국 경제 뉴스와 Google News/Yahoo Finance 기반 월드 마켓 뉴스를 전환할 수 있습니다. 월드 마켓 스냅샷은 생성 시점에 기사 제목과 핵심 요약을 한국어로 자동 번역해 저장합니다.

```bash
flutter pub get
flutter run
```

인앱 브라우저에서 흰 화면이 보이면 Flutter dev-server 대신 CDN 의존성이 없는 정적 빌드를 서빙합니다.

```powershell
.\scripts\serve_web.ps1
```

Firebase를 붙여 실행할 때는 `flutterfire configure`로 클라이언트 설정 파일을 생성한 뒤 아래처럼 실행합니다.

```bash
flutter run --dart-define=USE_FIREBASE=true
```

Flutter 앱에는 Firebase Admin SDK JSON을 넣지 않습니다. 앱에서 Firestore를 직접 읽게 할 때 필요한 것은 `flutterfire configure`가 생성하는 클라이언트 설정(`lib/firebase_options.dart`)이며, 이 값은 Admin 비밀키와 다른 종류입니다.

## GitHub Actions

`.github/workflows/daily_news.yml`는 매일 06:00 KST에 실행됩니다. GitHub Secrets에 아래 값을 등록해야 합니다.

- `LLM_API_KEY`
- `FIREBASE_CREDENTIALS_JSON`: Firebase 서비스 계정 JSON 전체 문자열

수동 실행은 GitHub Actions의 `workflow_dispatch`로 가능합니다.
