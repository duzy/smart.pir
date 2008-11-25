# $Id$

=begin comments

foo::Grammar::Actions - ast transformations for foo

This file contains the methods that are used by the parse grammar
to build the PAST representation of an foo program.
Each method below corresponds to a rule in F<src/parser/grammar.pg>,
and is invoked at the point where C<{*}> appears in the rule,
with the current match object as the first argument.  If the
line containing C<{*}> also has a C<#= key> comment, then the
value of the comment is passed as the second argument to the method.

=end comments

=cut

class smart::Grammar::Actions;

method TOP($/, $key) {
    our $?BLOCK;
    our @?BLOCK;

    if $key eq 'enter' {
	$?BLOCK := PAST::Block.new( :blocktype('declaration'), :node( $/ ) );
	@?BLOCK.unshift( $?BLOCK );
    }
    else { # while leaving the block
	my $past := @?BLOCK.shift();
	for $<statement> {
	    $past.push( $( $_ ) );
        }

        # push last op to the block to active target updating
        $past.push( PAST::Op.new( :name('!update-makefile-targets'),
          :pasttype('call'),
          :node( $/ )
        ) );

        make $past;
    }
}

method statement($/, $key) {
    ## get the field stored in $key from the $/ object
    ## and retrieve the result object from that field
    make $( $/{$key} );
}

method empty_smart_statement($/) { make PAST::Op.new( :pirop('noop') ); }

method makefile_variable_declaration($/) {
    my $var := PAST::Var.new(
        :name( trim_spaces(~$<name>) ),
          :scope('package'),
          :namespace('smart::makefile::variable'),
          #:scope('lexical'),
          :viviself('Undef'),
          :lvalue(1),
          :isdecl(1)
    );

    my $ctr := PAST::Op.new( :pasttype('call'),
      :name('!update-makefile-variable'),
      :returns('MakefileVariable') );
    for $<makefile_variable_value_list><item> {
        $ctr.push( PAST::Val.new( :value( ~$_ ), :returns('String') ) );
    }

    my $sign := ~$<sign>;
    $ctr.unshift( PAST::Val.new( :value($sign), :returns('String') ) );
    $ctr.unshift( PAST::Val.new( :value($var.name()), :returns('String') ) );

    make PAST::Op.new( $var, $ctr,
                       :pasttype('bind'),
                       :name('bind-makefile-variable-variable'),
                       :node( $/ )
                   );
}

method makefile_variable_method_call($/) {
    my $past := PAST::Op.new( $( $<makefile_variable_ref> ),
        :name( ~$<ident> ), :pasttype( 'callmethod' ) );
    for $<expression> {
        $past.push( $( $_ ) );
    }
    make $past;
}
method makefile_variable_ref($/) {
    my $name;
    if $<makefile_variable_ref1> {
        $name := ~$<makefile_variable_ref1><name>;
    }
    elsif $<makefile_variable_ref2> {
        $name := ~$<makefile_variable_ref2><name>;
    }
    my $var := PAST::Var.new( :name($name),
      :scope('package'),
      :namespace('smart::makefile::variable'),
      #:scope('lexical'),
      :viviself('Undef'),
      :lvalue(0),
      :node($/)
    );
    my $binder := PAST::Op.new( :pasttype('call'),
      #:name('!bind-makefile-variable'),
      :name('!update-makefile-variable'),
      :returns('MakefileVariable') );
    $binder.push( PAST::Val.new( :value($var.name()), :returns('String') ) );
    $binder.push( PAST::Val.new( :value(""), :returns('String') ) );

    make PAST::Op.new( $var, $binder,
                       :pasttype('bind'),
                       :name('bind-makefile-variable-variable'),
                   );
}

