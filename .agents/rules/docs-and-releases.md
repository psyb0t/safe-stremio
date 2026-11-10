# Docs and releases

Prefix: DOC.

- **DOC1:** The README links to the site with full `https://psyb0t.github.io/safe-stremio/...` URLs, and to repository files with full `https://github.com/psyb0t/safe-stremio/blob/master/...` URLs, because the README is mirrored to Docker Hub.
- **DOC2:** The `title` in `docs/_config.yml`, the docs home H1 and the `docs/llms.txt` H1 equal the README H1 ("Safe-Stremio: Your Secure, Pirate-Friendly Streaming Solution"). Change them together.
- **DOC3:** Keep `docs/` flat.
- **DOC4:** After a docs change, run `make docs` and the site link check.
- **DOC7:** A release tag `vX.Y.Z` goes on a `master` commit. CI promotes the image built for that commit; it never rebuilds on a tag.
