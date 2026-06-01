import '../models/news_article.dart';

const sampleDailyNews = DailyNewsDocument(
  date: '2026-05-31',
  articles: [
    NewsArticle(
      title: '삼성전자·SK하이닉스 랠리와 AI 이벤트 기대',
      sector: '반도체',
      source: '네이버페이 증권',
      publishedAt: '2026.05.31 19:40',
      isHeadline: true,
      clusterCount: 4,
      issueKeyword: '삼성전자 SK하이닉스',
      url:
          'https://finance.naver.com/news/news_read.naver?article_id=0002650314&office_id=016&mode=mainnews&type=&date=2026-05-31&page=1',
      whatHappened:
          '코스피는 8476.15로 마감했고 주간 기준 7.71% 상승했다. 반면 코스닥은 7.68% 하락했다. 삼성전자와 SK하이닉스의 코스피 내 시가총액 비중은 52%까지 확대됐고, 글로벌 AI 이벤트와 HBM 기대가 투자심리를 자극했다.',
      context:
          '삼성전자 노사 잠정합의, 마이크론 목표주가 상향, 단일종목 레버리지 ETF 상장 이후 대형 반도체주로 자금이 급격히 집중됐다. GTC 타이베이, 컴퓨텍스, MS 빌드 등 AI 인프라 이벤트가 연이어 예정돼 있다.',
      implication:
          'HBM, 메모리, AI 인프라 공급망에는 우호적이다. 다만 지수 상승이 일부 대형주에 과도하게 의존하고 있어 반도체 이벤트 기대가 꺾일 경우 코스피 변동성이 커질 수 있다.',
    ),
    NewsArticle(
      title: '한국 수출 9000억달러 전망, 1조달러 도전',
      sector: '수출',
      source: '네이버페이 증권',
      publishedAt: '2026.05.31 20:14',
      url:
          'https://finance.naver.com/news/news_read.naver?article_id=0001951669&office_id=057&mode=mainnews&type=&date=2026-05-31&page=1',
      whatHappened:
          '산업연구원은 올해 한국 수출이 전년 대비 30% 늘어 9000억달러를 넘길 것으로 전망했다. 1분기 반도체 수출은 전년 동기 대비 139% 증가한 반면 자동차는 0.3% 감소했다.',
      context:
          'AI 데이터센터 확대로 반도체와 전력기기 수요가 동시에 늘고 있다. 미국 노후 전력망 교체 수요까지 겹치며 변압기 등 전력장비 주문이 장기화되고 있다.',
      implication:
          '반도체, 전력기기, 전력망, ESS 관련 기업에는 구조적 수혜가 예상된다. 자동차처럼 수출 모멘텀이 약한 업종은 상대적으로 소외될 수 있어 업종별 선별이 중요하다.',
    ),
    NewsArticle(
      title: '델, AI 서버 수요 폭증으로 실적 서프라이즈',
      sector: 'AI 서버',
      source: '매일경제',
      publishedAt: '2026.05.31 17:17',
      url: 'https://www.mk.co.kr/news/stock/12062251',
      whatHappened:
          '델의 1분기 매출은 438억달러로 전년 대비 88% 증가했고 조정 EPS는 4.86달러로 214% 늘었다. AI 서버 매출은 161억달러로 757% 급증했으며 수주잔액은 513억달러에 달했다.',
      context:
          '글로벌 빅테크의 AI 인프라 지출 확대가 서버와 데이터센터 장비 수요를 밀어 올리고 있다. 델은 엔비디아 GPU 기반 AI 서버 고객을 5000곳 이상 확보한 것으로 알려졌다.',
      implication:
          'AI 서버 투자는 한국 HBM, 메모리, PCB, 전력장비 공급망에 긍정적이다. 서버 투자 사이클이 유지되면 국내 반도체 장비와 소재 기업까지 수혜가 확산될 가능성이 있다.',
    ),
    NewsArticle(
      title: '중국 첨단기업 IPO 러시와 반도체 자립 가속',
      sector: '중국 반도체',
      source: '매일경제',
      publishedAt: '2026.05.31 17:17',
      url: 'https://www.mk.co.kr/news/it/12062250',
      whatHappened:
          'CXMT, YMTC, 유니트리 등 중국 첨단기업들이 커촹반 상장을 추진하고 있다. 조달 자금은 HBM, 로봇, AI 인프라 R&D에 투입될 전망이다.',
      context:
          '미국 수출 규제에도 중국은 국가 펀드와 내수 시장을 기반으로 반도체 공정 국산화와 로봇 양산 역량을 키워왔다. 중국 빅테크의 자국 공급망 선호도 강화되고 있다.',
      implication:
          '단기적으로는 한국 메모리 기업의 기술 우위가 유지될 가능성이 크지만, 중국의 자금력과 물량 공세는 중장기 경쟁 압력이다. 국내 반도체와 로봇 밸류체인은 기술 격차와 고객 다변화가 중요하다.',
    ),
    NewsArticle(
      title: '스페이스X 초대형 IPO 전망',
      sector: '우주',
      source: '네이버페이 증권',
      publishedAt: '2026.05.31 22:41',
      url:
          'https://finance.naver.com/news/news_read.naver?article_id=0002650340&office_id=016&mode=mainnews&type=&date=2026-05-31&page=1',
      whatHappened:
          '스페이스X가 나스닥 상장을 추진하며 예상 기업가치는 최대 1조8000억달러, 공모 규모는 최대 750억달러로 제시됐다. 스타링크 매출은 전년 대비 49.9% 증가했다.',
      context:
          '스타링크가 현금창출원으로 부상했고 민간 우주산업의 상업화가 빨라지고 있다. 상장 후 나스닥100 빠른 편입 가능성도 언급됐다.',
      implication:
          '대형 IPO는 글로벌 증시 유동성을 흡수하는 이벤트가 될 수 있다. 동시에 국내 우주, 위성통신, 방산 관련 테마에는 투자심리 개선 요인으로 작용할 수 있다.',
    ),
    NewsArticle(
      title: '한국 코인시장 거래규모, 코스피의 50분의 1',
      sector: '가상자산',
      source: '매일경제',
      publishedAt: '2026.05.31 13:27',
      url: 'https://www.mk.co.kr/news/stock/12062068',
      whatHappened:
          '국내 5대 거래소 거래대금은 2조7130억원으로 코스피 거래대금 118조2670억원의 2.03% 수준이다. 지난해 7월 대비 코인 거래대금은 83.96% 급감했다.',
      context:
          '삼성전자와 SK하이닉스 중심의 코스피 랠리가 투자자 관심과 유동성을 흡수하고 있다. 반면 비트코인 관심도는 삼성전자 대비 8분의 1 수준으로 낮아졌다.',
      implication:
          '위험자금이 코인에서 주식시장으로 이동하는 흐름이다. 가상자산 거래소와 관련 지분 투자 매력은 약화될 수 있고, 증권사와 주식 거래 플랫폼의 상대적 수혜가 커질 수 있다.',
    ),
    NewsArticle(
      title: '반도체 빚투와 금리인상 경고',
      sector: '금리 리스크',
      source: '한국경제',
      publishedAt: '2026.05.31 14:21',
      url: 'https://www.hankyung.com/article/2026052968886',
      whatHappened:
          '한국은행은 기준금리를 2.50%로 동결했지만 연내 인상 필요성을 시사했다. 금통위원 21명 중 10명은 연말 적정금리로 3.0%를 제시했다.',
      context:
          '코스피는 AI와 반도체 모멘텀으로 사상 최고치 흐름을 이어가고 있지만 반도체 종목에 대한 빚투가 크게 늘었다. 금리 인상은 레버리지 투자 부담을 키우는 변수다.',
      implication:
          '반도체 실적 기대가 강하더라도 금리 상승과 신용융자 부담이 맞물리면 조정 시 낙폭이 커질 수 있다. 지수 추종보다 리스크 관리와 분할 접근이 필요하다.',
    ),
  ],
);
