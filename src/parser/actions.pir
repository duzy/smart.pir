#
#    Copyright 2008-10-27 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.info, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ["smart";"Grammar";"Actions"]

.namespace []

.sub "!BIND-VARIABLE"
    .param string name
    .local pmc var
    get_hll_global var, ['smart';'make';'variable'], name
    
    unless null var goto return_result
    $S0 = ""
    $I0 = MAKEFILE_VARIABLE_ORIGIN_file
    var = 'new:Variable'( name, $S0, $I0 )
    set_hll_global ['smart';'make';'variable'], name, var
    
return_result:
    .return(var)
.end # sub "!BIND-VARIABLE"

.sub "!set-var" :anon
    .param pmc var
    .param pmc val
    setattribute var, 'value', val
.end # sub "!set-var"

# .sub "vardecl:="
#     .param string name
#     .param string value
#     .local pmc var
#     var = '!BIND-VARIABLE'( name )
#     '!set-var'( var, value )
# .end # sub "vardecl:="

# .sub "vardecl::="
#     .param string name
#     .param string value
#     .local pmc var
#     var = '!BIND-VARIABLE'( name )
#     '!set-var'( var, value )
# .end # sub "vardecl::="

# .sub "vardecl:?="
#     .param string name
#     .param string value
#     .local pmc var
#     get_hll_global var, ['smart';'make';'variable'], name
#     if null var goto return_result
    
#     '!set-var'( var, value )
    
# return_result:
#     .return()
# .end # sub "vardecl:?="

# .sub "vardecl:+="
#     .param string name
#     .param string value
#     .local pmc var
#     var = '!BIND-VARIABLE'( name )
    
#     getattribute $P0, var, 'value'
#     if null $P0 goto set_value
#     $S0 = $P0
#     ##value = $S0 . value
#     concat value, $S0, value
    
# set_value:
#     '!set-var'( var, value )
# .end # sub "vardecl:+="

# .sub "varover:="
#     .param string name
#     .param string value
# .end # sub "varover:="

# .sub "varover::="
#     .param string name
#     .param string value
# .end # sub "varover::="

# .sub "varover:?="
#     .param string name
#     .param string value
# .end # sub "varover:?="

# .sub "varover:+="
#     .param string name
#     .param string value
# .end # sub "varover:+="


=item
=cut
.sub ":VARIABLE"
    .param string name
    .local pmc var
    get_hll_global var, ['smart';'make';'variable'], name
    .return(var)
.end # sub "!GET-VARIABLE"


=item
=cut
.sub "!UPDATE-GOALS"
    .local pmc targets
    .local pmc target
    .local pmc it
    
    ## the target list from command line arguments
    get_hll_global targets, ['smart';'make'], "@<?>"
    if null targets goto update_number_one_target
    #it = new 'Iterator', targets
    iter it, targets
iterate_command_line_targets:
    unless it goto end_iterate_command_line_targets
    $S0 = shift it
    get_hll_global target, ['smart';'make';'target'], $S0
    unless null target goto got_command_line_target
    target = 'new:Target'( $S0 )
    set_hll_global ['smart';'make';'target'], $S0, target
    got_command_line_target:
    ($I1, $I2, $I3) = target.'update'()
    if 0 < $I3 goto command_line_target_update_ok
    $S1 = "smart: Nothing to be done for target '"
    $S1 .= $S0
    $S1 .= "'\n"
    printerr $S1
    goto iterate_command_line_targets
    
    command_line_target_update_ok:
    $S1 = "smart: Target '"
    $S1 .= $S0
    $S1 .= "' updated(totally "
    $S2 = $I1
    $S1 .= $S2
    $S1 .= " objects).\n"
    printerr $S1
    goto iterate_command_line_targets
end_iterate_command_line_targets:
    .return ()
    
