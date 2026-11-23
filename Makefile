# Resume build and release targets.
#
# Requirements: latexmk, pdflatex (TeX Live or MiKTeX), poppler-utils (pdfinfo), git.
# Releases: `make deploy VERSION=vYYYY.MM.PATCH` tags the current commit and pushes the tag;
# the GitHub Actions workflow in .github/workflows/render.yml then publishes the PDF.

TEX          := resume.tex
PDF          := build/resume.pdf
BUILD_DIR    := build
EXPECTED_PAGES := 2
VERSION      ?=
VERSION_PATTERN := ^v[0-9]{4}\.[0-9]{2}\.[0-9]+$$

.PHONY: pdf dev verify check-version check-clean deploy clean

pdf:
	latexmk -pdf -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD_DIR) $(TEX)

dev:
	latexmk -pdf -pvc -interaction=nonstopmode -output-directory=$(BUILD_DIR) $(TEX)

verify: pdf
	@pages=$$(pdfinfo $(PDF) | awk '/^Pages:/ {print $$2}'); \
	if [ "$$pages" != "$(EXPECTED_PAGES)" ]; then \
		echo "resume must be exactly $(EXPECTED_PAGES) pages, found $$pages" >&2; \
		exit 1; \
	fi
	@echo "OK: $(PDF) has $(EXPECTED_PAGES) pages"

check-version:
	@if [ -z "$(VERSION)" ]; then \
		echo "VERSION is required, e.g. make deploy VERSION=v2026.11.1" >&2; \
		exit 1; \
	fi
	@if ! echo "$(VERSION)" | grep -Eq '$(VERSION_PATTERN)'; then \
		echo "VERSION must look like vYYYY.MM.PATCH, got '$(VERSION)'" >&2; \
		exit 1; \
	fi
	@if git rev-parse -q --verify "refs/tags/$(VERSION)" >/dev/null; then \
		echo "tag $(VERSION) already exists" >&2; \
		exit 1; \
	fi

check-clean:
	@if ! git diff --quiet || ! git diff --cached --quiet; then \
		echo "uncommitted changes to tracked files; commit or stash before deploying" >&2; \
		exit 1; \
	fi

deploy: check-version check-clean verify
	git tag -a $(VERSION) -m "Resume $(VERSION)"
	git push origin $(VERSION)

clean:
	rm -rf $(BUILD_DIR)
