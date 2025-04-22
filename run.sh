#/bin/sh
cd target

# step1 training run
$JAVA_HOME/bin/java \
-XX:AOTMode=record \
-XX:AOTConfiguration=/tmp/crash.aotconf \
-Dspring.context.exit=onRefresh \
-jar crash-leyden-0.0.1-SNAPSHOT/crash-leyden-0.0.1-SNAPSHOT.jar

#step2 create archive
$JAVA_HOME/bin/java \
-XX:AOTMode=create \
-XX:AOTConfiguration=/tmp/crash.aotconf \
-XX:AOTCache=/tmp/crash.aot \
-jar crash-leyden-0.0.1-SNAPSHOT/crash-leyden-0.0.1-SNAPSHOT.jar

# step3 run with archive
$JAVA_HOME/bin/java \
-XX:AOTMode=on \
-XX:AOTCache=/tmp/crash.aot \
-Dspring.context.exit=onRefresh \
-jar crash-leyden-0.0.1-SNAPSHOT/crash-leyden-0.0.1-SNAPSHOT.jar
