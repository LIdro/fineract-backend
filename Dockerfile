FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

# Install required tools
RUN apt-get update && \
    apt-get install -y dos2unix

# Copy the Gradle wrapper files first
COPY gradle gradle/
COPY gradlew gradlew
COPY gradle.properties .
COPY settings.gradle .
COPY build.gradle .

# Fix line endings and make gradlew executable
RUN dos2unix gradlew && \
    chmod +x gradlew && \
    echo "Current directory contents:" && \
    ls -la && \
    echo "Gradle directory contents:" && \
    ls -la gradle && \
    echo "Current working directory:" && \
    pwd && \
    echo "Current user:" && \
    whoami && \
    echo "File type of gradlew:" && \
    file gradlew

# Copy the rest of the source code
COPY . .

# Try to execute gradlew with full path and debug info
RUN pwd && \
    ls -la && \
    echo "Testing gradlew execution:" && \
    /app/gradlew -v && \
    echo "Building project:" && \
    /app/gradlew clean bootJar --info --stacktrace

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
