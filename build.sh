#!/bin/sh

mvn clean package
pushd target && java -Djarmode=tools -jar crash-leyden-0.0.1-SNAPSHOT.jar extract && popd
