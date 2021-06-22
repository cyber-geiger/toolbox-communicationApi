pipeline {
    triggers {
        pollSCM('') // Enabling being build on Push
    }
    agent any
	options {
		buildDiscarder(logRotator(numToKeepStr:'50'))
		disableConcurrentBuilds()
	}
	
	stages {
        stage('Clone sources') {
            steps {
                git url: 'git@github.com:cyber-geiger/toolbox-communicationApi.git',credentialsId: 'GEIGER_deployment', branch: env.BRANCH_NAME
            }
        }

        stage('Gradle build') {
            steps {
                sh './gradlew clean build jar javadoc --no-daemon'
            }
        }

        stage('Main test') {
            steps {
				script{
					try {
						sh './gradlew test checkstyleMain'
					} finally {
						junit '**/build/test-results/test/*.xml' 
					}
                }
            }
        }

        stage('Gradle publish') {
            steps {
                sh './gradlew -Dgradle.user.home=$HOME/.gradle publish --no-daemon'
            }
        }

    }
    post {
        always {
          publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'communicationAPI/build/reports/tests/test/', reportFiles: 'index.html', reportName: 'GEIGER localstorage Report', reportTitles: 'GEIGER-localstorage'])
        }
        success {
            archiveArtifacts artifacts: '**/build/libs/*.jar,**/target/install/**/*', fingerprint: true
			step([$class: 'JavadocArchiver', javadocDir: '**/build/docs/javadoc', keepAll: false])
            updateGitlabCommitStatus(name: 'build', state: 'success')
        }
        failure {
          updateGitlabCommitStatus(name: 'build', state: 'failed')
        }
    }
}