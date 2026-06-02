# My_timer ⏱️


> My_timer는 교대 근무자들을 위한 일정 연동형 알람 서비스입니다. 사용자들은 자신의 업무스케줄을 등록하고, 그에 맞는 알람 시간을 초기에 설정해두면, 이후 캘린더에 등록만 해두어도 알람이 연동되어 혹시 모를 지각에 대비할 수 있습니다.

- conceptualization 완료
- Analysis 완료
- Design 완료
- 구현 완료

---

## Android 권한 (AndroidManifest.xml)

| 권한 | 용도 |
|------|------|
| `POST_NOTIFICATIONS` | 알림 표시 (Android 13+) |
| `SCHEDULE_EXACT_ALARM` | 정확한 시간 알람 (Android 12+) |
| `RECEIVE_BOOT_COMPLETED` | 재부팅 후 알람 복원 |
| `READ_CALENDAR` / `WRITE_CALENDAR` | 기기 캘린더 접근 |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | 배터리 절약 모드 예외 |

---

## 주요 기능

- **근무 유형 등록** : 날짜를 탭 → 주간/야간/비번/휴무 선택 → 자동 알람 설정
- **반복 패턴** : 주야비휴 등 패턴을 설정하면 이후 날짜 자동 입력 (최대 12주)
- **알람 목록** : 등록된 알람 확인, 시간 수동 수정, on/off 토글
- **캘린더 동기화** : 기기 캘린더에 근무 이벤트 자동 등록/갱신/삭제
- **설정** : 근무별 기본 알람 시간, 선행 시간(15/30/60분), 소리/진동, 캘린더 연동

---

## 주의사항

- **Android 전용** 앱입니다. iOS는 지원하지 않습니다.
- `device_calendar` 패키지는 Android 의 `CalendarProvider` API를 사용합니다.
- Android 12 이상에서 `SCHEDULE_EXACT_ALARM` 권한이 거부되면  
  근사치(inexact) 알람으로 자동 대체됩니다.
- 배터리 최적화 설정에 따라 알람이 지연될 수 있으니  
  앱의 배터리 최적화를 **제외(예외 등록)** 해 주세요.
