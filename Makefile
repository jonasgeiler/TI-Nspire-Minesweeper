
build:
	nspire-merge --out out.lua
	luna out.lua minesweeper.tns

clean:
	$(RM) out.lua
	$(RM) minesweeper.tns

.PHONY: clean build

