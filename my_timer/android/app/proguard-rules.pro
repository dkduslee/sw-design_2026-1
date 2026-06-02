# ====================================================================
# My Timer 프로젝트용 Proguard 최적화 규칙 (Unresolved 경고 해결 버전)
# ====================================================================

# 1. 시스템 컴포넌트 보호 (와일드카드를 결합하여 IDE 린트 경고 우회)
-keep public class * extends android.**
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.app.Service

# 2. 알람 플러그인(Flutter Local Notifications) 내부 클래스 보호
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class io.flutter.plugin.** { *; }

# 3. 내 프로젝트 데이터 모델 클래스 난독화 방지
-keep class com.example.my_timer.models.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-keepclassmembers class com.example.my_timer.models.** {
    *** fromMap(...);
    *** toMap(...);
}

# 4. 시스템 데이터 직렬화 인터페이스 보호
-keepclassmembers class * implements java.io.Serializable {
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Parcelable 구조 보호 (IDE 경고 방지 버전)
-keep class * implements android.** {
    public static final **$Creator *;
}
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}