update_number_one_target:
    
    ## the number-one target from the Makefile(Smartfile)
    get_hll_global target, ['smart';'make'], "$<0>"
    if null target goto no_number_one_target
    
    ($I0, $I1, $I2) = target.'update'()
    
    .local string object
    object = target.'object'()
    
    if $I0 <= 0 goto nothing_updated
    if 0 < $I0 goto all_done
    
    $S0 = "smart: "
    $S0 .= object
    $S0 .= "' is up to date.\n"
    print $S0
    exit EXIT_OK
    
nothing_updated:
nothing_done:
    $S0 = "smart: Nothing to be done for '"
    $S0 .= object
    $S0 .= "'.\n"
    printerr $S0
    .return()
    
all_done:
#     $I1 = $I0 == 1
#     $I2 = $I2 <= 0
#     $I1 = and $I1, $I2
#     if $I2 goto nothing_done
    $S1 = $I0
    $S0 = "smart: Done, "
    $S0 .= $S1
    $S0 .= " targets updated.\n"
    print $S0
    .return()
    
no_number_one_target:
    printerr "smart: ** No targets. Stop.\n"
    exit EXIT_ERROR_NO_TARGETS
.end

.sub ":PACK"
    .param pmc args :slurpy
    .return (args)
.end

.sub "!PACK-RULE-TARGETS"
    .param pmc args :slurpy
    .local pmc result
    .local pmc it, ait
    result = new 'ResizablePMCArray'
    #it = new 'Iterator', args
    iter it, args
iterate_items:
    unless it goto iterate_items_end
    shift $P0, it
    typeof $S0, $P0
#     print $S0
#     print ": "
#     say $P0
    if $S0 == "Target" goto iterate_items__pack_Target
    if $S0 == "ResizablePMCArray" goto iterate_items__pack_ResizablePMCArray
    ## PS: Unknown type here will be ignored.
    goto iterate_items
    
iterate_items__pack_Target:
    push result, $P0
    goto iterate_items
    
iterate_items__pack_ResizablePMCArray:
    #ait = new 'Iterator', $P0
    iter ait, $P0
iterate_items__pack_ResizablePMCArray__iterate_array:
    unless ait goto iterate_items__pack_ResizablePMCArray__iterate_array_end
    $P1 = shift ait
#     print "     :"
#     say $P1
    push result, $P1
    goto iterate_items__pack_ResizablePMCArray__iterate_array
iterate_items__pack_ResizablePMCArray__iterate_array_end:
    goto iterate_items
    
iterate_items_end:
    .return (result)
.end # sub "!PACK-RULE-TARGETS"

.sub "!MAKE-TARGETS"
    .param string a_targets
    .param pmc rule
    .local pmc targets
.end # sub "!MAKE-TARGETS"

.sub "!CHECK-PATTERN"
    .param string text
    ## $I0 will be used to store the result value
    set $I0, 0
    index $I1, text, "%"
    if $I1 < 0          goto return_result
    $I2 = $I1 + 1
    index $I2, text, "%", $I2
    unless $I2 < 0      goto return_result
    set $I0, 1
return_result:
    .return($I0)
.end # sub "!CHECK-PATTERN"

.sub "!CHECK-AND-STORE-PATTERN-TARGET"
    .param string text
    .param pmc rule

    .local pmc out_statics
    out_statics = rule.'static-targets'()

    ## $I0 will be used to store the result value
    set $I0, 0

    index $I1, text, "%"
    if $I1 < 0          goto return_result
    $I2 = $I1 + 1
    index $I2, text, "%", $I2
    unless $I2 < 0      goto return_result

    .local pmc pattern_targets
    get_hll_global pattern_targets, ['smart';'make'], "@<%>"
    unless null pattern_targets goto check_and_handle_pattern_target_go
    new pattern_targets, 'ResizablePMCArray'
    set_hll_global ['smart';'make'], "@<%>", pattern_targets
    
check_and_handle_pattern_target_go:

    ( $S0, $P0 ) = '!CHECK-AND-SPLIT-ARCHIVE-MEMBERS'( text )
    if $S0 == "" goto check_and_handle_pattern_target__store_normal_pattern
    
    #new $P1, 'Iterator', $P0
    iter $P1, $P0
