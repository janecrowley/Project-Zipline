
#!/bin/bash

test_dir="../tests"
pass_count=0
fail_count=0
total_count=0
passed_tests=()
failed_tests=()

echo "Starting test runs..."

for inbound_file in "$test_dir"/*.inbound; do
  # Extract test name by removing path and extension
  testname=$(basename "$inbound_file" .inbound)
  logfile="xrun_${testname}.log"

  echo "Running test: $testname"
  xrun -64bit -sv -access +rwc -f kme.vlist +TESTNAME="$testname" +define+SEED=1 -top kme_tb -delay_trigger -timescale 1ns/1ps -l "$logfile"

  ((total_count++))

  if grep -q "PASSED!" "$logfile"; then
    echo "? $testname PASSED"
    ((pass_count++))
    passed_tests+=("$testname")
  else
    echo "? $testname FAILED"
    ((fail_count++))
    failed_tests+=("$testname")
  fi
done

echo
echo "==================== Summary ===================="
echo "Total tests run: $total_count"
echo "Passed: $pass_count"
echo "Failed: $fail_count"
echo
if [ $fail_count -eq 0 ]; then
  echo "?? All tests PASSED!"
else
  echo "?? Some tests FAILED:"
  for test in "${failed_tests[@]}"; do
    echo " - $test"
  done
fi

