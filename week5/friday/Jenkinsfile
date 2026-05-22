pipeline {
  agent {
    docker {
      image 'node:18-alpine'
      args '--network=host'
    }
  }

  options {
    timeout(time: 10, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '10'))
    disableConcurrentBuilds()
  }

  environment {
    APP_NAME         = 'kijanikiosk-payments'
    BUILD_DIR        = 'dist'
    NEXUS_URL        = 'http://172.17.0.1:8081/repository/npm-kijanikiosk/'
    NODE_ENV         = 'test'
    PKG_VERSION      = sh(script: "node -p \"require('./package.json').version\"", returnStdout: true).trim()
    GIT_SHORT        = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
    ARTIFACT_VERSION = "${PKG_VERSION}-${GIT_SHORT}"
  }

  stages {

    // --- Stage 1: Lint (fail-fast — runs before build) ---
    stage('Lint') {
      steps {
        sh 'npm ci'
        sh 'npm run lint'
      }
    }

    // --- Stage 2: Build ---
    stage('Build') {
      steps {
        sh 'npm run build'
        sh '''
          set -e
          test -d "${BUILD_DIR}" || { echo "ERROR: build output missing"; exit 1; }
          echo "Build output confirmed: $(ls ${BUILD_DIR} | wc -l) files"
        '''
      }
    }

    // --- Stage 3: Parallel Verify ---
    stage('Verify') {
      parallel {
        stage('Test') {
          steps {
            sh 'npm test'
          }
          post {
            always {
              junit allowEmptyResults: true, testResults: 'test-results/*.xml'
            }
          }
        }
        stage('Security Audit') {
          steps {
            sh 'npm audit --audit-level=high'
          }
        }
      }
    }

    // --- Stage 4: Archive ---
    stage('Archive') {
      steps {
        archiveArtifacts artifacts: "${BUILD_DIR}/**",
                         fingerprint: true,
                         onlyIfSuccessful: true
      }
    }

    // --- Stage 5: Publish ---
    stage('Publish') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'nexus-credentials',
          usernameVariable: 'NEXUS_USER',
          passwordVariable: 'NEXUS_PASS'
        )]) {
          sh '''
            set -e

            # Write .npmrc with auth token
            echo "${NEXUS_URL}:_auth=$(echo -n ${NEXUS_USER}:${NEXUS_PASS} | base64)" > .npmrc
            echo "always-auth=true" >> .npmrc

            # Update version in package.json
            npm version ${ARTIFACT_VERSION} --no-git-tag-version

            # Publish to Nexus
            npm publish --registry=${NEXUS_URL}

            # Clean up credentials immediately
            rm -f .npmrc
          '''
        }
      }
    }
  }

  post {
    always {
      cleanWs()
    }
    success {
      echo "Pipeline succeeded. Artifact published: ${APP_NAME}@${ARTIFACT_VERSION}"
    }
    failure {
      echo "Pipeline FAILED on branch ${env.BRANCH_NAME}, build #${env.BUILD_NUMBER}"
    }
    changed {
      echo "Pipeline status changed to ${currentBuild.currentResult} (was ${currentBuild.previousResult})"
    }
  }
}
