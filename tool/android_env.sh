# Source from project root. All caches are contained in this checkout.
export JAVA_HOME="$PWD/.tooling/jdk-21.0.12.1+1"
export ANDROID_HOME="$PWD/.tooling/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="$PWD/.tooling/android-user"
export GRADLE_USER_HOME="$PWD/.tooling/gradle"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
