#!/usr/bin/env bash
# Publishes every release artifact in this repository to GitHub Packages.
#
# Environment variables used by this script:
#   GITHUB_TOKEN       – token with packages:write permission.
#                        Must be explicitly mapped in the calling workflow step's
#                        env: section (e.g. GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}).
#   GITHUB_ACTOR       – GitHub username that owns the token.
#                        Automatically injected by GitHub Actions as a default
#                        environment variable; no explicit mapping required.
#   GITHUB_REPOSITORY  – owner/repo  (e.g. "MRISS-Projects/maven-repo").
#                        Automatically injected by GitHub Actions as a default
#                        environment variable; no explicit mapping required.
#
# SNAPSHOT artifacts that are stored with a timestamp-based filename
# (e.g. artifact-1.0-20231201.123456-1.jar) are intentionally skipped.
# Only clean release versions are published.

set -euo pipefail

REPO_URL="https://maven.pkg.github.com/${GITHUB_REPOSITORY}"

echo "=================================================="
echo " Publishing Maven artifacts to GitHub Packages"
echo " Target: ${REPO_URL}"
echo "=================================================="

DEPLOYED=0
SKIPPED=0
FAILED=0

# Walk every .pom file in the repository (relative to the repo root).
while IFS= read -r pomFile; do

    dir=$(dirname "${pomFile}")
    baseFile=$(basename "${pomFile}" .pom)

    # Skip timestamp-based SNAPSHOT files  (e.g. artifact-1.0-20231201.123456-1.pom)
    if echo "${baseFile}" | grep -qE '[0-9]{8}\.[0-9]{6}-[0-9]+$'; then
        SKIPPED=$(( SKIPPED + 1 ))
        continue
    fi

    # Derive Maven coordinates from the standard repository directory layout:
    #   ./groupId/path/artifactId/version/artifactId-version.pom
    relDir="${dir#./}"
    version=$(basename "${relDir}")
    artifactDir=$(dirname "${relDir}")
    artifactId=$(basename "${artifactDir}")
    groupPath=$(dirname "${artifactDir}")
    groupId=$(echo "${groupPath}" | tr '/' '.')

    echo ""
    echo "--- Deploying: ${groupId}:${artifactId}:${version}"

    mainJar="${dir}/${baseFile}.jar"
    sourcesJar="${dir}/${baseFile}-sources.jar"
    javadocJar="${dir}/${baseFile}-javadoc.jar"

    # Build the base argument array
    deployArgs=(
        --batch-mode
        deploy:deploy-file
        -DrepositoryId=github
        "-Durl=${REPO_URL}"
        "-DpomFile=${pomFile}"
        -Dgpg.skip=true
    )

    if [ -f "${mainJar}" ]; then
        deployArgs+=( "-Dfile=${mainJar}" -Dpackaging=jar )
    else
        # POM-only artifact (packaging=pom)
        deployArgs+=( "-Dfile=${pomFile}" -Dpackaging=pom )
    fi

    # Attach sources / javadoc as additional artifacts when present
    extraFiles=()
    extraClassifiers=()
    extraTypes=()

    if [ -f "${sourcesJar}" ]; then
        extraFiles+=( "${sourcesJar}" )
        extraClassifiers+=( "sources" )
        extraTypes+=( "jar" )
    fi

    if [ -f "${javadocJar}" ]; then
        extraFiles+=( "${javadocJar}" )
        extraClassifiers+=( "javadoc" )
        extraTypes+=( "jar" )
    fi

    if [ "${#extraFiles[@]}" -gt 0 ]; then
        # Join arrays with commas without using eval
        filesStr=$(printf '%s,' "${extraFiles[@]}");       filesStr="${filesStr%,}"
        classifiersStr=$(printf '%s,' "${extraClassifiers[@]}"); classifiersStr="${classifiersStr%,}"
        typesStr=$(printf '%s,' "${extraTypes[@]}");       typesStr="${typesStr%,}"
        deployArgs+=( "-Dfiles=${filesStr}" "-Dclassifiers=${classifiersStr}" "-Dtypes=${typesStr}" )
    fi

    if mvn "${deployArgs[@]}"; then
        DEPLOYED=$(( DEPLOYED + 1 ))
    else
        echo "WARNING: Failed to deploy ${groupId}:${artifactId}:${version} – continuing."
        FAILED=$(( FAILED + 1 ))
    fi

done < <(find . -name "*.pom" -not -path "./.git/*" | sort)

echo ""
echo "=================================================="
echo " Done."
echo "   Deployed : ${DEPLOYED}"
echo "   Skipped  : ${SKIPPED}  (timestamp-based SNAPSHOTs)"
echo "   Failed   : ${FAILED}"
echo "=================================================="

if [ "${FAILED}" -gt 0 ]; then
    exit 1
fi
