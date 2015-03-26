#!/bin/bash
#
# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Tests the examples provided in Bazel
#

# Load test environment
source $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-setup.sh \
  || { echo "test-setup.sh not found!" >&2; exit 1; }

function set_up() {
  copy_examples
}

#
# Native rules
#
function test_cpp() {
  assert_build "//examples/cpp:hello-world"
  assert_bazel_run "//examples/cpp:hello-world foo" "Hello foo"
  assert_test_ok "//examples/cpp:hello-success_test"
  assert_test_fails "//examples/cpp:hello-fail_test"
}

# An assertion that execute a binary from a sub directory (to test runfiles)
function assert_binary_run_from_subdir() {
    ( # Needed to make execution from a different path work.
    export PATH=${bazel_javabase}/bin:"$PATH" &&
    mkdir -p x &&
    cd x &&
    unset JAVA_RUNFILES &&
    unset TEST_SRCDIR &&
    assert_binary_run "../$1" "$2" )
}

function test_java() {
  local java_pkg=examples/java-native/src/main/java/com/example/myproject

  assert_build ${java_pkg}:hello-lib ./bazel-bin/${java_pkg}/libhello-lib.jar
  assert_build ${java_pkg}:custom-greeting ./bazel-bin/${java_pkg}/libcustom-greeting.jar
  assert_build ${java_pkg}:hello-world ./bazel-bin/${java_pkg}/hello-world
  assert_build ${java_pkg}:hello-resources ./bazel-bin/${java_pkg}/hello-resources
  assert_binary_run_from_subdir "bazel-bin/${java_pkg}/hello-world foo" "Hello foo"
}

function test_java_test() {
  setup_javatest_support
  local java_native_tests=//examples/java-native/src/test/java/com/example/myproject

  assert_build //examples/java-native/...
  assert_test_ok "${java_native_tests}:hello"
  assert_test_ok "${java_native_tests}:custom"
  assert_test_fails "${java_native_tests}:fail"
  assert_test_fails "${java_native_tests}:resource-fail"
}

function test_java_test_with_workspace_name() {
  local java_pkg=examples/java-native/src/main/java/com/example/myproject
  # Use named workspace and test if we can still execute hello-world
  bazel clean

  rm -f WORKSPACE
  cat >WORKSPACE <<'EOF'
workspace(name = "toto")
EOF

  assert_build ${java_pkg}:hello-world ./bazel-bin/${java_pkg}/hello-world
  assert_binary_run_from_subdir "bazel-bin/${java_pkg}/hello-world foo" "Hello foo"
}

function test_genrule_and_genquery() {
  # The --javabase flag is to force the tools/jdk:jdk label to be used
  # so it appears in the dependency list.
  assert_build "--javabase=//tools/jdk examples/gen:genquery" ./bazel-bin/examples/gen/genquery
  local want=./bazel-genfiles/examples/gen/genrule.txt
  assert_build "--javabase=//tools/jdk examples/gen:genrule" $want

  diff $want ./bazel-bin/examples/gen/genquery \
    || fail "genrule and genquery output differs"

  grep -qE "^//tools/jdk:jdk$" $want || {
    cat $want
    fail "//tools/jdk:jdk not found in genquery output"
  }
}

#
# Skylark rules
#
function test_python() {
  assert_build "//examples/py:bin"

  ./bazel-bin/examples/py/bin >& $TEST_log \
    || fail "//examples/py:bin execution failed"
  expect_log "Fib(5)=8"
}

function test_go() {
  if [ -e "tools/go/go_root" ]; then
    bazel build -s //examples/go/lib1:lib1 \
      || fail "Failed to build //examples/go/lib1:lib1"
    bazel clean
    bazel build -s //examples/go:fib \
      || fail "Failed to build //examples/go:fib"
    [ -x "bazel-bin/examples/go/fib" ] \
      || fail "bazel-bin/examples/go/fib is not executable"

    bazel run //examples/go:fib >$TEST_log \
      || fail "Failed to run //examples/go:fib"
    expect_log "Fib(5): 8"

    bazel test //examples/go/lib1:lib1_test \
      || fail "Failed to run //examples/go/lib1:lib1_test"

    bazel test //examples/go/lib1:fail_test \
      && fail "Test //examples/go/lib1:fail_test has succeeded" \
      || true
  else
    echo "Skipping go test: go_root not set"
  fi
}

function test_java_skylark() {
  local java_pkg=examples/java-skylark/src/main/java/com/example/myproject
  assert_build ${java_pkg}:hello-lib ./bazel-bin/${java_pkg}/libhello-lib.jar
  assert_build ${java_pkg}:hello-data ./bazel-bin/${java_pkg}/hello-data
  assert_build ${java_pkg}:hello-world ./bazel-bin/${java_pkg}/hello-world
  # we built hello-world but hello-data is still there.
  want=./bazel-bin/${java_pkg}/hello-data
  test -x $want || fail "executable $want not found"
  assert_binary_run_from_subdir "bazel-bin/${java_pkg}/hello-data foo" "Heyo foo"
}

function test_java_test_skylark() {
  setup_skylark_javatest_support
  javatests=examples/java-skylark/src/test/java/com/example/myproject
  assert_build //${javatests}:pass
  assert_test_ok //${javatests}:pass
  assert_test_fails //${javatests}:fail
}

function test_protobuf() {
  setup_protoc_support
  local jar=bazel-bin/examples/proto/libtest_proto.jar
  assert_build //examples/proto:test_proto $jar
  unzip -v $jar | grep -q 'KeyVal\.class' \
    || fail "Did not find KeyVal class in proto jar."
}

run_suite "examples"
