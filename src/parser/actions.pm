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

sub ref_makefile_variable( $/, $name ) {
    our $?Makefile;

    #$name := chop_spaces( $name );

    if !$?Makefile.symbol( $name ) {
	$/.panic( 'Makefile Variable undeclaraed by \''~$name~"'" );
    }

    return PAST::Var.new( :name( $name ),
			  :scope('lexical'),#('package'),
			  :viviself('Undef'),
			  :lvalue(0)
			);
}

method TOP($/, $key) {
    our $?BLOCK;
    our @?BLOCK;
    our $?Makefile;

    if $key eq 'enter' {
	$?BLOCK := PAST::Block.new( :blocktype('declaration'), :node( $/ ) );
	@?BLOCK.unshift( $?BLOCK );

        #$?Makefile := PAST::Block.new(:blocktype('declaration'), :node( $/ ));
        $?Makefile := $?BLOCK;
    }
    else { # while leaving the block
	my $past := @?BLOCK.shift();
	for $<statement> {
	    $past.push( $( $_ ) );
        }

        # push last op to the block to active target updating
        $past.push( PAST::Op.new( :name('!update-makefile-number-one-target'),
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
    if $<makefile_variable_assign> {
        my $var := $( $<makefile_variable> );
        my $ctr := $( $<makefile_variable_value_list> );
        my $name := $var.name();
        $ctr.unshift( PAST::Val.new( :value($name), :returns('String') ) );

        $var.lvalue( 1 );
        $var.isdecl( 1 );
        #$var.scope( 'lexical' );
        #$var.node( $?Makefile );

        $ctr.name('!create-makefile-variable');

        our $?Makefile;
        if $?Makefile.symbol( $name ) {
            my $assign := ~$<makefile_variable_assign>;
            if $assign eq '+=' {
                $ctr.name('!append-makefile-variable');
            }
        }
        else {
            $?Makefile.symbol( $name, :scope('lexical') );
            #$ctr.name('!create-makefile-variable');
        }

        make PAST::Op.new( $var, $ctr,
                           :name('bind-makefile-variable-object'),
                           :pasttype('bind'),
                       );
    }
}

#method makefile_variable($/) {
#    make PAST::Var.new( :name( ~$/ ),
#			:scope('lexical'),#('package'),
#			:viviself('Undef'),
#			:lvalue(1)
#		      );
#}

method makefile_variable_value_list($/) {
    my $past := PAST::Op.new( :pasttype('call'),
                              :returns('MakefileVariable'),
                              :node($/)
                            );
    for $<makefile_variable_value_item> {
        $past.push( $( $_ ) );
    }
    make $past;
}
method makefile_variable_value_item($/) {
    make PAST::Val.new( :value( ~$/ ), :returns('String'), :node($/) );
}

method makefile_variable_method_call($/) {
    my $past := PAST::Op.new( $( $<makefile_variable_ref> ),
        :name( ~$<ident> ),
	:pasttype( 'callmethod' )
       );
    for $<expression> {
        $past.push( $( $_ ) );
    }
    make $past;
}

method makefile_rule($/) {
    my $target  := $( $<makefile_target> );
    $target.lvalue( 1 );
    $target.isdecl( 1 );
    $target.scope('lexical');

    my $name    := $target.name();
    my $match   := $name;

    my $target_ctr     := PAST::Op.new( :pasttype('call'),
      :name('!bind-makefile-target'),
      :returns('MakefileTarget'),
      :node( $/ )
    );
    my $pack_deps := PAST::Op.new( :pasttype('call'),
      :name('!pack-args-into-array'),
      :returns('ResizablePMCArray'),
      :node($/)
    );
    my $pack_actions := PAST::Op.new( :pasttype('call'),
      :name('!pack-args-into-array'),
      :returns('ResizablePMCArray'),
      :node($/)
    );
    for $<makefile_target_dep> {
        my $dep := $( $_ );
        $dep.lvalue( 0 );
        $dep.isdecl( 1 );
        $dep.scope('lexical');
        ##bind dep to the target object
        my $dep_ctr := PAST::Op.new( :pasttype('call'),
          :name('!bind-makefile-target'),
          :returns('MakefileTarget')
        );
        $dep_ctr.push( PAST::Val.new( :value($dep.name()), :returns('String') ) );
        my $op := PAST::Op.new( $dep, $dep_ctr, :pasttype('bind'),
                                :name('bind-makefile-target')
                            );
        $pack_deps.push( $op );
    }
    for $<makefile_rule_action> { $pack_actions.push( $( $_ ) ); }

    $target_ctr.push( PAST::Val.new( :value($name), :returns('String') ) );
    $target_ctr.push( PAST::Val.new( :value(1), :returns('Integer') ) );

    my $target_bind := PAST::Op.new( $target, $target_ctr,
                                     :pasttype('bind'),
                                     :name('create-makefile-target')
                                 );

    my $rule := PAST::Var.new( :lvalue(0), :viviself('Undef'),
      :scope('lexical'), :name($name)
    );
    my $rule_ctr := PAST::Op.new( :pasttype('call'),
      :name('!update-makefile-rule'), :returns('MakefileRule')
    );
    $rule_ctr.push( PAST::Val.new( :value($match), :returns('String') ) );
    $rule_ctr.push( $target_bind );
    $rule_ctr.push( $pack_deps );
    $rule_ctr.push( $pack_actions );

    make PAST::Op.new( $rule, $rule_ctr,
                       :pasttype('bind'),
                       :name('create-makefile-rule'),
                       :node( $/ ) );
}

method makefile_target($/) {
    my $name := ~$/;
    chop_spaces( $name );
    make PAST::Var.new( :name($name),
      :lvalue(1),
      :viviself('Undef'),
      :scope('lexical'),
      :node( $/ )
    );
}

method makefile_target_dep($/) {
    make PAST::Var.new( :name(~$/),
      :lvalue(0),
      :viviself('Undef'),
      :scope('lexical'),
      :node($/)
    );
}

method makefile_rule_action($/) {
    my $past := PAST::Op.new( :pasttype('call'), :returns('MakefileAction'),
      :name('!create-makefile-action'), :node($/) );
    $past.push( PAST::Val.new( :value(~$/), :returns('String') ) );
    make $past;
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

method makefile_variable_ref($/, $key) { make $( $/{$key} ); }
method makefile_variable_ref1($/) {
    make ref_makefile_variable( $/, ~$<makefile_variable_name1> );
}
method makefile_variable_ref2($/) {
    make ref_makefile_variable( $/, ~$<makefile_variable_name2> );
}



# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