iterate_arcives:
    unless $P1 goto iterate_arcives_end
    shift $S0, $P1
    $P2 = 'new:Target'( $S0 )
    $P3 = 'new:Pattern'( $S0 )
    setattribute $P2, 'object', $P3
    getattribute $P10, $P2, 'updators'
    push $P10, rule ## bind the rule with the pattern target
    push pattern_targets, $P2
    goto iterate_arcives
iterate_arcives_end:
    #set implicit, 1 ## flag implicit for the rule
    set $I0, 1 ## set the result
    null $P1
    null $P2
    null $P3
    goto return_result

check_and_handle_pattern_target__store_normal_pattern:
    $P1 = 'new:Target'( text )
    $P2 = 'new:Pattern'( text )
    setattribute $P1, 'object', $P2 ## reset the target's object attribute
    getattribute $P10, $P1, 'updators'
    push $P10, rule ## bind the rule with the pattern target
    null $P2
    null $P10

    ## If static rule, the pattern target will not be stored, but bind with
    ## the static targets instead
    .local pmc cs
    new cs, "ResizableIntegerArray"
    #bsr bind_static_targets
    local_branch cs, bind_static_targets
    if $I0 goto return_result
    
    if text == "%" goto check_and_handle_pattern_target__store_match_anything
    
check_and_handle_pattern_target__store_pattern_target:
    push pattern_targets, $P1
    null $P1
    null pattern_targets
    set $I0, 1 ## set the result
    goto return_result
    
check_and_handle_pattern_target__store_match_anything:
    set_hll_global ['smart';'make'], "$<%>", $P1
    set $I0, 1 ## set the result
    goto return_result
    
    
bind_static_targets:
    if null out_statics goto bind_static_targets_done
    .local pmc sit, st
    #new sit, 'Iterator', out_statics
    iter sit, out_statics
iterate_static_targets:
    unless sit goto iterate_static_targets_end
    shift st, sit
    ## Bind the static targets with the target-pattern
    getattribute $P10, st, 'updators'
    push $P10, $P1 ## $P1 should be the target-pattern
    goto iterate_static_targets
iterate_static_targets_end:
    set $I0, 1 ## set the result
    
bind_static_targets_done:
    #ret
    local_return cs
    
return_result:
    .return ($I0)
.end # sub "!CHECK-AND-STORE-PATTERN-TARGET"

=item
=cut
.sub ":MAKE-PATTERN-TARGET"
    .param string name
    .param pmc rule
    .local pmc target
    .local pmc pattern
    target = 'new:Target'( name )
    pattern = 'new:Pattern'( name )
    setattribute target, 'object', pattern ## reset the target's object attribute
    getattribute $P10, target, 'updators'
    push $P10, rule ## bind the rule with the pattern target
    .return(target)
.end # sub ":MAKE-PATTERN-TARGET"

=item
=cut
.sub ":STORE-PATTERN-TARGET"
    .param pmc pattern_target
    
    .local pmc pattern_targets
    get_hll_global pattern_targets, ['smart';'make'], "@<%>"
    
    unless null pattern_targets goto push_pattern_target
    new pattern_targets, 'ResizablePMCArray'
    set_hll_global ['smart';'make'], "@<%>", pattern_targets

push_pattern_target:
    push pattern_targets, pattern_target
.end # sub ":STORE-PATTERN-TARGET"

=item
@returns 1 if succeed, or 0.
=cut
.sub "!CHECK-AND-SPLIT-ARCHIVE-MEMBERS"
    .param string text
    
    set $S0, ""
    null $P0
    
    index $I1, text, "("
    if $I1 < 0 goto check_and_split_archive_members_done
    index $I2, text, ")", $I1
    if $I2 < 0 goto check_and_split_archive_members_done
    substr $S1, text, 0, $I1
    inc $I1
    $I2 = $I2 - $I1
    substr $S2, text, $I1, $I2
    
    $S0 = 'strip'( $S1 )
    #split $P0, $S2, " "
    $P3 = '~expanded-items'( $S2 )
    null $P1
    null $P2
    new $P0, 'ResizableStringArray'
    #new $P1, 'Iterator', $P3
    iter $P1, $P3
