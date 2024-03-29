=head1 TITLE

smart.pir - A smart compiler.

=head2 Description

This is the base file for the smart compiler.

This file includes the parsing and grammar rules from
the src/ directory, loads the relevant PGE libraries,
and registers the compiler under the name 'smart'.

=head2 Functions

=over 4

=item onload()

Creates the smart compiler using a C<PCT::HLLCompiler>
object.

=cut

.namespace [ 'smart::Compiler' ]

.loadlib 'smart_group'

.include "include/warnings.pasm"

.include "stat.pasm"
.include "datatypes.pasm" # for libc::readdir
.include "src/constants.pir"

.sub 'onload' :anon :load :init
    warningson .PARROT_WARNINGS_DEPRECATED_FLAG

    load_bytecode 'PCT.pbc'

    $P0 = get_hll_global ['PCT'], 'HLLCompiler'
    $P1 = $P0.'new'()
    $P1.'language'('smart')
    $P1.'parsegrammar'('smart::Grammar')
    $P1.'parseactions'('smart::Grammar::Actions')
    
    $P1.'commandline_banner'("Smart Make for Parrot VM\n")
    $P1.'commandline_prompt'("smart> ")
.end

.sub "reset-global-variables"
    $P0 = new 'ResizablePMCArray'
    set_hll_global ['smart';'Grammar';'Actions'], '@?BLOCKS', $P0
    $P0 = new 'ResizablePMCArray'
    set_hll_global ['smart';'Grammar';'Actions'], '@VAR_SWITCHES', $P0
    $P0 = new 'Integer'
    $P0 = 1
    set_hll_global ['smart';'Grammar';'Actions'], '$VAR_ON', $P0
    $P0 = new 'Integer'
    $P0 = 0
    set_hll_global ['smart';'Grammar';'Actions'], '$RULE_NUMBER', $P0
    $P0 = new 'Integer'
    $P0 = 0
    set_hll_global ['smart';'Grammar';'Actions'], '$SMART_ACTION_NUMBER', $P0
    $P0 = new 'Integer'
    $P0 = 0
    set_hll_global ['smart';'Grammar';'Actions'], '$SMART_INCLUDE_NUMBER', $P0
    $P0 = new 'Integer'
    $P0 = 0
    set_hll_global ['smart';'Grammar';'Actions'], '$?INCLUDE_LEVEL', $P0
    $P0 = new 'Integer'
    $P0 = 0
    set_hll_global ['smart';'Grammar';'Actions'], '$MACRO_NUM', $P0
    $P0 = new 'Integer'
    $P0 = 0
    set_hll_global ['smart';'Grammar';'Actions'], '$VARIABLE_NUM', $P0
    $P0 = new 'Integer'
    $P0 = 0
    set_hll_global ['smart';'Grammar';'Actions'], '$BLOCK_NUM', $P0
.end # sub "reset-global-variables"

=item
=cut
.sub "show-usage"
    $S0 = <<'END_USAGE'
Usage:
        TODO: show command usage.
END_USAGE
    say $S0
.end


=item <"override-variable-on-command-line"(name, value)>
=cut
.sub "override-variable-on-command-line" :anon
    .param string name
    .param string value
    $I0 = MAKEFILE_VARIABLE_ORIGIN_command_line
    $P0 = 'new:Variable'( name, value, $I0 )
    set_hll_global ['smart';'make';'variable'], name, $P0
.end # sub "override-variable-on-command-line"

=item <"!import-environment-variables"()>
=cut
.sub "!import-environment-variables" #:anon
    .local pmc env, it
    .local string name, value
    env = new 'Env'
    iter it, env
iterate_env:
    unless it goto iterate_env_end
    name = shift it
    value = env[name]
    $P0 = 'new:Variable'( name, value, MAKEFILE_VARIABLE_ORIGIN_environment )
    set_hll_global ['smart';'make';'variable'], name, $P0
    goto iterate_env
iterate_env_end:
.end # sub "!import-environment-variables"

=item
=cut
.sub "parse-command-line-arguments" :anon
    .param pmc args
    .local pmc new_args
    .local string command_name, target
    .local string smartfile
    smartfile = ""

    ## save the command line name
    command_name = shift args

    new_args = new 'ResizablePMCArray'
    push new_args, command_name
    
    .local int argc
    argc = args
    if argc == 0 goto guess_smartfile
    
    .local string arg
    .local pmc it
    arg = ""
    iter it, args
loop_args:
    unless it goto end_loop_args
    arg = shift it

check_arg_0: ## Smartfile specifying
    unless arg == "-f" goto check_arg_1
    unless it goto check_arg_0_bad
    $S0 = shift it
    smartfile = $S0
    stat $I0, smartfile, 0
    unless $I0 goto check_arg_0_smartfile_not_existed
    goto check_arg_end
check_arg_1: ## usage screen
    unless arg == "-h" goto check_arg_2
    'show-usage'()
    exit EXIT_OK
    goto check_arg_end
check_arg_2: ## variable overriding
    $S0 = substr arg, 0, 1
    if $S0 == "-" goto check_arg_3
    $I0 = index arg, "="
    if $I0 < 0 goto check_arg_3
    $S0 = substr arg, 0, $I0
    inc $I0
    $I1 = length arg
    $I1 = $I1 - $I0
    $S1 = substr arg, $I0, $I1
    'override-variable-on-command-line'($S0, $S1)
    goto check_arg_end
