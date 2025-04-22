# Leyden crash

When running a (private) app with the https://github.com/openjdk/leyden/tree/premain, the app crashes with a segmentation fault.

This repo reproduces the issue with a simple Spring Boot app.

## Steps to reproduce

Run `build.sh` to build the Spring Boot app and https://docs.spring.io/spring-boot/reference/packaging/class-data-sharing.html

Run `run.sh` to create the AOT cache file and run the app with it, triggering the segfault.

## Observations

* During the aotconf creation, bouncy castle classes are excluded because they are from a signed jar.
```
Skipping org/bouncycastle/jcajce/provider/asymmetric/util/BaseKeyFactorySpi: Signed JAR
```

* There are a lot of warnings during the AOT cache creation, it may be related to the crash.
```
[1,064s][warning][cds,heap] Archive heap points to a static field that may hold a different value at runtime:
[1,064s][warning][cds,heap] Field: sun/security/x509/AlgorithmId::SHA3_512withRSA_oid
[1,064s][warning][cds,heap] Value: sun.security.util.ObjectIdentifier
[1,064s][warning][cds,heap] {0x00000006000453b8} - klass: 'sun/security/util/ObjectIdentifier' - flags:
[1,064s][warning][cds,heap]
[1,064s][warning][cds,heap]  - ---- fields (total size 4 words):
[1,064s][warning][cds,heap]  - private 'componentLen' 'I' @12  -1 (0xffffffff)
[1,064s][warning][cds,heap]  - private transient 'componentsCalculated' 'Z' @16  false (0x00)
[1,064s][warning][cds,heap]  - private 'encoding' '[B' @20  [B{0x00000006000453d8} (0xc0008a7b)
[1,064s][warning][cds,heap]  - private volatile transient 'stringForm' 'Ljava/lang/String;' @24  "2.16.840.1.101.3.4.3.16"{0x0000000600045378} (0xc0008a6f)
[1,064s][warning][cds,heap]  - private 'components' 'Ljava/lang/Object;' @28  null (0x00000000)
[1,064s][warning][cds,heap] --- trace begin ---
[1,064s][warning][cds,heap] [ 0] {0x0000000600043330} java.util.concurrent.ConcurrentHashMap::table (offset = 20)
[1,064s][warning][cds,heap] [ 1] {0x0000000600043370} [Ljava.util.concurrent.ConcurrentHashMap$Node; @[87]
[1,064s][warning][cds,heap] [ 2] {0x0000000600045358} java.util.concurrent.ConcurrentHashMap$Node::val (offset = 20)
[1,064s][warning][cds,heap] [ 3] {0x00000006000453b8} sun.security.util.ObjectIdentifier
[1,064s][warning][cds,heap] --- trace end ---
```

