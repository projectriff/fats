package io.projectriffsamples.bootrepeater;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import reactor.core.publisher.Flux;
import reactor.util.function.Tuple2;

import java.util.Collections;
import java.util.function.Function;

@SpringBootApplication
public class BootRepeaterApplication {

    /**
     * Accepts a Flux of String and Flux of integer and returns a flux of string
     * that represents the string repeated integer number of times in a list.
     *
     * i.e. given input hello, 2 the output string will be
     * "[hello, hello]"
     */
    @Bean
    public Function<Tuple2<Flux<String>, Flux<Integer>>, Flux<String>> repeater() {
        return objects -> {
            Flux<String> stringFlux = objects.getT1();
            Flux<Integer> integerFlux = objects.getT2();

            return stringFlux.zipWith(integerFlux, (s, i) -> Collections.nCopies(i, s).toString());
        };
    }

    public static void main(String[] args) {
        SpringApplication.run(BootRepeaterApplication.class, args);
    }

}
