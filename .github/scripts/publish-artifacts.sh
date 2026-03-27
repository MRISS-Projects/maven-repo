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
ALREADY_EXISTS=0
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
    echo "--- Checking: ${groupId}:${artifactId}:${version}"

    # Check whether this artifact version already exists in GitHub Packages.
    # GitHub Packages Maven registry is immutable: re-uploading an existing
    # version returns HTTP 409 "Conflict" or HTTP 422 "Unprocessable Entity".
    # Checking first makes the workflow idempotent so it can be safely re-run
    # (e.g. after a cancelled previous run that had already published some
    # artifacts).  Any 409/422 that slips through the pre-check is also handled
    # gracefully in the deploy step below.
    pomCheckUrl="${REPO_URL}/${groupPath}/${artifactId}/${version}/${baseFile}.pom"
    httpStatus=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 \
        --max-time 30 \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "${pomCheckUrl}")
    if [ "${httpStatus}" = "200" ]; then
        echo "SKIP: ${groupId}:${artifactId}:${version} already exists in GitHub Packages."
        ALREADY_EXISTS=$(( ALREADY_EXISTS + 1 ))
        continue
    elif [ "${httpStatus}" != "404" ] && [ "${httpStatus}" != "000" ]; then
        echo "  INFO: Existence check returned HTTP ${httpStatus} for ${groupId}:${artifactId}:${version} – proceeding with deploy."
    fi

    echo "--- Deploying: ${groupId}:${artifactId}:${version}"

    sourcesJar="${dir}/${baseFile}-sources.jar"
    javadocJar="${dir}/${baseFile}-javadoc.jar"

    # Determine the packaging type declared in the POM.  When the <packaging>
    # element is absent the Maven default is 'jar'.
    # maven-plugin packaging also produces a .jar file on disk (not .maven-plugin).
    # Lines starting with an XML comment are filtered out to avoid false matches.
    packaging=$(grep -v '<!--' "${pomFile}" | sed -n 's|.*<packaging>\([^<]*\)</packaging>.*|\1|p' | head -1)
    packaging="${packaging:-jar}"
    [ "${packaging}" = "maven-plugin" ] && packaging="jar"

    # Build the base argument array
    deployArgs=(
        --batch-mode
        deploy:deploy-file
        -DrepositoryId=github
        "-Durl=${REPO_URL}"
        "-DpomFile=${pomFile}"
        -Dgpg.skip=true
    )

    if [ "${packaging}" = "pom" ]; then
        # POM-only artifact (e.g. parent/BOM pom)
        deployArgs+=( "-Dfile=${pomFile}" -Dpackaging=pom )
    else
        mainArtifact="${dir}/${baseFile}.${packaging}"
        if [ -f "${mainArtifact}" ]; then
            deployArgs+=( "-Dfile=${mainArtifact}" "-Dpackaging=${packaging}" )
        else
            # No binary artifact found for the declared packaging type.
            # Fall back to POM-only so Maven at least records the coordinates.
            echo "  WARNING: expected ${baseFile}.${packaging} not found; deploying as POM-only."
            deployArgs+=( "-Dfile=${pomFile}" -Dpackaging=pom )
        fi
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

    # Capture Maven output so we can inspect it for known "already exists"
    # status codes (409 Conflict / 422 Unprocessable Entity) that GitHub
    # Packages returns when an immutable artifact version is re-uploaded.
    # LC_ALL=C ensures English-language Maven output regardless of runner locale
    # so that the grep pattern below matches reliably.
    tmpOut=$(mktemp) || { echo "ERROR: Failed to create temp file"; exit 1; }
    if LC_ALL=C mvn "${deployArgs[@]}" 2>&1 | tee "${tmpOut}"; then
        DEPLOYED=$(( DEPLOYED + 1 ))
    elif grep -qE "status code: (409|422)" "${tmpOut}"; then
        echo "INFO: ${groupId}:${artifactId}:${version} already exists in GitHub Packages (conflict detected during upload) – skipping."
        ALREADY_EXISTS=$(( ALREADY_EXISTS + 1 ))
    else
        echo "WARNING: Failed to deploy ${groupId}:${artifactId}:${version} – continuing."
        FAILED=$(( FAILED + 1 ))
    fi
    rm -f "${tmpOut}"

done < <(find . -name "*.pom" -not -path "./.git/*" | sort)

echo ""
echo "=================================================="
echo " Done."
echo "   Deployed      : ${DEPLOYED}"
echo "   Already exists: ${ALREADY_EXISTS}  (skipped – version already in GitHub Packages)"
echo "   Skipped       : ${SKIPPED}  (timestamp-based SNAPSHOTs)"
echo "   Failed        : ${FAILED}"
echo "=================================================="

if [ "${FAILED}" -gt 0 ]; then
    exit 1
fi
