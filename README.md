# MRISS Maven Repository

This repository hosts packages only. It is the home of the MRISS-Projects Maven registry on
GitHub Packages:

```text
https://maven.pkg.github.com/MRISS-Projects/maven-repo
```

It holds no artifacts in git. Until October 2026, `master` carried a Maven repository layout
(`com/`, `org/`) served over raw GitHub URLs. That tree was removed by
[#9](https://github.com/MRISS-Projects/maven-repo/issues/9); git history still has it. Builds that
resolved through `raw.githubusercontent.com/MRISS-Projects/maven-repo` no longer resolve.

## What is published

The packages are listed on the
[organisation's packages page](https://github.com/orgs/MRISS-Projects/packages?repo_name=maven-repo).
Projects publish to the registry with `mvn deploy`, from their own release workflows. Nothing is
published by committing files here.

## Consuming packages

GitHub Packages requires authentication even to read a public package. Use a personal access token
with the `read:packages` scope, or `write:packages` to publish, in `~/.m2/settings.xml`:

```xml
<settings>
  <servers>
    <server>
      <id>MRISS-Projects-maven-repo</id>
      <username>YOUR_GITHUB_USERNAME</username>
      <password>YOUR_PERSONAL_ACCESS_TOKEN</password>
    </server>
  </servers>
</settings>
```

Then declare the repository in the consuming POM, or in a profile of `settings.xml`. The `<id>` must
match the server's:

```xml
<repositories>
  <repository>
    <id>MRISS-Projects-maven-repo</id>
    <url>https://maven.pkg.github.com/MRISS-Projects/maven-repo</url>
    <snapshots><enabled>true</enabled></snapshots>
  </repository>
</repositories>
```

A plugin, such as the MRISS fork of `maven-changes-plugin`, needs the same URL under
`<pluginRepositories>`.
