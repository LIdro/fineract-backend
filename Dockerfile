FROM gradle:7.5.1-jdk17 AS builder

WORKDIR /app

# Copy gradle configuration files
COPY gradle gradle
COPY build.gradle settings.gradle gradle.properties ./
COPY buildSrc buildSrc

# Copy project modules
COPY fineract-provider fineract-provider
COPY fineract-client fineract-client
COPY fineract-avro-schemas fineract-avro-schemas
COPY fineract-core fineract-core
COPY fineract-loan fineract-loan
COPY fineract-investor fineract-investor
COPY integration-tests integration-tests
COPY config config

# Build the application
RUN gradle clean bootJar -x test --no-daemon --stacktrace

# Final stage
FROM openjdk:17-slim

WORKDIR /app

# Copy the built artifact
COPY --from=builder /app/fineract-provider/build/libs/fineract-provider.jar ./app.jar

ENV JAVA_OPTS="-Xmx1G -Xms1G"
ENV FINERACT_NODE_ID=1

EXPOSE 8443

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
