# -*- mode: Makefile -*-
#
# checker: 10-multi-rule-one-target
#

#
# GNUMake compatibility: It looks like GNU make does no keep a strict order
# of the rules for single target, but smart-make does keep exactly the same
# order as they are appeared in the file.
#
# Take this file as an example, make will generate the following result:
# [start make output]
# ok, e, command 1
# ok, e, command 2
# ok, d <- e, command 1
# ok, d <- e, command 2
# foobar, invoked by foo
# ok, a
# ok, b
# ok, c
# foo <- d a b c | bar
# [end make output]
#
# But smart-make will make the following:
# [start smart output]
# ok, a
# ok, b
# ok, c
# ok, e, command 1
# ok, e, command 2
# ok, d <- e, command 1
# ok, d <- e, command 2
# foobar, invoked by foo
# foo <- a b c d | bar
# smart: Nothing to be done for 'foo'.
# [end smart output]
# 

foo: a
foo: b
foo: c
foo: d|bar
	@echo "$@ <- $^ | $|"

.PHONY: foo a b c d e bar

a:
	@echo "ok, $@"
b:
	@echo "ok, $@"
c:
	@echo "ok, $@"
d: e ;	@echo "ok, $@ <- $^, command 1"
	@echo "ok, $@ <- $^, command 2"
e:;	@echo "ok, $@, command 1"
	@echo "ok, $@, command 2"

bar:;   @echo "foobar, invoked by foo"
	@echo "todo: think about the the order of invocation of rules"