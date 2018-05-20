pipeline {
  agent any
  stages {
    stage('Prerequisites') {
      steps {
        isUnix()
        sh '''set -e

for command in git curl wget make python java type which [ [[; do
  hash $command || type $command
done
'''
        dir(path: '/mnt/building/jws/xos') {
          sh '''echo "Preparing Go..."

if [ ! -d go ]; then
  echo "Downloading Go..."
  curl https://dl.google.com/go/go1.10.2.linux-amd64.tar.gz 2>/dev/null | tar -xvz
fi

echo "Creating directories for Go..."
mkdir -p gopath

export GOROOT="$(pwd)/go"
export GOPATH="$(pwd)/gopath"
export PATH="$GOROOT/bin:$PATH"

echo "Downloading additional tools..."
go get -v github.com/itchio/gothub'''
        }

      }
    }
    stage('Prepare') {
      steps {
        echo 'Preparing...'
        dir(path: '/mnt/building/jws/xos') {
          echo 'Making directories...'
          sh 'mkdir -p src bin'
          echo 'Checking Python'
          sh '''export PATH="$(pwd)/bin:$PATH"
if [ "$(python --version | cut -d \' \' -f2 | cut -d \'.\' -f1)" == "3" ]; then
  echo "Found Python 3, but need 2. Trying to find a solution..."
  if ! hash python2; then
    echo "Need Python 2"
    exit 1
  else
    echo "Symlinking python2 to bin/python"
    ln -sf $(which python2) bin/python
    python --version
  fi
fi'''
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
            sh '''export PATH="$(pwd)/bin:$PATH"
if [ ! -d .repo ]; then
  repo init -u git://github.com/halogenOS/android_manifest.git -b "$XOS_REVISION"
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
export PATH="$(pwd)/bin:$PATH"

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
export PATH="$(pwd)/bin:$PATH"
source build/envsetup.sh
reposync'''
            }

            retry(count: 2) {
              echo 'Syncing device trees...'
              sh '''set +x
export PATH="$(pwd)/bin:$PATH"
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
export PATH="$(realpath $(pwd -P)/..)/bin:$PATH"

if [ "$(python --version | cut -d \' \' -f2 | cut -d \'.\' -f1)" == "3" ]; then
  echo "Woops... How could this happen? Python 2 is what AOSP needs. :/"
  exit 1
fi

source ../msg-lib

Device="$Device" msglib_send_message "Build $BUILD_NUMBER for $Device started"

LC_ALL=C build full XOS_$Device-userdebug $( [ "$Clean" == "false" ] && echo -n noclean || : )'''
          }

        }

      }
    }
    stage('Upload') {
      steps {
        dir(path: '/mnt/building/jws/xos') {
          sh '''set +x
set -e

if [ ! -f upload-creds ]; then
  echo "Upload credentials not found, skipping upload"
  exit 0
fi

source upload-creds
source msg-lib

export GOROOT="$(pwd)/go"
export GOPATH="$(pwd)/gopath"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

if [ -z "$BUILD_NUMBER" ]; then
  BUILD_NUMBER=0
fi

if [ ! -d builds-git ]; then
  echo "Cloning builds repository..."
  git clone https://$GITHUB_USER:$GITHUB_TOKEN@github.com/halogenOS/builds builds-git 2>/dev/null >/dev/null
fi

cd builds-git

git_rel_tag="tb$(date +%Y%m%d.%H%M.${BUILD_NUMBER})"
git tag $git_rel_tag && git push --tags

echo "Starting release..."

full_out_path="$(realpath ../src/out/target/product/$Device)"

git_rel_filename="$(basename $(ls -c $full_out_path/XOS*zip | head -n1))"
git_rel_filename_sum="$(basename $(ls -c $full_out_path/XOS*sum | head -n1))"
git_rel_filepath="$(realpath $full_out_path/$git_rel_filename)"
git_rel_sumpath="$(realpath $full_out_path/$git_rel_filename_sum)"

gothub release \\
    --user halogenOS \\
    --repo builds \\
    --tag $git_rel_tag \\
    --name "[Test build] $(date +%d/%m/%Y) for $Device" \\
    --description "This is a TEST BUILD. Please do not use this unless you know what this means.

Checksum ($(echo $git_rel_sumpath | cut -d \'.\' -f4)): $(echo $(<$git_rel_sumpath) | cut -d \' \' -f1)" \\
    --pre-release

echo "Uploading build..."
Device="$Device" msglib_send_message "Uploading build $BUILD_NUMBER..."

gothub upload \\
    --user halogenOS \\
    --repo builds \\
    --tag $git_rel_tag \\
    --name "$git_rel_filename" \\
    --file "$git_rel_filepath"

echo "Uploading checksum..."

gothub upload \\
    --user halogenOS \\
    --repo builds \\
    --tag $git_rel_tag \\
    --name "$git_rel_filename_sum" \\
    --file "$git_rel_sumpath"


Device="$Device" msglib_send_message "New test build $(date +%d/%m/%Y) for $Device

Download: https://github.com/halogenOS/builds/releases/download/$git_rel_tag/$git_rel_filename
"'''
        }

      }
    }
  }
  environment {
    XOS_REVISION = 'XOS-8.1'
    Device = 'cheeseburger'
    Clean = 'false'
    _JAVA_OPTIONS = '-Xmx8G'
  }
}