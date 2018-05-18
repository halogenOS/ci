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
      steps {
        echo 'Preparing...'
        dir(path: '/mnt/building/jws/xos') {
          echo 'Making directories...'
          sh 'mkdir -p src bin'
          echo 'Downloading tools...'
          sh '''if [ -x bin/repo ]; then
exit 0
fi

echo "Downloading repo..."

curl https://storage.googleapis.com/git-repo-downloads/repo > bin/repo
chmod a+x bin/repo'''
          echo 'Setting path'
          sh 'export PATH="$(pwd)/bin:$PATH"'
          echo 'Initializing source tree...'
          dir(path: 'src') {
            sh '''if [ ! -f .repo ]; then
  repo init -u git://github.com/halogenOS/android_manifest.git -b $XOS_REVISION\'
fi
'''
          }

        }

      }
    }
    stage('Sync') {
      steps {
        echo 'Syncing...'
        dir(path: '/mnt/building/jws/xos') {
          dir(path: 'src') {
            retry(count: 3) {
              sh '''set +x
if [ -d build/make -a -d external/xos ]; then
echo "Bootstrap sync not necessary."
exit 0
fi

echo "Doing boostrap sync..."
repo sync -c --no-tags build/make external/xos

'''
            }

            retry(count: 4) {
              echo 'Syncing sources...'
              sh '''set +x
source build/envsetup.sh
reposync'''
            }

            retry(count: 2) {
              echo 'Syncing device trees...'
              sh '''set +x
if ! type breakfast 2>&1 >/dev/null; then
  source build/envsetup.sh
fi
set +e
breakfast "$Device"
set -e
echo "Checking if everything is alright..."
if ! find device -name "$Device" -type d -mindepth 2 -maxdepth 2; then
  exit 1
fi'''
            }

          }

        }

      }
    }
    stage('Build') {
      steps {
        echo 'Building...'
        dir(path: '/mnt/building/jws/xos') {
          dir(path: 'src') {
            sh '''set +x
source build/envsetup.sh
build full XOS_$device-userdebug $( [ "$Clean" == "false" ] && echo -n noclean || : )'''
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