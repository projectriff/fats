package io.projectriffsamples.streaminguppercase;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import reactor.core.publisher.Flux;
import reactor.test.StepVerifier;

import java.util.function.Function;

@SpringBootTest
class StreamingUppercaseApplicationTests {

    @Autowired
    private Function<Flux<String>, Flux<String>> function;

    @Test
    void uppercase() {
        Flux<String> lowerStrings = Flux.just("one", "two");

        StepVerifier.create(function.apply(lowerStrings))
                .expectNext("ONE")
                .expectNext("TWO")
                .verifyComplete();
    }

}
