fennel:
	wget "https://fennel-lang.org/downloads/fennel-1.3.0" -O fennel
	chmod +x fennel

lib/shim: lib/shim.fnl
	./fennel --compile --require-as-include $< > $@.lua

funcho: funcho.fnl fennel lib/shim
	sed -e '\#^$$#q' $< | sed -e 's#;;#--#' > $@.lua
	./fennel --compile --require-as-include $< >> $@.lua

clean:
	rm funcho.lua

.PHONY: clean
