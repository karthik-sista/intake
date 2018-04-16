import java.text.SimpleDateFormat

node('intake-slave') {
  checkout scm
  def branch = env.BRANCH_NAME ?: (env.GIT_BRANCH ?: 'master')
  def curStage = 'Start'
  def pipelineStatus = 'SUCCESS'
  def successColor = '11AB1B'
  def failureColor = '#FF0000'
  SimpleDateFormat dateFormatGmt = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
  def buildDate = dateFormatGmt.format(new Date())

  try {

      VERSION = sh(returnStdout: true, script: './scripts/ci/compute_version.rb').trim()
      VCS_REF = sh(
        script: 'git rev-parse --short HEAD',
        returnStdout: true
      )

      stage('Build') {
        curStage = 'Build'
        sh 'make build'
      }

      stage('Release') {
        curStage = 'Release'
        withEnv(["BUILD_DATE=${buildDate}","VERSION=${VERSION}","VCS_REF=${VCS_REF}"]) {
          sh 'make release'
        }
      }

      stage('Acceptance test Bubble'){
        withEnv(["INTAKE_IMAGE_VERSION=intakeaccelerator${BUILD_NUMBER}_app"]) {
          sh './scripts/ci/acceptance_test.rb'
        }
      }


    }

  } catch (e) {
    pipelineStatus = 'FAILED'
    currentBuild.result = 'FAILURE'
    throw e
  }

  finally {
    try {
      stage('Clean') {
        withEnv(["GIT_BRANCH=${branch}"]){
          sh './scripts/ci/clean.rb'
        }
      }
    } catch(e) {
      pipelineStatus = 'FAILED'
      currentBuild.result = 'FAILURE'
    }
  }
}
