import Foundation
import MeterCore

// Claude Code statusline command. Reads the payload from stdin, merges it
// into the snapshot, prints one line. Any failure degrades to a line of
// dashes; nothing is ever written to stderr and the exit code is always 0.
let input = FileHandle.standardInput.readDataToEndOfFile()
let line = HookRunner.run(input: input, store: .default)
print(line)
exit(0)
