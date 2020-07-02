clean:
	go clean
	rm -rf dvbtci.tgz

test: clean
	go test

pkg: clean
	$(eval TMPDIR := $(shell mktemp -d))
	$(shell mkdir -p $(TMPDIR)/dvbtci)
	$(shell cp -r *.go testdata go.* metadata.json $(TMPDIR)/dvbtci)
	$(shell (cd $(TMPDIR)/ ; tar -zcvf dvbtci.tgz dvbtci))
	$(shell mv $(TMPDIR)/dvbtci.tgz .)
	rm -rf $(TMPDIR)