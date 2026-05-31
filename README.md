# Dailynews

한국 시장 전용 경제 뉴스 수집, AI 구조화 요약, Firestore 적재, Flutter 모바일 대시보드를 한 레포에서 관리합니다.

## Backend Pipeline

크롤러는 네이버페이 증권, 매일경제, 한국경제의 증권/금융 섹션을 대상으로 동작합니다. 키워드 필터는 코드에 고정하지 않고 JSON 설정으로 주입합니다.

```bash
py -3 -m pip install -r requirements.txt
$env:LLM_API_KEY="..."
$env:FIREBASE_CREDENTIALS_PATH="C:\path\to\serviceAccountKey.json"
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

Firestore 저장 경로는 `korea_economy_news/{YYYY-MM-DD}`이며, 문서 안의 `articles` 배열에 중복 URL을 제외하고 병합됩니다.

## Flutter App

앱은 Firestore의 지정 날짜 문서를 읽어 선택형 뉴스 카드와 상세 분석 패널로 렌더링합니다. Firebase 설정이 없으면 로컬 샘플 데이터로 먼저 실행됩니다.

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

## GitHub Actions

`.github/workflows/daily_news.yml`는 매일 08:00 KST에 실행됩니다. GitHub Secrets에 아래 값을 등록해야 합니다.

- `LLM_API_KEY`
- `FIREBASE_CREDENTIALS_JSON`: Firebase 서비스 계정 JSON 전체 문자열

수동 실행은 GitHub Actions의 `workflow_dispatch`로 가능합니다.
