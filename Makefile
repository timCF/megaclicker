clean:
	rm -rf /Users/tim/MYprojects/megaclicker/_build/dev/lib/silverb/priv/silverb
	mix clean
	mix deps.clean --all
	rm -rf ./_build
release:
	mix clean
	mix deps.get
	mix compile.protocols
	mix silverb.on
	mix silverb.check
	mix silverb.off
	mix release.clean --implode
	mix release
