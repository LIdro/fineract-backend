FROM gradle:7.5.1-jdk17 AS builder

WORKDIR /app

# Copy only the files needed for dependency resolution first
COPY build.gradle settings.gradle gradle.properties ./
COPY buildSrc buildSrc
COPY fineract-provider/build.gradle fineract-provider/
COPY fineract-provider/dependencies.gradle fineract-provider/
COPY fineract-provider/gradle.properties fineract-provider/
COPY fineract-client/build.gradle fineract-client/
COPY fineract-avro-schemas/build.gradle fineract-avro-schemas/
COPY fineract-core/build.gradle fineract-core/
COPY fineract-loan/build.gradle fineract-loan/
COPY fineract-investor/build.gradle fineract-investor/
COPY fineract-provider/config/ fineract-provider/config/
COPY integration-tests/build.gradle integration-tests/

# Download dependencies first
RUN gradle downloadDependencies --no-daemon --stacktrace || true

# Now copy the rest of the source code
COPY . .

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
