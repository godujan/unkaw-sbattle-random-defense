# 운의전쟁 v1.5.1 — 랭킹 연동 설정

미리보기: https://godujan.github.io/unkaw-sbattle-random-defense/preview/v1.5.1/

- 현재 **v1.4 정식 게임 주소는 그대로 유지**합니다.
- 시즌 랭킹: 한국시간 기준 14일 주기 (2026-11-06 시작), 각 계정 최고 노멀 점수로 상위 100명
- 오늘 랭킹: 한국시간 기준 오늘 최고 점수로 상위 100명
- 내 기록: 로그인한 계정의 온라인 기록과 로컬 기록 표시
- 노멀 도전을 완료하거나 실패하면 로그인 계정의 기록이 서버로 전송됩니다.
- 서버 미연결 시 가짜 순위를 표시하지 않습니다.

## Supabase 연결 순서

1. https://supabase.com/ 에 가입해 프로젝트를 만듭니다.
2. Supabase **SQL Editor**에서 `supabase-schema.sql`을 실행해 프로필을 생성합니다.
3. 이어 `supabase-leaderboard.sql`을 실행해 기록 테이블/RLS/랭킹 RPC를 생성합니다.
4. Supabase **Connect**에서 Project URL과 **Publishable key**(`sb_publishable_...`)를 확인합니다.
5. 이 저장소 루트의 `auth-config.js`에서 빈 값을 아래와 같이 교체합니다.

```js
window.GAME_AUTH_CONFIG = {
  SUPABASE_URL: 'https://YOUR-PROJECT.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_YOUR_PUBLIC_KEY'
};
```

`SUPABASE_ANON_KEY`는 구형 게임의 필드명이며 **새 Publishable key 값**을 넣어도 됩니다.
`service_role`, `sb_secret_...` 등 비밀키를 공개 GitHub 저장소에 넣지 마세요.

6. **Supabase → Authentication → URL Configuration**
   - Site URL: `https://godujan.github.io/unkaw-sbattle-random-defense/`
   - Additional Redirect URL: `https://godujan.github.io/unkaw-sbattle-random-defense/preview/v1.5.1/`
7. **Authentication → Providers → Email** 활성화.
8. v1.5.1 페이지에서 이메일 링크로 로그인 후 노멀 게임을 진행해 시즌·오늘·내 기록을 확인합니다.

### 주의
이 랭킹은 베타입니다. 인증된 사용자만 자기 기록을 등록하고 SQL에서 점수식/웨이브 범위를 점검하지만 **클라이언트에서 계산한 기록이므로 완전한 부정행위 방지는 아닙니다**. 상금이나 정식 경쟁에는 서버에서 게임 결과 검증이 필요합니다.
