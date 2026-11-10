# Docs and releases

Prefix: DOC.

- **DOC1:** `docs/` is the user documentation and `README.md` is the front door. Reference material lives in `docs/`; the README keeps a summary and links to the site with full `https://psyb0t.github.io/safe-stremio/...` URLs, and to repository files with full `https://github.com/psyb0t/safe-stremio/blob/master/...` URLs, because the README is mirrored to Docker Hub.
- **DOC2:** The `title` in `docs/_config.yml`, the docs home H1 and the `docs/llms.txt` H1 equal the README H1 ("Safe-Stremio: Your Secure, Pirate-Friendly Streaming Solution"). Change them together.
- **DOC3:** Every page has front matter with a unique `title` and a `description` of 50 to 170 characters. Keep `docs/` flat. Link pages by relative `.md` path; link files outside `docs/` by full GitHub URL.
- **DOC4:** After a docs change, run `make docs` and the site link check, and fix what it reports.
- **DOC5:** Prose: no em or en dashes, "directory" never "folder", plain words instead of filler vocabulary, straight quotes. Match the existing voice of the README.
- **DOC6:** Public text never names local scratch directories, agent tooling or session details.
- **DOC7:** A release adds a `CHANGELOG.md` entry in the existing style and tags `vX.Y.Z` on the `master` commit. CI promotes the image built for that commit; it never rebuilds on a tag. Do not bump versions or write CHANGELOG entries unless asked.
- **DOC8:** Commits and tags never carry `Closes #N`, `Fixes #N` or `Resolves #N` unless the owner asked to close that issue.
