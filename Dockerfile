FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

# Copy the Gradle wrapper files
COPY gradlew .
COPY gradle gradle
COPY settings.gradle .
COPY build.gradle .
COPY gradle.properties .

# Copy the source code
COPY . .

# Make the Gradle wrapper executable
RUN chmod +x ./gradlew

# Build the application
RUN ./gradlew clean bootJar

# Create a new stage for running the application
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copy the built jar from the build stage
COPY --from=0 /app/fineract-provider/build/libs/*.jar app.jar

# Expose the application port
EXPOSE 8443

# Set environment variables
ENV SPRING_PROFILES_ACTIVE=default
ENV FINERACT_HIKARI_PASSWORD=mysql
ENV FINERACT_HIKARI_USERNAME=root
ENV FINERACT_HIKARI_DRIVER_SOURCE_CLASS_NAME=com.mysql.cj.jdbc.Driver
ENV FINERACT_HIKARI_JDBC_URL=jdbc:mysql://db:3306/fineract_tenants
ENV FINERACT_DEFAULT_TENANTDB_HOSTNAME=db
ENV FINERACT_DEFAULT_TENANTDB_PORT=3306
ENV FINERACT_DEFAULT_TENANTDB_UID=root
ENV FINERACT_DEFAULT_TENANTDB_PWD=mysql

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
