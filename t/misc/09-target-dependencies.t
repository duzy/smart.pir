# -*- mode: Makefile -*-
#
# checker: 09-target-dependencies
# 

all: pre-clean foobar.txt check clean
	echo $@ done

pre-clean:
	rm -f {foo,bar,foobar}.txt

check:
	@ls foo.txt bar.txt foobar.txt
	@cat foobar.txt
	@wc -l foobar.txt
foobar.txt: foo.txt bar.txt
	@echo update foobar.txt
	@cat "foo.txt" >> foobar.txt
	@cat "bar.txt" >> foobar.txt
foo.txt:
	@echo update foo.txt
	@echo "foo" > foo.txt
bar.txt:
	@echo update bar.txt
	@echo "bar" > bar.txt

clean:
	rm -f {foo,bar,foobar}.txt
