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
          sh 'repo init -u git://github.com/halogenOS/android_manifest.git -b $XOS_REVISION'
        }

        dir(path: '/mnt/building/jws/xos')
      }
    }
    stage('Sync') {
      steps {
        echo 'Syncing...'
        dir(path: 'src') {
          sh '''if [ -d build/make -a -d external/xos ]; then
echo "Bootstrap sync not necessary."
exit 0
fi

echo "Doing boostrap sync..."
repo sync -c --no-tags build/make external/xos

'''
        }

        dir(path: 'src') {
          retry(count: 4) {
            echo 'Syncing sources...'
            sh '''source build/envsetup.sh
reposync'''
          }

        }

        dir(path: 'src') {
          retry(count: 2) {
            sh '''source build/envsetup.sh
breakfast $Device'''
          }

        }

      }
    }
    stage('Build') {
      steps {
        echo 'Building...'
        dir(path: 'src') {
          sh '''source build/envsetup.sh
build full XOS_$device-userdebug $( [ "$Clean" == "false" ] && echo -n noclean || : )'''
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