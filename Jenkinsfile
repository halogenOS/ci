pipeline {
  agent any
  stages {
    stage('Prerequisites') {
      steps {
        isUnix()
        sh '''set -e

for command in git curl wget make; do
  hash $command
done'''
      }
    }
    stage('Prepare') {
      parallel {
        stage('Prepare') {
          steps {
            echo 'Preparing...'
          }
        }
        stage('Make directories') {
          steps {
            sh 'mkdir -p src bin'
          }
        }
        stage('Download tools') {
          steps {
            sh '''echo "Downloading repo..."

curl https://storage.googleapis.com/git-repo-downloads/repo > bin/repo
chmod a+x bin/repo'''
          }
        }
      }
    }
  }
}