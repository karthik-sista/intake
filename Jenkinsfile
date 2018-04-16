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
  def docker_credentials_id = '6ba8d05c-ca13-4818-8329-15d41a089ec0'

  try {
      stage('Acceptance test Bubble'){
        withDockerRegistry([credentialsId: docker_credentials_id]){
          withEnv(["INTAKE_IMAGE_OLD_VERSION=intakeaccelerator${BUILD_NUMBER}_app"]) {
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