check_and_split_archive_members__iterate:
    unless $P1 goto check_and_split_archive_members__iterate_end
    shift $P2, $P1
    #$S1 = 'strip'( $P2 )
    set $S2, $P2
    clone $S1, $S0
    concat $S1, "("
    concat $S1, $S2
    concat $S1, ")"
    push $P0, $S1
    goto check_and_split_archive_members__iterate
check_and_split_archive_members__iterate_end:
    
    null $S1
    null $S2
    null $P1
    null $P2

check_and_split_archive_members_done:
    .return( $S0, $P0 )
.end # sub "!CHECK-AND-SPLIT-ARCHIVE-MEMBERS"

.sub "!HAS-WILDCARD"
    .param string text
    
check_wildcard_prerequsite:
    $I0 = 0
check_wildcard_prerequsite__case1:
    index $I1, text, "*"
    if $I1 < 0 goto check_wildcard_prerequsite__case2
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case2:
    index $I1, text, "?"
    if $I1 < 0 goto check_wildcard_prerequsite__case3
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case3:
    index $I1, text, "["
    if $I1 < 0 goto check_wildcard_prerequsite__case4
    index $I2, text, "]", $I1
    if $I2 < 0 goto check_wildcard_prerequsite__case4
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case4:
    ## more other case?
    goto check_wildcard_prerequsite__done

check_wildcard_prerequsite__done_yes:
    $I0 = 1
check_wildcard_prerequsite__done:
    .return($I0)
.end # "!HAS-WILDCARD"

.sub "!WILDCARD-PREREQUISITE"
    .param pmc prerequisites ## *OUT/unshift*
    .param string text
    
check_wildcard_prerequsite:
    $I0 = 0
check_wildcard_prerequsite__case1:
    index $I1, text, "*"
    if $I1 < 0 goto check_wildcard_prerequsite__case2
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case2:
    index $I1, text, "?"
    if $I1 < 0 goto check_wildcard_prerequsite__case3
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case3:
    index $I1, text, "["
    if $I1 < 0 goto check_wildcard_prerequsite__case4
    index $I2, text, "]", $I1
    if $I2 < 0 goto check_wildcard_prerequsite__case4
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case4:
    ## more other case?
    goto check_wildcard_prerequsite__done
    
check_wildcard_prerequsite__done_yes:
    $P1 = '~wildcard'( text )
    #new $P2, 'Iterator', $P1
    iter $P2, $P1
check_wildcard_prerequsite__done_yes__iterate_items:
    unless $P2 goto check_wildcard_prerequsite__done_yes__iterate_items__end
    shift $S1, $P2
#     print "wildcard: "
#     say $S1
    $P1 = '!BIND-TARGET'( $S1, TARGET_TYPE_NORMAL )
    push prerequisites, $P1
    goto check_wildcard_prerequsite__done_yes__iterate_items
check_wildcard_prerequsite__done_yes__iterate_items__end:
    null $P1
    $I0 = 1
check_wildcard_prerequsite__done:
    .return($I0)
.end # sub "!WILDCARD-PREREQUISITE"

=item
=cut
.sub "!CHECK-AND-CONVERT-SUFFIX"
    .param string text

    .local string pat1
    .local string pat2

    .local pmc cs
    new cs, 'ResizableIntegerArray'

check_and_convert_suffix_target:
    set $I0, 0
    substr $S0, text, 0, 1
    unless $S0 == "." goto check_and_convert_suffix_target__done
    index $I1, text, ".", 1
    unless $I1 < 0 goto check_and_convert_suffix_target__check_two_suffixes
    set $I0, 1 ## tells number of suffixes
    
    $S3 = text ## check the suffix
    #bsr check_and_convert_suffix_target__check_suffixes
    local_branch cs, check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    ## ".c:" => "%: %.c"
    pat1 = "%"
    pat2 = "%"
    pat2 .= text
    
    goto check_and_convert_suffix_target__done
    
