# -*- mode: Makefile -*-

# NOTE: all targets should always be updated

all: foobar
	@echo update all
	@ls -lh foo.txt bar.txt foobar.txt
	@cat foobar.txt
foobar: foobar.txt
	@echo update foobar
foobar.txt: foo bar
	@echo update foobar.txt
	@cat "foo.txt" >> foobar.txt
	@cat "bar.txt" >> foobar.txt
foo: bar foo.txt
	@echo update foo
foo.txt:
	@echo update foo.txt
	@echo "foo" > foo.txt

bar: bar.txt
	@echo update bar
bar.txt:
	@echo update bar.txt
	@echo "bar" > bar.txt

