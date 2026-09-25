# Hand the generated .lib files to OpenSTA's own Liberty reader.
#
# tests/check_lib.py is deliberately self-contained, so it can run anywhere --
# but it is our parser checking our writer. This closes that loop with the
# parser the consumer actually uses. run_tests.sh calls it only when an
# OpenSTA binary is on PATH; there is no way to fake this one.
#
#   ROM_LIB_LIST="<lib>\n<lib>..." sta -no_init -no_splash -exit tests/read_liberty.tcl
#
# The list arrives in the ENVIRONMENT, not after the script name. OpenSTA
# takes exactly one positional argument, the cmd_file; hand it a second one
# and the binary prints its usage and exits 1 having never sourced this file.
# That is not a hypothetical -- it is how this layer failed the first time it
# ever got to run, in CI on 2026-09-25, once OpenSTA actually built.

set paths {}
if { [info exists ::env(ROM_LIB_LIST)] } {
    foreach line [split $::env(ROM_LIB_LIST) "\n"] {
        set line [string trim $line]
        if { $line ne "" } { lappend paths $line }
    }
}

# An empty list is not an empty job, it is a job that never started. If the
# variable does not arrive the foreach below simply never runs and this exits
# 0 -- a layer reporting success having read nothing, the worst outcome
# available. So it is a failure instead.
if { [llength $paths] == 0 } {
    puts "  FAIL read_liberty.tcl received no .lib paths."
    puts "       They come in via ROM_LIB_LIST, newline-separated; it was"
    puts "       empty or unset, so NOTHING was checked. Fix the caller"
    puts "       rather than letting the layer pass vacuously."
    exit 1
}

set failed 0

foreach path $paths {
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
puts "read_liberty: [llength $paths] file(s) accepted by OpenSTA"
exit 0
