# Hand the generated .lib files to OpenSTA's own Liberty reader.
#
# tests/check_lib.py is deliberately self-contained, so it can run anywhere --
# but it is our parser checking our writer. This closes that loop with the
# parser the consumer actually uses. run_tests.sh calls it only when an
# OpenSTA binary is on PATH; there is no way to fake this one.
#
#   sta -no_init -no_splash -exit tests/read_liberty.tcl <lib> [<lib> ...]

set failed 0

foreach path $argv {
    if { [catch {read_liberty $path} err] } {
        puts "  FAIL [file tail $path]  OpenSTA refused it: $err"
        incr failed
        continue
    }

    # read_liberty survives some malformed files with a warning, so ask for
    # the library back: a name that does not come out means nothing was built.
    set name [file rootname [file tail $path]]
    if { [catch {get_libs $name} libs] || $libs eq "" } {
        puts "  FAIL [file tail $path]  read, but no library named $name exists"
        incr failed
        continue
    }
    puts "  ok   [file tail $path]  read by OpenSTA"
}

if { $failed > 0 } {
    puts "read_liberty: $failed file(s) FAILED"
    exit 1
}
puts "read_liberty: [llength $argv] file(s) accepted by OpenSTA"
exit 0
