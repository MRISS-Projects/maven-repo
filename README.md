# MRISS Maven Repository — GitHub Packages

This repository stores Maven/Java artifacts that are published to **GitHub Packages** so that any Maven or Gradle project can consume them directly.

A GitHub Actions workflow ([`.github/workflows/publish-to-github-packages.yml`](.github/workflows/publish-to-github-packages.yml)) publishes every artifact in the repository to the GitHub Packages Maven registry at:

```
https://maven.pkg.github.com/MRISS-Projects/maven-repo
```

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Configure Maven](#2-configure-maven)
3. [Configure Gradle](#3-configure-gradle)
4. [Add the repository to your project POM](#4-add-the-repository-to-your-project-pom)
5. [Available Artifacts](#5-available-artifacts)
6. [Publishing new artifacts](#6-publishing-new-artifacts)

---

## 1. Prerequisites

GitHub Packages requires authentication even for **read** access to packages belonging to a public repository.  You need:

* A GitHub account.
* A **Personal Access Token (PAT)** with at least the `read:packages` scope.  
  Create one at **Settings → Developer settings → Personal access tokens**.

---

## 2. Configure Maven

Add the server credentials to your **`~/.m2/settings.xml`** (never commit credentials to source control):

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>github-mriss</id>
      <username>YOUR_GITHUB_USERNAME</username>
      <!-- Use a PAT with read:packages scope, or ${env.GITHUB_TOKEN} in CI -->
      <password>YOUR_PERSONAL_ACCESS_TOKEN</password>
    </server>
  </servers>
</settings>
```

> **CI environments** (GitHub Actions): replace the `<password>` value with `${env.GITHUB_TOKEN}` and expose the built-in `GITHUB_TOKEN` secret to your step.

---

## 3. Configure Gradle

Add the following to your `build.gradle` (Groovy DSL) or `build.gradle.kts` (Kotlin DSL):

**Groovy DSL**
```groovy
repositories {
    maven {
        url = uri("https://maven.pkg.github.com/MRISS-Projects/maven-repo")
        credentials {
            username = project.findProperty("gpr.user") ?: System.getenv("GITHUB_ACTOR")
            password = project.findProperty("gpr.key")  ?: System.getenv("GITHUB_TOKEN")
        }
    }
}
```

**Kotlin DSL**
```kotlin
repositories {
    maven {
        url = uri("https://maven.pkg.github.com/MRISS-Projects/maven-repo")
        credentials {
            username = project.findProperty("gpr.user") as String? ?: System.getenv("GITHUB_ACTOR")
            password = project.findProperty("gpr.key")  as String? ?: System.getenv("GITHUB_TOKEN")
        }
    }
}
```

Store your credentials in `~/.gradle/gradle.properties`:

```properties
gpr.user=YOUR_GITHUB_USERNAME
gpr.key=YOUR_PERSONAL_ACCESS_TOKEN
```

---

## 4. Add the repository to your project POM

```xml
<repositories>
  <repository>
    <id>github-mriss</id>
    <name>MRISS GitHub Packages</name>
    <url>https://maven.pkg.github.com/MRISS-Projects/maven-repo</url>
    <releases><enabled>true</enabled></releases>
    <snapshots><enabled>false</enabled></snapshots>
  </repository>
</repositories>
```

> The `<id>` value (`github-mriss`) must match the `<server><id>` in your `settings.xml`.

---

## 5. Available Artifacts

All release versions currently published to GitHub Packages are listed below.

### MRISS Parent POMs

| Group ID | Artifact ID | Available Versions |
|---|---|---|
| `com.mriss` | `mriss-parent` | 3.0.0, 3.1.1, 3.1.2, 3.2.0, 3.3.0, 3.3.1, 3.4.0, 3.5.0, 3.6.0, 3.6.1, 3.6.2, 3.6.3 |
| `com.mriss.mriss-parent` | `framework` | 3.0.0, 3.1.1, 3.1.2, 3.2.0, 3.3.0, 3.3.1, 3.4.0, 3.5.0, 3.6.0, 3.6.1, 3.6.2, 3.6.3 |
| `com.mriss.mriss-parent` | `infrastructure` | 3.0.0, 3.1.1, 3.1.2, 3.2.0, 3.3.0, 3.3.1, 3.4.0, 3.5.0, 3.6.0, 3.6.1, 3.6.2, 3.6.3 |
| `com.mriss.mriss-parent` | `products` | 3.0.0, 3.1.1, 3.1.2, 3.2.0, 3.3.0, 3.3.1, 3.4.0, 3.5.0, 3.6.0, 3.6.1, 3.6.2, 3.6.3 |

### MRISS Infrastructure

| Group ID | Artifact ID | Available Versions |
|---|---|---|
| `com.mriss.mriss-parent.infrastructure` | `announcement-templates` | 3.0.0, 3.1.1, 3.1.2, 3.2.0, 3.3.0, 3.3.1, 3.4.0, 3.5.0, 3.6.0, 3.6.1, 3.6.2, 3.6.3 |
| `com.mriss.mriss-parent.infrastructure` | `maven-archetypes` | 3.0.0, 3.1.1, 3.1.2, 3.2.0, 3.3.0, 3.3.1, 3.4.0, 3.5.0, 3.6.0, 3.6.1, 3.6.2, 3.6.3 |
| `com.mriss.mriss-parent.infrastructure` | `maven-plugins` | 3.0.0, 3.1.1, 3.1.2, 3.2.0, 3.3.0, 3.3.1, 3.4.0, 3.5.0, 3.6.0, 3.6.1, 3.6.2, 3.6.3 |
| `com.mriss.mriss-parent.infrastructure` | `skins` | 3.0.0, 3.1.1, 3.1.2, 3.2.0, 3.3.0, 3.3.1, 3.4.0, 3.5.0, 3.6.0, 3.6.1, 3.6.2, 3.6.3 |

### Mail Processor Service

| Group ID | Artifact ID | Available Versions |
|---|---|---|
| `com.mriss.mriss-parent.products` | `mail-processor-service` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service` | `card-statement-processor` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service` | `clock-in-processor` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service` | `mail-processing-api` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.card-statement-processor` | `backend` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.card-statement-processor` | `frontend` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.card-statement-processor` | `card-statement-parser` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.card-statement-processor` | `clock-in-parser` | 0.1.0, 0.1.1, 0.2.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.card-statement-processor.backend` | `app` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.card-statement-processor.backend` | `service` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.card-statement-processor.frontend` | `mobile` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.card-statement-processor.frontend` | `web-app` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.clock-in-processor` | `backend` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.clock-in-processor` | `frontend` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.clock-in-processor` | `clock-in-parser` | 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.clock-in-processor.backend` | `app` | 0.1.0, 0.1.1 |
| `com.mriss.mriss-parent.products.mail-processor-service.clock-in-processor.backend` | `clockin-backend-app` | 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.clock-in-processor.backend` | `service` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.clock-in-processor.frontend` | `mobile` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |
| `com.mriss.mriss-parent.products.mail-processor-service.clock-in-processor.frontend` | `web-app` | 0.1.0, 0.1.1, 0.2.0, 0.3.0 |

### DSH (Document Smart Highlights)

| Group ID | Artifact ID | Available Versions |
|---|---|---|
| `com.mriss.products` | `dsh` | 0.0.1, 0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4 |
| `com.mriss.products.dsh` | `DSH-doc-analyser` | 0.0.1, 0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4 |
| `com.mriss.products.dsh` | `DSH-doc-indexer-worker` | 0.0.1, 0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4 |
| `com.mriss.products.dsh` | `DSH-rest-api` | 0.0.1, 0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4 |
| `com.mriss.products.dsh` | `DSH-data` | 0.0.1, 0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4 |
| `com.mriss.products.dsh` | `dsh-test-dataset` | 0.0.1, 0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4 |
| `com.mriss.products.dsh` | `DSH-Coverage-Report` | 0.2.2, 0.2.3, 0.2.4 |
| `com.mriss.products.dsh.DSH-doc-analyser` | `DSH-doc-processor-worker` | 0.0.1, 0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4 |
| `com.mriss.products.dsh.DSH-doc-analyser` | `DSH-keyword-extractor` | 0.0.1, 0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4 |
| `com.mriss.products.dsh.DSH-doc-analyser` | `DSH-top-sentences-extractor` | 0.0.1, 0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4 |

### Third-party artifacts (bundled for convenience)

| Group ID | Artifact ID | Available Versions |
|---|---|---|
| `org.apache.maven.plugins` | `maven-changes-plugin` | 2.12.3, 2.12.4, 2.12.5, 2.12.6 |
| `com.google.code.maven-replacer-plugin` | `replacer` | 1.6.0 |

### Example dependency declaration (Maven)

```xml
<dependency>
  <groupId>com.mriss.products.dsh</groupId>
  <artifactId>DSH-rest-api</artifactId>
  <version>0.2.4</version>
</dependency>
```

```xml
<dependency>
  <groupId>com.mriss</groupId>
  <artifactId>mriss-parent</artifactId>
  <version>3.6.3</version>
  <type>pom</type>
</dependency>
```

---

## 6. Publishing new artifacts

Add your artifact files (`.jar`, `.pom`, etc.) to this repository following the standard Maven repository layout:

```
<groupId path>/<artifactId>/<version>/<artifactId>-<version>.jar
<groupId path>/<artifactId>/<version>/<artifactId>-<version>.pom
```

For example:

```
com/mriss/products/dsh/DSH-rest-api/0.2.5/DSH-rest-api-0.2.5.jar
com/mriss/products/dsh/DSH-rest-api/0.2.5/DSH-rest-api-0.2.5.pom
```

Once the files are committed and pushed to `main`, the **Publish Maven Artifacts to GitHub Packages** workflow runs automatically and deploys the new artifact to GitHub Packages.

You can also trigger the workflow manually from the repository's **Actions** tab at any time.
