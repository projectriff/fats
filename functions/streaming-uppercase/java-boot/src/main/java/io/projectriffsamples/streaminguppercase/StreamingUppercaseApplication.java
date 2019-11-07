package io.projectriffsamples.streaminguppercase;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import reactor.core.publisher.Flux;

import java.util.function.Function;

@SpringBootApplication
public class StreamingUppercaseApplication {

    public static void main(String[] args) {
        SpringApplication.run(StreamingUppercaseApplication.class, args);
    }

    @Bean
    public Function<Flux<String>, Flux<String>> streamingUppercase() {
        return stringFlux -> stringFlux.log().map(String::toUpperCase);
    }
}
