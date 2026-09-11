# Connected Car (현대 / 기아) 연동 — 보류

**결론: 지금 구조로는 안전하게 구현할 수 없다. Slice 7 을 중단하고 수동 주행거리 입력을
제대로 만드는 쪽으로 대체했다.**

핸드오프 문서 §17 과 §19 의 지시에 따른다.

> If a secure integration requires a backend, stop that Slice and document the reason
> before introducing backend infrastructure.

조사일: 2026-09-12

## 확인한 것

### 1. 공식 API 는 Client Secret 을 쓴다

Hyundai Developers / KIA Developers 에서 프로젝트를 등록하면 **Client ID 와 Client
Secret** 이 발급되고, 이 둘로 계정 연결과 차량 데이터 API 를 호출한다. 토큰 교환은
`grant_type=authorization_code` 에 `client_id`, `client_secret`, `code`,
`redirect_uri` 를 함께 보내는 전형적인 confidential client 흐름이다.

### 2. Public client / PKCE 지원 근거를 찾지 못했다

공개된 문서 범위에서 PKCE(`code_challenge` / `code_verifier`)나 secret 없는 native
app 흐름에 대한 언급을 찾지 못했다. 상세 규격 페이지는 계정 로그인 뒤에야 전부 보이는
구조라 **"지원하지 않는다"고 단정할 수는 없지만, "지원한다"는 근거도 없다.**

핸드오프 문서의 규칙은 이 상황을 이미 정하고 있다 — *Do not guess authentication
behavior.* 근거 없이 public client 를 가정하고 만들 수는 없다.

### 3. 모바일 앱에 Client Secret 을 넣을 수 없다

APK 든 IPA 든 바이너리는 뜯어볼 수 있다. 문자열 난독화는 시간을 벌 뿐이다. Secret 이
유출되면 우리 서비스 이름으로 남의 차량 데이터에 접근하는 통로가 된다.

### 4. 상용 이용에는 별도 심사가 있다

개발 프로젝트로 시험한 뒤 **상용화 신청 → 심사 → 상용 프로젝트 발급** 을 거쳐야 실제
사용자에게 서비스할 수 있다. 개인 개발자가 심사를 통과할 수 있는지는 공개 문서에
명시돼 있지 않다.

## 그래서 선택지는

1. **Backend 를 둔다.** Client Secret 을 서버에 두고 앱은 우리 서버와만 이야기한다.
   안전하지만 "자체 Backend 없음" 원칙이 깨지고, 서버 운영·개인정보 처리·비용이 따라온다.
   사용자 차량 데이터가 우리 서버를 통과하게 되는 것도 별개의 결정이다.
2. **PKCE 지원 여부를 공식 채널로 확인한다.** `developers@hyundai.com` 에 문의해
   secret 없이 native app 에서 쓸 수 있는 흐름이 있는지 묻는다. 있다면 1번 없이 간다.
3. **연동을 포기하고 수동 입력을 잘 만든다.** ← **지금 선택**

## 지금 한 것

3번을 골랐다. 주행거리 자동 연동은 있으면 좋은 편의지, 이 앱의 핵심 가치("정비 이력을
빠르게 기록하고 확인")가 아니다. 없다고 해서 앱이 못 쓰게 되지 않는다.

대신 수동 입력이 방치되지 않게 했다:

- 차량 화면에 **연동 상태**를 정직하게 표시한다. "지원 예정"이라고 하지 않고, 지금은
  수동 입력이며 왜 그런지 볼 수 있게 한다.
- 주행거리가 오래됐으면 홈에서 **업데이트를 제안**한다. 주행거리가 낡으면 "다음 교체까지
  N km" 가 조용히 틀려지는데, 사용자는 그걸 알 방법이 없다.

## 다시 열어야 할 때

- 공식 채널에서 PKCE / public client 지원을 확인했을 때
- Backend 를 두기로 결정했을 때 (그 자체가 별도 논의)
- 상용화 심사 통과 가능성이 확인됐을 때

그때 이 문서를 갱신하고 Slice 7 을 다시 연다. 데이터 모델에는 이미 자리가 있다
(`Vehicle.integrationType`, `integrationVehicleId` 는 아직 추가하지 않았다 — 쓰이지 않는
컬럼을 미리 만들지 않는다).