method makefile_rule($/) {
    if ( $<makefile_special_rule> ) {
        make $( $<makefile_special_rule> );
    }
    else {
        my $pack_targets := PAST::Op.new( :pasttype('call'),
          :name('!pack-args-into-array'), :returns('ResizablePMCArray') );
        for $<makefile_target> { $pack_targets.push( $( $_ ) ); }

        my $pack_prerequisites := PAST::Op.new( :pasttype('call'),
          :name('!pack-args-into-array'), :returns('ResizablePMCArray') );
        for $<makefile_prerequisite> { $pack_prerequisites.push( $( $_ ) ); }

        my $pack_actions := PAST::Op.new( :pasttype('call'),
          :name('!pack-args-into-array'), :returns('ResizablePMCArray') );
        for $<makefile_rule_action> { $pack_actions.push( $( $_ ) ); }

        my $match := ~$<targets>;
        $match := trim_spaces( $match );
        my $rule := PAST::Var.new( :lvalue(1), :viviself('Undef'),
           :scope('package'), :name($match), :namespace('smart::makefile::rule') );
        my $rule_ctr := PAST::Op.new( :pasttype('call'),
          :name('!update-makefile-rule'), :returns('MakefileRule')
        );
        $rule_ctr.push( PAST::Val.new( :value($match), :returns('String') ) );
        $rule_ctr.push( $pack_targets );
        $rule_ctr.push( $pack_prerequisites );
        $rule_ctr.push( $pack_actions );

        make PAST::Op.new( $rule, $rule_ctr,
                       :pasttype('bind'),
                       :name('bind-makefile-rule-variable'),
                       :node( $/ ) );
    }
}
method makefile_target($/) {
    if $<makefile_variable_ref> {
        make $( $<makefile_variable_ref> );
    }
    else {
        my $name := trim_spaces( ~$/ );
        my $t := PAST::Var.new( :name($name),
          :lvalue(0),
          :isdecl(1),
          :viviself('Undef'),
          :scope('lexical'),
          :node( $/ )
        );
        my $c := PAST::Op.new( :pasttype('call'), :returns('MakefileTarget'),
          :name('!bind-makefile-target') );
        $c.push( PAST::Val.new( :value($t.name()), :returns('String') ) );
        $c.push( PAST::Val.new( :value(1), :returns('Integer') ) );
        make PAST::Op.new( $t, $c, :pasttype('bind'),
                           :name('bind-makefile-target-variable'),
                           :node($/) );
    }
}
method makefile_prerequisite($/) {
    if $<makefile_variable_ref> {
        make $( $<makefile_variable_ref> );
    }
    else {
        my $p := PAST::Var.new( :name(~$/),
          :lvalue(0),
          :isdecl(1),
          :viviself('Undef'),
          :scope('lexical') );
        my $c := PAST::Op.new( :pasttype('call'),
          :name('!bind-makefile-target'), :returns('MakefileTarget') );
        $c.push( PAST::Val.new( :value($p.name()), :returns('String') ) );
        $c.push( PAST::Val.new( :value(0), :returns('Integer') ) );
        make PAST::Op.new( $p, $c, :pasttype('bind'),
                           :name('bind-makefile-prerequisite'),
                           :node($/) );
    }
}
method makefile_rule_action($/) {
    my $past := PAST::Op.new( :pasttype('call'), :returns('MakefileAction'),
      :name('!create-makefile-action'), :node($/) );
    $past.push( PAST::Val.new( :value(~$/), :returns('String') ) );
    make $past;
}

method makefile_special_rule($/) {
    my $past := PAST::Op.new( :pasttype('call'),
      :name('!update-special-makefile-rule') );
    $past.push( PAST::Val.new( :value(~$<name>), :returns('String') ) );
    for $<item> {
        $past.push( PAST::Val.new( :value(~$_), :returns('String') ) );
    }
    make $past;
}

method makefile_conditional_statement($/) {
    our $?BLOCK;
    my $arg1 := ~$<arg1>;
    my $arg2 := ~$<arg2>;
    my $stat := ~$<stat>;
    my $cond := 0;

    if $stat eq 'ifeq' {
        $cond := ( $arg1 eq $arg2 );
    }
    #elsif $stat eq 'ifneq' {
    else {
        $cond := ( $arg1 ne $arg2 );
    }

    my $pir;
    #if $arg1 eq $arg2 {
    if $cond {
        $pir := "print 'args: (if)'\n"
            ~ "print %0\n"
            ~ "print ', '\n"
            ~ "say %1\n"
            ;
        for $<if_stat> {
            $?BLOCK.push( $( $_ ) );
        }
    }
    else {
        $pir := "print 'args: (else)'\n"
            ~ "print %0\n"
            ~ "print ', '\n"
            ~ "say %1\n"
            ;
        for $<else_stat> {
            $?BLOCK.push( $( $_ ) );
        }
    }

    my $p := PAST::Op.new( :inline($pir) );
    $p.push( PAST::Val.new( :value(~$arg1), :returns('String') ) );
    $p.push( PAST::Val.new( :value(~$arg2), :returns('String') ) );
    make $p;
}

method smart_say_statement($/) {
    my $past := PAST::Op.new( :name('say'), :pasttype('call'), :node( $/ ) );
    for $<expression> {
        $past.push( $( $_ ) );
    }
    make $past;
}

##  expression:
##    This is one of the more complex transformations, because
##    our grammar is using the operator precedence parser here.
##    As each node in the expression tree is reduced by the
##    parser, it invokes this method with the operator node as
##    the match object and a $key of 'reduce'.  We then build
##    a PAST::Op node using the information provided by the
##    operator node.  (Any traits for the node are held in $<top>.)
##    Finally, when the entire expression is parsed, this method
##    is invoked with the expression in $<expr> and a $key of 'end'.
method expression($/, $key) {
    if ($key eq 'end') {
        make $($<expr>);
    }
    else {
        my $past := PAST::Op.new( :name($<type>),
                                  :pasttype($<top><pasttype>),
                                  :pirop($<top><pirop>),
                                  :lvalue($<top><lvalue>),
                                  :node($/)
                                );
        for @($/) {
            $past.push( $($_) );
        }
        make $past;
    }
}


##  term:
##    Like 'statement' above, the $key has been set to let us know
##    which term subrule was matched.
method term($/, $key) { make $( $/{$key} ); }

method value($/, $key) {
    make $( $/{$key} );
}

method integer($/) {
    make PAST::Val.new( :value( ~$/ ), :returns('Integer'), :node($/) );
}

method quote($/) {
    make PAST::Val.new( :value( $($<string_literal>) ), :node($/) );
}



# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

