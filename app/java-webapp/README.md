# Java Webapp Multi-Module Project

This project contains a Maven multi-module Java application with:
- `lib1`: JAR module exposing a greeting service
- `lib2`: JAR module exposing a request processor
- `webapp`: WAR module exposing a servlet at `/api`

The WAR module depends on both JAR modules; if the JARs are missing, the WAR will fail with `ClassNotFoundException` or `NoClassDefFoundError`.

Build

```bash
cd java-webapp
mvn clean package -DskipTests
```

Artifacts produced

- `lib1/target/lib1-1.0.0-SNAPSHOT.jar`
- `lib2/target/lib2-1.0.0-SNAPSHOT.jar`
- `webapp/target/webapp-1.0.0-SNAPSHOT.war`

Run (recommended — quick, no external Tomcat required)

Option A — Run with the Jetty Maven plugin (quick, uses your JDK):

```bash
cd java-webapp/webapp
mvn org.eclipse.jetty:jetty-maven-plugin:11.0.15:run -Djetty.port=8080
```

- The app will be available at: http://localhost:8080/api
- Stop with Ctrl+C.

Option B — Deploy to a standalone Tomcat (plain Java/Tomcat):

1. Download Tomcat 10.1.x from https://tomcat.apache.org/
2. Unpack and copy the WAR:
   - `cp webapp/target/webapp-1.0.0-SNAPSHOT.war <tomcat>/webapps/ROOT.war`
3. Start Tomcat:
   - On Linux/macOS: `<tomcat>/bin/startup.sh`
   - On Windows: `<tomcat>\bin\startup.bat`
4. Visit: http://localhost:8080/api

Option C — (Alternative) Run with Jetty Runner:

1. Download a compatible Jetty runner jar (ensure compatibility with Jakarta Servlet 6 / Tomcat 10.1).
2. Run:
   ```bash
   java -jar jetty-runner.jar webapp/target/webapp-1.0.0-SNAPSHOT.war --port 8080
   ```

Test endpoints

GET example:

```bash
curl "http://localhost:8080/api?name=Aditya"
# Expected response:
# Hello, Aditya!
```

POST example:

```bash
curl -X POST -d "payload=hello" "http://localhost:8080/api"
# Expected response:
# POST processed successfully.
# Received payload: hello
```

Notes

- The WAR includes the two library JARs inside `WEB-INF/lib`. If you manually build and move the WAR, ensure `WEB-INF/lib` remains intact.
- If you need an executable single-jar (fat jar) with embedded server, consider converting to a Spring Boot-style project or building a small launcher using embedded Tomcat/Jetty.

Troubleshooting

- If the servlet fails to start with ClassNotFoundException for `com.example.lib1.GreetingService` or `com.example.lib2.RequestProcessor`, ensure you built the parent project so the JARs are present and packaged into the WAR (`mvn clean package -DskipTests` from `java-webapp`).