* Sample Backtrace from the segfault:
```
💣 Program crashed: Bad pointer dereference at 0x0000000000000000

Thread 2 crashed:

 0 0x0000000000000000
 1 0x00000001132b5230
 2 0x00000001132b0154
 3 JavaCalls::call_helper(JavaValue*, methodHandle const&, JavaCallArguments*, JavaThread*) + 988 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaCalls.cpp:415:7
 4 InstanceKlass::call_class_initializer(JavaThread*) + 764 in libjvm.dylib at make/hotspot/src/hotspot/share/oops/instanceKlass.cpp:1777:5
 5 InstanceKlass::initialize_impl(JavaThread*) + 2748 in libjvm.dylib at make/hotspot/src/hotspot/share/oops/instanceKlass.cpp:1331:7
 6 InstanceKlass::initialize_impl(JavaThread*) + 1540 in libjvm.dylib at make/hotspot/src/hotspot/share/oops/instanceKlass.cpp:1292:20
 7 HeapShared::resolve_or_init_classes_for_subgraph_of(Klass*, bool, JavaThread*) + 900 in libjvm.dylib at make/hotspot/src/hotspot/share/cds/heapShared.cpp:1491:9
 8 HeapShared::initialize_from_archived_subgraph(JavaThread*, Klass*) + 336 in libjvm.dylib at make/hotspot/src/hotspot/share/cds/heapShared.cpp:1415:5
 9 JVM_InitializeFromArchive + 560 in libjvm.dylib at make/hotspot/src/hotspot/share/prims/jvm.cpp:3369:3
10 0x00000001132b8e80
11 0x00000001132b4a90
12 0x00000001132b0154
13 JavaCalls::call_helper(JavaValue*, methodHandle const&, JavaCallArguments*, JavaThread*) + 988 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaCalls.cpp:415:7
14 InstanceKlass::call_class_initializer(JavaThread*) + 764 in libjvm.dylib at make/hotspot/src/hotspot/share/oops/instanceKlass.cpp:1777:5
15 InstanceKlass::initialize_impl(JavaThread*) + 2748 in libjvm.dylib at make/hotspot/src/hotspot/share/oops/instanceKlass.cpp:1331:7
16 LinkResolver::resolve_static_call(CallInfo&, LinkInfo const&, bool, JavaThread*) + 152 in libjvm.dylib at make/hotspot/src/hotspot/share/interpreter/linkResolver.cpp:1116:21
17 LinkResolver::resolve_invokestatic(CallInfo&, constantPoolHandle const&, int, JavaThread*) + 52 in libjvm.dylib at make/hotspot/src/hotspot/share/interpreter/linkResolver.cpp:1749:3
18 LinkResolver::resolve_invoke(CallInfo&, Handle, constantPoolHandle const&, int, Bytecodes::Code, JavaThread*) + 116 in libjvm.dylib at make/hotspot/src/hotspot/share/interpreter/linkResolver.cpp:1708:39
19 InterpreterRuntime::resolve_invoke(JavaThread*, Bytecodes::Code) + 748 in libjvm.dylib at make/hotspot/src/hotspot/share/interpreter/interpreterRuntime.cpp:988:5
20 InterpreterRuntime::resolve_invokestatic(JavaThread*) + 420 in libjvm.dylib at make/hotspot/src/hotspot/share/interpreter/interpreterRuntime.cpp:952:3
21 InterpreterRuntime::resolve_from_cache(JavaThread*, Bytecodes::Code) + 2644 in libjvm.dylib at make/hotspot/src/hotspot/share/interpreter/interpreterRuntime.cpp:1167:37
22 0x00000001132c48c4
23 0x00000001132b0154
24 JavaCalls::call_helper(JavaValue*, methodHandle const&, JavaCallArguments*, JavaThread*) + 988 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/javaCalls.cpp:415:7
25 InstanceKlass::call_class_initializer(JavaThread*) + 764 in libjvm.dylib at make/hotspot/src/hotspot/share/oops/instanceKlass.cpp:1777:5
26 InstanceKlass::initialize_impl(JavaThread*) + 2748 in libjvm.dylib at make/hotspot/src/hotspot/share/oops/instanceKlass.cpp:1331:7
27 InstanceKlass::initialize_impl(JavaThread*) + 1540 in libjvm.dylib at make/hotspot/src/hotspot/share/oops/instanceKlass.cpp:1292:20
28 HeapShared::init_classes_for_special_subgraph(Handle, JavaThread*) + 356 in libjvm.dylib at make/hotspot/src/hotspot/share/cds/heapShared.cpp:1387:13
29 Threads::create_vm(JavaVMInitArgs*, bool*) + 1504 in libjvm.dylib at make/hotspot/src/hotspot/share/runtime/threads.cpp:808:5
30 JNI_CreateJavaVM_inner(JavaVM_**, void**, void*) + 80 in libjvm.dylib at make/hotspot/src/hotspot/share/prims/jni.cpp:3587:12
31 JNI_CreateJavaVM + 116 in libjvm.dylib at make/hotspot/src/hotspot/share/prims/jni.cpp:3678:14
32 InitializeJVM + 184 in libjli.dylib at make/src/java.base/share/native/libjli/java.c:1510:9
33 JavaMain + 256 in libjli.dylib at make/src/java.base/share/native/libjli/java.c:494:10
34 ThreadJavaMain + 12 in libjli.dylib at make/src/java.base/macosx/native/libjli/java_md_macosx.m:679:29
35 0x0000000197d71c0c _pthread_start + 136 in libsystem_pthread.dylib

Backtrace took 1.01s
```
