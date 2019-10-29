package io.projectriffsamples;

import org.junit.Test;
import reactor.core.publisher.Flux;
import reactor.test.StepVerifier;
import reactor.util.function.Tuples;

public class RepeaterTest {

    @Test
    public void oneStringAndOneNumber() {
        Flux<String> stringFlux = Flux.just("test");
        Flux<Integer> integerFlux = Flux.just(2);

        Repeater r = new Repeater();
        StepVerifier.create(r.apply(Tuples.of(stringFlux, integerFlux)))
                .expectNext("[test, test]")
                .verifyComplete();
    }

    @Test
    public void twoStringsAndOneNumber() {
        Flux<String> stringFlux = Flux.just("test1", "test2");
        Flux<Integer> integerFlux = Flux.just(2);

        Repeater r = new Repeater();
        StepVerifier.create(r.apply(Tuples.of(stringFlux, integerFlux)))
                .expectNext("[test1, test1]")
                .verifyComplete();
    }

    @Test
    public void oneStringAndTwoNumber() {
        Flux<String> stringFlux = Flux.just("test");
        Flux<Integer> integerFlux = Flux.just(2, 3);

        Repeater r = new Repeater();
        StepVerifier.create(r.apply(Tuples.of(stringFlux, integerFlux)))
                .expectNext("[test, test]")
                .verifyComplete();
    }

    @Test
    public void twoStringsAndTwoNumber() {
        Flux<String> stringFlux = Flux.just("test1", "test2");
        Flux<Integer> integerFlux = Flux.just(2, 3);

        Repeater r = new Repeater();
        StepVerifier.create(r.apply(Tuples.of(stringFlux, integerFlux)))
                .expectNext("[test1, test1]")
                .expectNext("[test2, test2, test2]")
                .verifyComplete();
    }
}
