# Leyden crash

When:
* running an app with the https://github.com/openjdk/leyden/tree/premain
* FlightRecorder was enabled for the aotconf creation
* FlightRecorder was disabled for the aotcache creation
* FlightRecorder is enabled for the production run
Then the app crashes with a segmentation fault.

This repo reproduces the issue with a simple Spring Boot app. I couldn't reproduce with a simple `main()`.
```
💣 Program crashed: Bad pointer dereference at 0x0000000000000000

Thread 2 crashed:

 0 0x0000000000000000
 1 0x00000001139d4820
 2 0x00000001139d4a90
 3 0x00000001139d4820
 4 0x00000001139d4820
 5 0x00000001139d4820
 6 0x00000001139d4820
 7 0x00000001139d4a90
 8 0x00000001139d4a90
 9 0x00000001139d4820
10 0x00000001139d4a90
11 0x00000001139d4a90
12 0x00000001139d0154
13 JavaCalls::call_helper(JavaValue*, methodHandle const&, JavaCallArguments*, JavaThread*) + 988 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaCalls.cpp:415:7
14 JavaCalls::call(JavaValue*, methodHandle const&, JavaCallArguments*, JavaThread*) + 28 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaCalls.cpp:323:3
15 JavaCalls::call_virtual(JavaValue*, Klass*, Symbol*, Symbol*, JavaCallArguments*, JavaThread*) + 356 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaCalls.cpp:179:3
16 JfrJavaCall::call_virtual(JfrJavaArguments*, JavaThread*) + 224 in libjvm.dylib at make/hotspot/src/hotspot/share/jfr/jni/jfrJavaCall.cpp:374:3
17 JfrDCmd::invoke(JfrJavaArguments&, JavaThread*) const + 288 in libjvm.dylib at make/hotspot/src/hotspot/share/jfr/dcmd/jfrDcmds.cpp:207:3
18 JfrDCmd::execute(DCmdSource, JavaThread*) + 456 in libjvm.dylib at make/hotspot/src/hotspot/share/jfr/dcmd/jfrDcmds.cpp:244:3
19 launch_recording(JfrStartFlightRecordingDCmd*, JavaThread*) + 40 in libjvm.dylib at make/hotspot/src/hotspot/share/jfr/recorder/jfrRecorder.cpp:164:19
20 launch_command_line_recordings(JavaThread*) + 132 in libjvm.dylib at make/hotspot/src/hotspot/share/jfr/recorder/jfrRecorder.cpp:180:12
21 JfrRecorder::on_create_vm_3() + 252 in libjvm.dylib at make/hotspot/src/hotspot/share/jfr/recorder/jfrRecorder.cpp:241:45
22 Jfr::on_create_vm_3() + 12 in libjvm.dylib at make/hotspot/src/hotspot/share/jfr/jfr.cpp:63:8
23 Threads::create_vm(JavaVMInitArgs*, bool*) + 1904 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/threads.cpp:897:3
24 JNI_CreateJavaVM_inner(JavaVM_**, void**, void*) + 80 in libjvm.dylib at make/hotspot/src/hotspot/share/prims/jni.cpp:3587:12
25 JNI_CreateJavaVM + 116 in libjvm.dylib at make/hotspot/src/hotspot/share/prims/jni.cpp:3678:14
26 InitializeJVM + 184 in libjli.dylib at make/src/java.base/share/native/libjli/java.c:1510:9
27 JavaMain + 256 in libjli.dylib at make/src/java.base/share/native/libjli/java.c:494:10
28 ThreadJavaMain + 12 in libjli.dylib at make/src/java.base/macosx/native/libjli/java_md_macosx.m:679:29
29 0x0000000197d71c0c _pthread_start + 136 in libsystem_pthread.dylib
```

## Steps to reproduce

Run `build.sh` to build the Spring Boot app and extract the jar according to https://docs.spring.io/spring-boot/reference/packaging/class-data-sharing.html

Run `run.sh` to create the AOT cache file and run the app with it, triggering the segfault.

## Additional observations

Initially the crash was triggered in a real large app by Spring Boot's BackgroundPreinitializer, but if disabled with system property `-Dspring.backgroundpreinitializer.ignore=false`,
I still had the crash in a jfr thread, I reproduce the backtraces hereafter:

Crash in BackgroundPreinitializer (full stack, I did not truncate after 0x000000011959e938):
```
💣 Program crashed: Bad pointer dereference at 0x0000000000000000

Thread 25 "Java: background-preinit" crashed:

0 0x0000000000000000
1 0x0000000118ff0a90
2 0x0000000118ff0a90
3 0x0000000118ff0a90
4 0x0000000118ff0a90
5 0x000000011959e938
```

Crash in jfr:
```
💣 Program crashed: Bad pointer dereference at 0x0000000000000000

Thread 21 "Java: JFR Periodic Tasks" crashed:

 0 0x0000000000000000
 1 0x0000000141fa4a90
 2 0x0000000141fa4a90
 3 0x0000000141fa4a90
 4 0x0000000141fa4a90
 5 0x0000000141fa4a90
 6 0x0000000141fa5030
 7 0x0000000141fa4a90
 8 0x0000000141fa0154
 9 JavaCalls::call_helper(JavaValue*, methodHandle const&, JavaCallArguments*, JavaThread*) + 988 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaCalls.cpp:415:7
10 JavaCalls::call(JavaValue*, methodHandle const&, JavaCallArguments*, JavaThread*) + 28 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaCalls.cpp:323:3
11 JavaCalls::call_virtual(JavaValue*, Klass*, Symbol*, Symbol*, JavaCallArguments*, JavaThread*) + 356 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaCalls.cpp:179:3
12 JavaCalls::call_virtual(JavaValue*, Handle, Klass*, Symbol*, Symbol*, JavaThread*) + 100 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaCalls.cpp:185:3
13 thread_entry(JavaThread*, JavaThread*) + 164 in libjvm.dylib at make/hotspot/src/hotspot/share/prims/jvm.cpp:2763:3
14 JavaThread::thread_main_inner() + 164 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaThread.cpp:774:5
15 Thread::call_run() + 200 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/thread.cpp:242:9
16 thread_native_entry(Thread*) + 420 in libjvm.dylib at make/hotspot/src/hotspot/os/bsd/os_bsd.cpp:601:11
17 0x0000000197d71c0c _pthread_start + 136 in libsystem_pthread.dylib
```
