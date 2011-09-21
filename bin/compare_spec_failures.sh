#!/usr/bin/env bash
#5584 examples, 128 failures, 28 pending

pipe=/tmp/mypipe_$RANDOM

function compare_failure_count() {
  failures=`grep -e '[0-9]* examples, [0-9]* failures'|cut -f3 -d' '`
  expected_failures=`cat $WORKSPACE/../expected_failures`
  if [[ -n $expected_failures && $failures -gt $expected_failures ]]; then
    echo "Expected at most $expected_failures failures, actual $failures failures. Aborting." >&2
    exit 1
  else
    if [[ $failures -ne $expected_failures ]]; then
      echo "Expected $expected_failures failures <  actual $failures failures. Changing expectation."
      echo $failures >$WORKSPACE/../expected_failures
    else
      echo "Expected $expected_failures failures == actual $failures failures. Pass."
    fi
  fi
}

trap "rm -f $pipe; exit" EXIT

if [[ ! -p $pipe ]]; then
    mkfifo -m 600 $pipe
fi

#rake ci:rspec |tee >(cat) >(compare_failure_count)
cat $1|tee >(cat >$pipe) | compare_failure_count >$pipe | cat <$pipe
exit ${PIPESTATUS[2]}