check_and_convert_suffix_target__check_two_suffixes:
    unless 2 <= $I1 goto check_and_convert_suffix_target__done ## avoid ".."
    $I2 = $I1 + 1
    $I2 = index text, ".", $I2  ## no third "." should existed
    unless $I2 < 0 goto check_and_convert_suffix_target__done
    $I2 = length text
    $I2 = $I2 - $I1
    $I0 = 2 ## tells number of suffixes
    $S0 = substr text, 0, $I1 ## the first suffix
    $S1 = substr text, $I1, $I2 ## the second suffix
    
    $S3 = $S0 ## check the first suffix
    #bsr check_and_convert_suffix_target__check_suffixes
    local_branch cs, check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    $S3 = $S1 ## check the second suffix
    #bsr check_and_convert_suffix_target__check_suffixes
    local_branch cs, check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    ## ".c.o:" => "%.o:%.c"
    pat1 = "%"
    pat1 .= $S1
    pat2 = "%"
    pat2 .= $S0
    
check_and_convert_suffix_target__done:
    .return(pat1, pat2)
    
    
    ######################
    ## local: check_and_convert_suffix_target__check_suffixes
    ##          IN: $S3
    ##          OUT: $I1
check_and_convert_suffix_target__check_suffixes:
    .local pmc suffixes
    get_hll_global suffixes, ['smart';'make';'rule'], ".SUFFIXES"
    if null suffixes goto check_and_convert_suffix_target__check_suffixes__done
    #$P0 = new 'Iterator', suffixes
    iter $P0, suffixes
    $I1 = 0
check_and_convert_suffix_target__iterate_suffixes:
    unless $P0 goto check_and_convert_suffix_target__iterate_suffixes_done
    $S4 = shift $P0
    unless $S4 == $S3 goto check_and_convert_suffix_target__iterate_suffixes
    inc $I1
check_and_convert_suffix_target__iterate_suffixes_done:
    null $P0
    if $I1 goto check_and_convert_suffix_target__check_suffixes__done
    $S4 = "smart: Unknown suffix '"
    $S4 .= $S3
    $S4 .= "'\n"
    print $S4
check_and_convert_suffix_target__check_suffixes__done:
    #ret
    local_return cs
.end # sub "!CHECK-AND-CONVERT-SUFFIX"

=item
=cut
.sub "!CONVERT-SUFFIX-TARGET"
    .param pmc prerequisites ## *OUT*
    .param string text ## *IN* *OUT/modifying*

    .local pmc cs
    new cs, 'ResizableIntegerArray'
    
    ######################
    ## local: check_and_convert_suffix_target
    ##          IN: text(the target name)
    ##          OUT: text(modified into pattern if suffix detected)
check_and_convert_suffix_target:
    set $I0, 0
    substr $S0, text, 0, 1
    unless $S0 == "." goto check_and_convert_suffix_target__done
    index $I1, text, ".", 1
    unless $I1 < 0 goto check_and_convert_suffix_target__check_two_suffixes
    set $I0, 1 ## tells number of suffixes
    
    $S3 = text
    #bsr check_and_convert_suffix_target__check_suffixes
    local_branch cs, check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
#     print "one-suffix-rule: "   #!!!
#     say text                    #!!!

    $S2 = "%"
    $S2 .= text ## implicit:  %.text
    unshift prerequisites, $S2
    text = "%"
    
    goto check_and_convert_suffix_target__done
    
check_and_convert_suffix_target__check_two_suffixes:
    unless 2 <= $I1 goto check_and_convert_suffix_target__done ## avoid ".."
    $I2 = $I1 + 1
    $I2 = index text, ".", $I2  ## no third "." should existed
    unless $I2 < 0 goto check_and_convert_suffix_target__done
    $I2 = length text
    $I2 = $I2 - $I1
    $I0 = 2 ## tells number of suffixes
    $S0 = substr text, 0, $I1 ## the first suffix
    $S1 = substr text, $I1, $I2 ## the second suffix
    
    $S3 = $S0
    #bsr check_and_convert_suffix_target__check_suffixes
    local_branch cs, check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    $S3 = $S1
    #bsr check_and_convert_suffix_target__check_suffixes
    local_branch cs, check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
