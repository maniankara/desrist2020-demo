clean:
	go clean
	rm -rf dti.tgz

test: clean
	go test

pkg: clean
	$(eval TMPDIR := $(shell mktemp -d))
	$(shell mkdir -p $(TMPDIR)/dti)
	$(shell cp *.go $(TMPDIR)/dti)
	$(shell (cd $(TMPDIR)/ ; tar -zcvf dti.tgz dti))
	$(shell mv $(TMPDIR)/dti.tgz .)
	rm -rf $(TMPDIR)