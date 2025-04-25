package com.aot.crashleyden;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CrashLeydenApplication {

    public static void main(String[] args) throws InterruptedException {
        if (args.length == 0) {
            // training run packs a bunch of classes into the jar
            SpringApplication.run(CrashLeydenApplication.class, args);
        } else {
            // second run just sleeps until the crash, see run.sh
            Thread.sleep(10_000);
        }
    }
}