#     print "two-suffix-rule: "   #!!!
#     print $S0                   #!!! 
#     print ", "                  #!!!
#     say $S1                     #!!!

    text = "%"
    text .= $S1
    $S2 = "%"
    $S2 .= $S0 ## implicit: %.$S0
    unshift prerequisites, $S2
    
check_and_convert_suffix_target__done:
    .return(text)
    
    
    ######################
    ## local: check_and_convert_suffix_target__check_suffixes
    ##          IN: $S3
    ##          OUT: $I1
check_and_convert_suffix_target__check_suffixes:
    .local pmc suffixes
    get_hll_global suffixes, ['smart';'make';'rule'], ".SUFFIXES"
    if null suffixes goto check_and_convert_suffix_target__check_suffixes__done
    #$P0 = new 'Iterator', suffixes
    iter $P0, suffixes
    $I1 = 0
check_and_convert_suffix_target__iterate_suffixes:
    unless $P0 goto check_and_convert_suffix_target__iterate_suffixes_done
    $S4 = shift $P0
    unless $S4 == $S3 goto check_and_convert_suffix_target__iterate_suffixes
    inc $I1
check_and_convert_suffix_target__iterate_suffixes_done:
    null $P0
    if $I1 goto check_and_convert_suffix_target__check_suffixes__done
    $S4 = "smart: Unknown suffix '"
    $S4 .= $S3
    $S4 .= "'\n"
    print $S4
check_and_convert_suffix_target__check_suffixes__done:
    #ret
    local_return cs
   
.end # sub '!CONVERT-SUFFIX-TARGET'

.sub ":PHONY-RULE"
    .param pmc items
    
    .local pmc array
    get_hll_global array, ['smart';'make';'rule'], ".PHONY"
    unless null array goto push_items
    
    array = new 'ResizableStringArray'
    set_hll_global ['smart';'make';'rule'], ".PHONY", array
    
push_items:
    
#     $S0 = join ' ', items
#     $P1 = '~expanded-items'( $S0 )
#     $P2 = new 'Iterator', $P1
# convert_items_into_array__iterate_items:
#     unless $P2 goto convert_items_into_array__iterate_items_end
#     $P1 = shift $P2
#     push array, $P1
#     goto convert_items_into_array__iterate_items
# convert_items_into_array__iterate_items_end:
# convert_items_into_array__done:
    #new $P1, 'Iterator', items
    iter $P1, items
iterate_items:
    unless $P1 goto iterate_items_end
    shift $P0, $P1
    push array, $P0
    goto iterate_items
iterate_items_end:

.end # sub ":PHONY-RULE"

.sub ":SUFFIXES-RULE"
    .param pmc items
    
    .local pmc array
    get_hll_global array, ['smart';'make';'rule'], ".SUFFIXES"
    unless null array goto push_items
    
    array = new 'ResizableStringArray'
    set_hll_global ['smart';'make';'rule'], ".SUFFIXES", array
    
push_items:
    
    #new $P1, 'Iterator', items
    iter $P1, items
iterate_items:
    unless $P1 goto iterate_items_end
    shift $P0, $P1
    push array, $P0
    goto iterate_items
iterate_items_end:
.end # sub ":SUFFIXES-RULE"

=item
":SPECIAL-RULE"
=cut
.sub ":SPECIAL-RULE"
    .param string name
    .param pmc items

    print "TODO: special rule '"
    print name
    print "'\n"
    
    .return()

    .local pmc cs
    new cs, 'ResizableIntegerArray'


    ######################
    ## local routine: update_special_array_rule
    ##          IN: $S0(the name of the rule)
update_special_array_rule:
    .local pmc array
    get_hll_global array, ['smart';'make';'rule'], $S0
    unless null array goto update_special_PHONY__got_phony_array
    array = new 'ResizableStringArray'
    set_hll_global ['smart';'make';'rule'], $S0, array
