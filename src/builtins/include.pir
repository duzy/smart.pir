#
#    Copyright 2009-02-02 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

=head1

include -- Include another Smartfile.

=cut

.namespace []

=item
=cut
.sub "include"
    .param string name
    .local pmc target
    #target = 'new:Target'( name ) ## create a new target
    target = ':TARGET'( name )

    $I0 = target.'exists'()
    if $I0 goto do_include
    $I0 = target.'update'()
    #if $I0 goto do_include
    #.return($I0)
    $I0 = target.'exists'()
    unless $I0 goto error_target_not_existed

do_include:
    .local pmc smart
    #get_hll_global smart, ['smart'], "$self"
    smart = compreg 'smart'

    get_hll_global $P0, ['smart';'Grammar';'Actions'], '$?INCLUDE_LEVEL'
    inc $P0
    
    $S0 = target
    stat $I0, $S0, 1
    open $P1, $S0
    read $S1, $P1, $I0
    close $P1
    null $P1
    $S1 = smart.'compile'( $S1, 'target'=>'pir' )

    $S0 = target
    concat $S0, ".pir"
    open $P1, $S0, "w"
    print $P1, $S1
    close $P1
    null $P1
    
    smart.'evalfiles'( target )
    dec $P0

    .return()

error_target_not_existed:
    $S0 = "smart: "
    $S0 .= name
    $S0 .= ": no such file or directory\n"
    printerr $S0
    #exit EXIT_ERROR_NO_FILE
    
.end # sub "include"