check_arg_3: ## environment-variable overriding flag
    unless arg == "-e" goto check_arg_4
    $P0 = new 'Integer'
    $P0 = 1
    set_hll_global ['smart'], "$-e", $P0
    goto check_arg_end
check_arg_4: ## 
    unless arg == "--warn-undefined-variables" goto check_arg_5
    $P0 = new 'Integer'
    $P0 = 1
    set_hll_global ['smart'], "$--warn-undefined-variables", $P0
    goto check_arg_end
check_arg_5: ## --target=xxx
    $I0 = index arg, "--target"
    unless $I0 == 0 goto check_arg_6
    $I0 += 8 ## the length of '--target'
    $I0 = index arg, "="
    if $I0 < 0 goto check_arg_6
    inc $I0
    $I1 = length arg
    $I1 = $I1 - $I0
    $S0 = substr arg, $I0, $I1
    push new_args, arg
    goto check_arg_end
check_arg_6: ## --compile/-c
    if arg == "-c" goto check_arg_6__mark_compiling
    if arg == "--compile" goto check_arg_6__mark_compiling
    goto check_arg_7
check_arg_6__mark_compiling:
    $P0 = new 'Integer'
    $P0 = 1
    set_hll_global ['smart'], "$--compile", $P0
    goto check_arg_end
check_arg_7: ##
check_arg_else:
    $S0 = substr arg, 0, 1
    if $S0 == "-" goto check_arg_unknown_flag
    goto check_arg_targets
    print "arg: "
    say arg
    push new_args, arg
    goto check_arg_end
check_arg_targets:
    get_hll_global $P0, ['smart';'make'], "@<?>"
    unless null $P0 goto got_target_list_variable
    $P0 = new 'ResizableStringArray'
    set_hll_global ['smart';'make'], "@<?>", $P0
    got_target_list_variable:
    push $P0, arg
    goto check_arg_end
check_arg_end:
    goto loop_args ## looping
    
check_arg_0_bad:
    $S0 = "smart: No argument for '-f', it requires one argument.\n"
    printerr $S0
    exit EXIT_ERROR_BAD_ARGUMENT
    
check_arg_0_smartfile_not_existed:
    $S0 = "smart: Smartfile '"
    $S0 .= smartfile
    $S0 .= "' not found.\n"
    printerr $S0
    exit EXIT_ERROR_NO_FILE
    
check_arg_unknown_flag:
    $S0 = "smart: Uknown command line flag '"
    $S0 .= arg
    $S0 .= "'\n"
    printerr $S0
    exit EXIT_ERROR_BAD_ARGUMENT
    
end_loop_args:
    
    ## TODO: support more arguments
    
    if smartfile == "" goto guess_smartfile
    goto done
    
guess_smartfile:
    .local pmc filenames
    filenames = new 'ResizableStringArray'
    push filenames, "smartfile"
    push filenames, "Smartfile"
    push filenames, "GNUmakefile"
    push filenames, "makefile"
    push filenames, "Makefile"
    iter it, filenames
iterate_filenames:
    unless it goto iterate_filenames_end
    $S0 = shift it
    stat $I0, $S0, 0
    unless $I0 goto iterate_filenames
    smartfile = $S0
    goto done
iterate_filenames_end:

done:
    if smartfile == "" goto no_smartfile_for_new_args

    ## Save smartfile
    new $P0, 'String'
    assign $P0, smartfile
    set_hll_global ['smart'], "$smartfile", $P0
    null $P0
    
    push new_args, smartfile
    .return (new_args)
    
no_smartfile_for_new_args:
    $S0 = "smart: No targets specified and no Smartfile found. Stop.\n"
    printerr $S0
    exit EXIT_ERROR_NO_SMARTFILE
.end # sub "parse-command-line-arguments"


=item main(args :slurpy)  :main
    Start compilation by passing any command line C<args>
    to the smart compiler.
=cut
.sub 'main' :main
    .param pmc args
    .local pmc smart
    .local pmc arguments

    #'!load-database'()
    #'!import-environment-variables'()
    arguments = 'parse-command-line-arguments'( args )

    .local string smartfile
    get_hll_global $P0, ['smart'], "$smartfile"
    set smartfile, $P0

    stat $I1, smartfile, .STAT_CHANGETIME
    
    set $S0, smartfile
    concat $S0, ".pbc"
    stat $I0, $S0, 0
    unless $I0 goto check_pir
    if $I0 < $I1 goto execute_smart

check_pir:
    set $S0, smartfile
    concat $S0, ".pir"
    stat $I0, $S0, 0
    unless $I0 goto execute_smart
    if $I0 < $I1 goto execute_smart

execute_parrot:
    .local string filename
    find_charset $I0, "ascii"
    trans_charset filename, $S0, $I0
    load_bytecode filename
    .return()

execute_smart:
    compreg smart, 'smart'
    
    "reset-global-variables"()
    'compile_if_updated'( smart, smartfile, "target"=>"pir" )
    
    "reset-global-variables"()
    $P1 = smart.'command_line'( arguments )
    #smart.'evalfiles'( smartfile )
    #goto execute
    .return()
.end

.include "gen/gen_builtins.pir"
.include "gen/gen_grammar.pir"
.include "gen/gen_actions.pir"
.include "src/parser/grammar.pir"
.include "src/parser/actions.pir"
.include "src/classes/all.pir"
.include "src/database.pir"
#.include "src/builtins/oper.pir"

=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