update_special_PHONY__got_phony_array:
    $P0 = array
    #bsr convert_items_into_array
    #ret
    local_branch cs, convert_items_into_array
    local_return cs
    
    ######################
    ## local routine: convert_items_into_array
    ##          IN: $P0 (a ResizableStringArray)
    ##          OUT: $P0 (modifying)
convert_items_into_array:
    $S0 = join ' ', items
    $P1 = '~expanded-items'( $S0 )
    #$P2 = new 'Iterator', $P1
    iter $P2, $P1
convert_items_into_array__iterate_items:
    unless $P2 goto convert_items_into_array__iterate_items_end
    $P1 = shift $P2
    push $P0, $P1
    ##print "item: "
    ##say $P1
    goto convert_items_into_array__iterate_items
convert_items_into_array__iterate_items_end:
convert_items_into_array__done:
    #ret
    local_return cs

.end # sub :SPECIAL-RULE


.sub "!BIND-TARGETS-BY-EXPANDING-STRING"
    .param string str
    .local pmc items
    .local pmc result
    new result, 'ResizablePMCArray'
    items = '~expanded-items'( str )
    #$P0 = new 'Iterator', items
    iter $P0, items
iterate_items:
    unless $P0 goto iterate_items_end
    $S0 = shift $P0
#     say $S0
    $P1 = '!BIND-TARGET'( $S0, 0 )
    push result, $P1
    goto iterate_items
iterate_items_end:
    
    .return(result)
.end


=item <'!BIND-TARGET'(IN name, OPT is_rule)>
    Create or bind(if existed) 'name' to a makefile target object.

    While target is updating(C<Target::update>), implicit targets will
    be created on the fly, and the created implicit targets will be stored.
=cut
.sub "!BIND-TARGET"
    .param string name
    .param int type       ## target type, se constants.pir
    .local pmc target
    .local string name
    
    get_hll_global target, ['smart';'make';'target'], name
    if null target goto create_new_makefile_target
    .return (target)
    
create_new_makefile_target:
    target = 'new:Target'( name )
    
    ## store the new target object
    ## TODO: should escape implicit targets(patterns)?
    set_hll_global ['smart';'make';'target'], name, target
    
    .return(target)
.end # sub "!BIND-TARGET"

=item
=cut
.sub ":TARGET"
    .param string name
    .param pmc updator :optional
    .local pmc target

    get_hll_global target, ['smart';'make';'target'], name
    
    unless null target goto push_updator
    
    target = 'new:Target'( name ) ## create a new target 
    set_hll_global ['smart';'make';'target'], name, target
    
push_updator:
    if null updator goto return_result
    
    getattribute $P0, target, 'updators'
    elements $I0, $P0
    unless 0 < $I0 goto just_push_it

    ## New updator should always take the first position,
    ## the previous updator at the beginning be moved behind.
    ## 
    ## NOTE that the actions of the first updator will be executed
    ## while updating.
    $P1 = $P0[0]
    $P0[0] = updator
    push $P0, $P1
    
    goto return_result
    
just_push_it:
    push $P0, updator ## bind the target with the updator
    
return_result:
    .return (target)
.end # sub ":TARGET"

=item
=cut
.sub ":DEFAULT-GOAL"
    .param pmc numberOneTarget

    if null numberOneTarget goto return_result
    
    ## the first rule should defines the number-one target
    get_hll_global $P0, ['smart';'make'], "$<0>"
    
    unless null $P0 goto return_result
    
    $S0 = numberOneTarget #.'object'()
    
    set_hll_global ['smart';'make'], "$<0>", numberOneTarget
    
    $P1 = 'new:Variable'( ".DEFAULT_GOAL", $S0, MAKEFILE_VARIABLE_ORIGIN_automatic )
    set_hll_global ['smart';'make';'variable'], ".DEFAULT_GOAL", $P1
    
return_result:
    .return()
.end # sub ":DEFAULT-GOAL"

# =item
# =cut
# .sub "!GET-TARGET"
#     .param string name
#     get_hll_global $P0, ['smart';'make';'target'], name
#     .return($P0)
# .end # sub "!GET-TARGET"

