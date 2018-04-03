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

        stage('Test') {
            curStage = 'Test'
            sh 'make test'
        }

        if (branch == 'master') {
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

            stage('Publish') {
                withDockerRegistry([credentialsId: '6ba8d05c-ca13-4818-8329-15d41a089ec0']) {
                    curStage = 'Publish'
                    withEnv(["VERSION=${VERSION}"]){
                        sh './scripts/ci/publish.rb'
                    }
                }
            }

            stage('Deploy Preint') {
                sh "curl -v http://${JENKINS_USER}:${JENKINS_API_TOKEN}@jenkins.mgmt.cwds.io:8080/job/preint/job/deploy-intake/buildWithParameters?token=${JENKINS_TRIGGER_TOKEN}&cause=Caused%20by%20Build%20${env.BUILD_ID}"
                pipelineStatus = 'SUCCEEDED'
                currentBuild.result = 'SUCCESS'
            }

        }

        stage ('Reports') {
            step([$class: 'JUnitResultArchiver', testResults: '**/reports/*.xml'])

            publishHTML (target: [
                allowMissing: false,
                alwaysLinkToLastBuild: false,
                keepAll: true,
                reportDir: 'reports/coverage/js',
                reportFiles: 'index.html',
                reportName: 'JS Code Coverage'
            ])

            publishHTML (target: [
                allowMissing: false,
                alwaysLinkToLastBuild: false,
                keepAll: true,
                reportDir: 'reports/coverage/ruby',
                reportFiles: 'index.html',
                reportName: 'Ruby Code Coverage'
            ])
        }

    } catch (e) {
        pipelineStatus = 'FAILED'
        currentBuild.result = 'FAILURE'
        throw e
    }

    finally {
        try {
            stage('Clean') {
                sh './scripts/ci/clean.rb'
            }
        } catch(e) {
            pipelineStatus = 'FAILED'
            currentBuild.result = 'FAILURE'
        }

        if (branch == 'master') {
            slackAlertColor = successColor
            slackMessage = "${pipelineStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' completed for branch '${branch}' (${env.BUILD_URL})"

            if(pipelineStatus == 'FAILED') {
                slackAlertColor = failureColor
                slackMessage = "${pipelineStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' in stage '${curStage}' for branch '${branch}' (${env.BUILD_URL})"
            }

            slackSend channel: "#tech-intake", baseUrl: 'https://hooks.slack.com/services/', tokenCredentialId: 'slackmessagetpt2', color: slackAlertColor, message: slackMessage
        }

    }
}
