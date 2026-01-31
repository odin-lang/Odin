/*
The implementation of the `odin test` runner and procedures user tests can use for this purpose.

Defineables through `#config`:

```odin
// Specify how many threads to use when running tests.
TEST_THREADS          : int    : #config(ODIN_TEST_THREADS,              0)
// Track the memory used by each test.
TRACKING_MEMORY       : bool   : #config(ODIN_TEST_TRACK_MEMORY,         true)
// Always report how much memory is used, even when there are no leaks or bad frees.
ALWAYS_REPORT_MEMORY  : bool   : #config(ODIN_TEST_ALWAYS_REPORT_MEMORY, false)
// Treat memory leaks and bad frees as errors.
FAIL_ON_BAD_MEMORY    : bool   : #config(ODIN_TEST_FAIL_ON_BAD_MEMORY,   false)
// Specify how much memory each thread allocator starts with.
PER_THREAD_MEMORY     : int    : #config(ODIN_TEST_THREAD_MEMORY, mem.   ROLLBACK_STACK_DEFAULT_BLOCK_SIZE)
// Select a specific set of tests to run by name.
// Each test is separated by a comma and may optionally include the package name.
// This may be useful when running tests on multiple packages with `-all-packages`.
// The format is: `package.test_name,test_name_only,...`
TEST_NAMES            : string : #config(ODIN_TEST_NAMES,                "")
// Show the fancy animated progress report.
// This requires terminal color support, as well as STDOUT to not be redirected to a file.
FANCY_OUTPUT          : bool   : #config(ODIN_TEST_FANCY,                true)
// Copy failed tests to the clipboard when done.
USE_CLIPBOARD         : bool   : #config(ODIN_TEST_CLIPBOARD,            false)
// How many test results to show at a time per package.
PROGRESS_WIDTH        : int    : #config(ODIN_TEST_PROGRESS_WIDTH,       24)
// This is the random seed that will be sent to each test.
// If it is unspecified, it will be set to the system cycle counter at startup.
SHARED_RANDOM_SEED    : u64    : #config(ODIN_TEST_RANDOM_SEED,          0)
// Set the lowest log level for this test run.
LOG_LEVEL_DEFAULT     : string : "debug" when ODIN_DEBUG else "info"
LOG_LEVEL             : string : #config(ODIN_TEST_LOG_LEVEL,            LOG_LEVEL_DEFAULT)
// Report a message at the info level when a test has changed its state.
LOG_STATE_CHANGES     : bool   : #config(ODIN_TEST_LOG_STATE_CHANGES,    false)
// Show only the most necessary logging information.
USING_SHORT_LOGS      : bool   : #config(ODIN_TEST_SHORT_LOGS,           false)
// Output a report of the tests to the given path.
JSON_REPORT           : string : #config(ODIN_TEST_JSON_REPORT,          "")
// Print the full file path for failed test cases on a new line
// in a way that's friendly to regex capture for an editor's "go to error".
GO_TO_ERROR           : bool   : #config(ODIN_TEST_GO_TO_ERROR,          false)
```
*/
package testing