
#RUBY = ruby
BEXEC = bundle exec


serve:
	@echo "##"
	@echo "## head for http://localhost:7080/"
	@echo "##"
	$(BEXEC) rackup -p 7080 -o 0.0.0.0 -s puma test/config.ru
s: serve


.PHONY: serve

