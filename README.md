# My_timer ⏱️


> My_timer는 교대 근무자들을 위한 일정 연동형 알람 서비스입니다. 사용자들은 자신의 업무스케줄을 등록하고, 그에 맞는 알람 시간을 초기에 설정해두면, 이후 캘린더에 등록만 해두어도 알람이 연동되어 혹시 모를 지각에 대비할 수 있습니다.

- conceptualization 완료
- Analysis 완료
- Design 완료
- 구현 완료

---

## 📁 프로젝트 구조

```
lib/
├── main.dart                        # 앱 진입점 · 권한 요청 · Provider 설정
├── models/
│   ├── shift_type.dart              # ShiftType 열거형 (주간/야간/비번/휴무)
│   ├── shift_schedule.dart          # ShiftSchedule 데이터 모델
│   ├── alarm_setting.dart           # AlarmSetting 데이터 모델
│   └── app_settings.dart            # AppSettings (SharedPreferences 래핑)
├── services/
│   ├── schedule_manager.dart        # SQLite CRUD (sqflite)
│   ├── alarm_manager.dart           # OS 알람 등록/취소 (flutter_local_notifications)
│   ├── calendar_manager.dart        # 기기 캘린더 연동 (device_calendar)
│   ├── sync_service.dart            # 알람·캘린더 동기화 조율 + 롤백
│   ├── settings_service.dart        # 앱 설정 저장·로드 (ChangeNotifier)
│   └── schedule_provider.dart       # 스케줄 상태 관리 (ChangeNotifier)
├── screens/
│   ├── home_screen.dart             # 하단 네비게이션 진입점
│   ├── calendar_screen.dart         # 메인 캘린더 화면
│   ├── alarm_list_screen.dart       # 알람 목록 화면
│   └── settings_screen.dart         # 설정 화면
└── widgets/
    ├── shift_dialog.dart            # 근무 유형 선택 다이얼로그
    └── repeat_pattern_dialog.dart   # 반복 패턴 설정 다이얼로그
```

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
