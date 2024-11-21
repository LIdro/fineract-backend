FROM gradle:7.5.1-jdk17 AS builder

WORKDIR /app
COPY . .
RUN gradle clean bootJar -x test

FROM openjdk:17-slim

WORKDIR /app
COPY --from=builder /app/fineract-provider/build/libs/fineract-provider.jar ./app.jar
COPY --from=builder /app/fineract-provider/build/classes/java/main/META-INF/build.properties ./META-INF/build.properties

ENV JAVA_OPTS="-Xmx1G -Xms1G"
ENV FINERACT_NODE_ID=1

EXPOSE 8443

ENTRYPOINT ["java", "-jar", "app.jar"]
