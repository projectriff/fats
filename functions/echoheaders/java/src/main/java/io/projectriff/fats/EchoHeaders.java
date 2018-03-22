package io.projectriff.fats;

import java.util.function.Function;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.messaging.support.MessageHeaderAccessor;

@SpringBootApplication
public class EchoHeaders implements Function<Message<String>, Message<String>> {
	public Message<String> apply(Message<String> in) {
		String payload = String.format("Got Headers:\n%s\n\nGot Body:\n%s", in.getHeaders(), in.getPayload());

		return MessageBuilder
						.withPayload(payload)
						.setHeaders(new MessageHeaderAccessor(in)).build();
	}

	public static void main(String[] args) {
		SpringApplication.run(EchoHeaders.class, args);
	}
}