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
            sh '''if [ -x bin/repo ]; then
  exit 0
fi

echo "Downloading repo..."

curl https://storage.googleapis.com/git-repo-downloads/repo > bin/repo
chmod a+x bin/repo'''
          }
        }
        stage('Set PATH') {
          steps {
            sh 'export PATH="$(pwd)/bin:$PATH"'
          }
        }
        stage('Initialize tree') {
          steps {
            dir(path: 'src') {
              sh 'repo init -u git://github.com/halogenOS/android_manifest.git -b $XOS_REVISION'
            }

          }
        }
      }
    }
    stage('Sync') {
      parallel {
        stage('Sync') {
          steps {
            echo 'Syncing...'
          }
        }
        stage('Do a boostrap sync if necessary') {
          steps {
            dir(path: 'src') {
              sh '''if [ -d build/make -a -d external/xos ]; then
  echo "Bootstrap sync not necessary."
  exit 0
fi

echo "Doing boostrap sync..."
repo sync -c --no-tags build/make external/xos

'''
            }

          }
        }
        stage('Sync sources') {
          steps {
            dir(path: 'src') {
              retry(count: 4) {
                echo 'Syncing sources...'
                sh '''source build/envsetup.sh
reposync'''
              }

            }

          }
        }
        stage('Download device trees') {
          steps {
            dir(path: 'src') {
              retry(count: 2) {
                sh '''source build/envsetup.sh
breakfast $Device'''
              }

            }

          }
        }
      }
    }
    stage('Build') {
      parallel {
        stage('Build') {
          steps {
            echo 'Building...'
          }
        }
        stage('Build ROM') {
          steps {
            dir(path: 'src') {
              sh '''source build/envsetup.sh
build full XOS_$device-userdebug $( [ "$Clean" == "false" ] && echo -n noclean || : )'''
            }

          }
        }
      }
    }
  }
  environment {
    XOS_REVISION = 'XOS-8.1'
    Device = 'oneplus2'
    Clean = 'true'
  }
}