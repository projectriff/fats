package io.projectriffsamples;

import reactor.core.publisher.Flux;
import reactor.util.function.Tuple2;

import java.util.Collections;
import java.util.function.Function;

/**
 * Accepts a Flux of String and Flux of integer and returns a flux of string
 * that represents the string repeated integer number of times in a list.
 *
 * i.e. given input hello, 2 the output string will be
 * "[hello, hello]"
 */
public class Repeater implements Function<Tuple2<Flux<String>, Flux<Integer>>, Flux<String>> {

    public Flux<String> apply(Tuple2<Flux<String>, Flux<Integer>> inputs) {
        Flux<String> stringFlux = inputs.getT1();
        Flux<Integer> integerFlux = inputs.getT2();
        return stringFlux.zipWith(integerFlux, (s, i) -> Collections.nCopies(i, s).toString());
    }
}
