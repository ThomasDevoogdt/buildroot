# Buildroot package maintenance guide

This repository is Buildroot. Keep package changes small, reviewable, and
compatible with the package infrastructure. Do not rewrite unrelated files or
normalize formatting outside the package being changed.

## Discover package ownership and scope

Before editing a package:

1. Read every file in `package/<name>/`, including patches and the package
   `Config.in`.
2. Find the package's entry in `DEVELOPERS`.
3. Inspect the package's recent history:

   ```sh
   git log --follow -- package/<name>/<name>.mk
   ```

4. Inspect at least one recent successful bump for the same package. If the
   package has never been bumped, inspect a package from the same upstream and
   build-system family.
5. Treat all existing uncommitted work as user-owned. Never revert or overwrite
   unrelated changes.

Nested packages still have one package directory, for example
`package/x11r7/xlib_libxshmfence/`. `package/openjdk/` also owns the
`host-openjdk-bin` package.

## Identify the real package version

The authoritative version is normally `<UPPERCASE_PACKAGE_NAME>_VERSION` in
the package `.mk` file. Less common layouts use:

- several independently selectable version variables;
- a source revision or Git commit instead of a release number;
- an upstream version normalized for Buildroot;
- a generated source archive whose filename includes the fetched revision;
- package versions selected through `Config.in` choices.

Read the source variables before assuming an archive name:

- `_SITE`
- `_SOURCE`
- `_SITE_METHOD`
- `_EXCLUDES`
- `_STRIP_COMPONENTS`
- `_LICENSE` and `_LICENSE_FILES`
- `_DEPENDENCIES`
- `_CONF_OPTS`, `_INSTALL_STAGING`, `_INSTALL_TARGET`
- `_AUTORECONF`, `_SUBDIR`, `_CPE_ID_*`

For Git sources, the hash is for Buildroot's generated archive, not for a
particular Git object stored elsewhere. Recalculate it by using Buildroot's
download/check machinery when the version or fetch method changes.

For Go or Cargo packages that Buildroot post-processes, the hash is for the
generated `-go2` or `-cargoN` archive, not the upstream tag archive. Generate
it with Buildroot's exact `support/download/go-post-process` or
`support/download/cargo-post-process` helper, host tool version, environment,
lockfile, and options. Do not trust a hand-built vendor directory or a
differently generated archive. Keep the package source declaration aligned
with the generated format suffix.

## Check whether a bump exists

Use the package's official upstream release channel. Prefer, in order:

1. the upstream release/download site already referenced by the package;
2. official project tags or releases in its repository;
3. the distribution metadata maintained by the upstream project.

Do not use an unrelated distribution's patch, downstream fork, or search result
as the source of truth.

Check:

- the newest stable, non-release-candidate version;
- whether the package intentionally tracks an upstream stable series;
- whether a major-version change is compatible with the current Buildroot
  package API and package dependencies;
- whether all required binary/source variants exist, especially host variants
  for packages with architecture-specific archives;
- the exact archive filename and checksum published by upstream.

If the package tracks a moving commit rather than a release, move the pin only
for a justified upstream state. Do not silently substitute a branch head.

## Routine bump footprint

A normal release bump usually changes:

```text
package/<name>/<name>.mk
package/<name>/<name>.hash
```

In the `.mk` file, update the version and any source filename/site component
derived from it.

In the `.hash` file:

- remove the old source archive hash;
- add the exact new archive hash;
- use an upstream-published checksum whenever one exists in a release
  announcement, release asset, or checksum sidecar, and cite that exact URL;
  use `Locally calculated` only after confirming that no trustworthy upstream
  checksum is available;
- re-extract every file named by the package `_LICENSE_FILES`;
- inspect the complete upstream license file set, not just files currently
  listed, and detect new, removed, renamed, split, or partially changed
  licenses;
- remove hash entries for license files no longer shipped and add entries for
  newly relevant license files;
- recompute every retained license hash; do not assume an unchanged filename
  means unchanged content;
- preserve a useful `# From <official checksum or release URL>` comment for
  published checksums rather than relabeling them as locally calculated;
- mark checksums as locally computed when no upstream checksum exists;
- never copy a checksum merely because the filename looks similar.

`Config.in`, `DEVELOPERS`, patches, and documentation are not part of an
ordinary bump unless the release semantics require them.

## Review patches on every bump

For every patch in the version-specific package directory:

1. Apply or refresh it against the new upstream version.
2. Determine whether it is already upstream.
3. Remove obsolete patches when their fix is present upstream.
4. Renumber remaining patches consecutively.
5. Keep `Upstream:` and `Signed-off-by:` metadata in patches unless their
   upstream lineage changes.
6. Update `.checkpackageignore` when a version-specific patch path is renamed
   and an existing exception must follow it.

A clean package bump should not keep a patch that is already included upstream.
Before keeping a patch, confirm it with a real application check against the
new extracted release, for example `git apply --check`. An upstreamed patch
commonly reports reversed/already-applied hunks. Recheck after choosing the
final source type and generated archive, since the archive root can differ.

## Build-system-specific checks

The build-system macro does not by itself define which files a bump changes,
but it identifies the likely compatibility risks.

### Autotools

Look for:

- removal or addition of `_AUTORECONF = YES`;
- changed configure option names;
- newly required pkg-config dependencies;
- generated `configure` scripts disappearing or appearing;
- new host tools, language requirements, or minimum versions.

Compare old and new `configure --help` output when practical. Do not add
autoreconf just because it fails without first understanding the upstream
tarball.

### CMake

Look for:

- renamed CMake options;
- changed minimum CMake version;
- static/shared library selection changes;
- toolchain behavior moved from configure options to dependencies;
- newly required host CMake/Perl/Python tools.

Map obsolete `*_CONF_OPTS` to the new option names rather than leaving silently
ignored options.

### Meson

Look for:

- renamed Meson options, especially options with `auto` values;
- changed Meson minimum version;
- `dependency()` moves and newly required features;
- upstream Meson wrap fallbacks that must be disabled in a Buildroot build;
- newly required host Python or Ninja features.

Never enable an upstream bundled fallback that bypasses Buildroot's own
dependency graph.

Meson packages run through Ninja after configuration. Use `_NINJA_ENV` for
variables required during build/install; `_BUILD_ENV` is not consumed by the
Meson infrastructure's default Ninja commands.

Rust/Cargo code invoked from Ninja needs `PKG_CARGO_ENV` plus target
`PKG_CONFIG` search paths and `PKG_CONFIG_SYSROOT_DIR` when build scripts
discover system libraries. Use `HOST_PKG_CARGO_ENV` for host builds. A
configured target triplet alone does not make pkg-config target-aware.

### Other systems

For generic, custom, or language-specific packages, compare the upstream build
and install commands. Preserve Buildroot staging/target behavior, host-package
variants, and cross-compilation environment handling.

## Config and dependency changes

Change `Config.in` only when the new release changes:

- a package dependency;
- a minimum toolchain/compiler/C library/kernel capability;
- available user-selectable options;
- package type or visibility;
- a mutually exclusive choice.

When the build system changes as part of the bump, verify the package's macro
and all custom configure/build/install commands. A build-system conversion is a
separate compatibility change and needs explicit rationale in the commit
message; it is not an ordinary side effect of updating a version.

Raise a package's Kconfig floor only after confirming the exact new facility
introduced upstream. Examples include:

- target-library `fork()` use requiring `BR2_USE_MMU`;
- Linux `dma-buf`/`udmabuf` UAPI headers requiring a higher kernel-header floor;
- unsupported Rust target triples making a package unavailable despite host
  Rust/Cargo being available.

Put a constraint on the top-level package symbol when the whole package is
unusable, and on a sub-option only when that feature alone is affected. Add a
matching `comment` so the reason is visible in menuconfig.

After changing a package dependency or constraint, search all reverse
dependencies:

```sh
git grep -n 'select BR2_PACKAGE_<UPPERCASE_NAME>' package
git grep -n 'depends on BR2_PACKAGE_<UPPERCASE_NAME>' package
```

For every result, determine whether the reverse dependency can configure the
newly constrained package. If so, repeat the required Kconfig constraint on the
consumer, or select a provider/alternative only when it genuinely satisfies
the same dependency. Do not rely on a mandatory `select` to make an invisible
constraint satisfiable: Kconfig can simply leave the selected symbol disabled.

This applies even to transitively mandatory dependencies. For example, a
new MMU requirement on `seatd` must be added to every consumer that selects
`seatd` and therefore cannot itself build without MMU, including consumers
with an otherwise unrelated existing MMU reason.

Update CPE metadata when a normalized source version no longer maps correctly
to the upstream/NVD version.

## Validate source metadata

Run package checks:

```sh
utils/check-package \
  package/<name>/Config.in \
  package/<name>/<name>.mk \
  package/<name>/<name>.hash \
  package/<name>/<patch>.patch
```

Prefer explicit changed and newly added files. Passing only a package directory
is not reliable across all `check-package` versions and can report
`0 lines processed`, which is not validation. Check renamed version-specific
patch paths too. Deleted patches need not be passed; verify the remaining patch
set and deletion separately.

Run `check-package` after patch generation/refresher work and again after the
final metadata edits. A valid run reports the expected processed-line count and
`0 warnings generated`. A zero-line result is meaningful only when an
intentionally empty set was requested.

Always combine it with `git diff --check`: `check-package` validates Buildroot
conventions and `diff --check` catches whitespace and patch-formatting errors.

Force a clean source check where appropriate:

```sh
make <package>-source
make <package>-dirclean
make <package>
```

If a download remains in Buildroot's download cache, move the package directory
or invoke the standard source/check target as needed to ensure the source is
actually fetched with the new hash.

Inspect the extracted source and its top-level license/COPYING/NOTICE files.
Also search subdirectories for licenses when the new release vendors code or
adds a separately licensed component. Confirm the package `_LICENSE` expression
still matches all installed artifacts and that `_LICENSE_FILES` names every
required file with the correct path.

Review `make <package>-legal-info` output and verify:

- no configured license file disappeared;
- no new license is left undeclared;
- source, target, and host variants install the same declared content;
- changed license notices are represented in the hash file;
- vendored dependency licenses are covered when package infrastructure
  requires them.

## Use `utils/test-pkg`

`utils/test-pkg` validates a package against Buildroot's external toolchain
matrix. Its important controls are:

- `-p PKG`: targeted package build, legal-info, and `show-info` JSON check;
- `-c FILE`: merge a configuration snippet into each selected toolchain;
- `-a`: test all eligible external toolchains from the selected CSV;
- `-n N`: test the first N toolchains;
- `-r N`: test N random toolchains;
- `-T NAME`: select one named toolchain;
- `-t CSV`: use a different toolchain list;
- `-d DIR`: choose the build root;
- `-k`: retain successful build artifacts;
- `--prepare-only`: prepare and inspect configurations without building.

`-a` selects toolchains. It does not enable every package option.

`-c` controls package configuration. The snippet is merged after the
toolchain fragment and `minimal.config`; `test-pkg` verifies every requested
setting remains in `.config`. Incompatible toolchains are marked `SKIPPED`.
`-c` neither selects toolchains nor enables `-a`.

Without `-c`, `test-pkg` derives a temporary snippet from `-p` and enables
`BR2_PACKAGE_<PACKAGE>=y`. If a bump needs optional features or dependencies
to be exercised, provide a complete snippet that enables the relevant choices.

Recommended progression:

```sh
utils/test-pkg -p <package>             # default six challenging toolchains
utils/test-pkg -p <package> -c /path/to/<package>.config
utils/test-pkg -a -p <package> -c /path/to/<package>.config
```

Always start with the default six-toolchain matrix rather than one convenient
x86_64 glibc toolchain. The CSV deliberately covers useful challenging
configurations such as an old GCC/toolchain, musl, uClibc, noMMU, and
full-static builds; an absent-C++ toolchain may also legitimately skip a C++
package. Inspect every `SKIPPED` result and verify that the Kconfig dependency
which caused it is intended.

Do not combine unrelated packages in one configuration and treat that as their
validation. Package selection and global dependencies can change what is
compiled or cause a package to disappear from the final `.config`. Run each
package target independently so its own feature and dependency closure is
tested.

Use a named toolchain while debugging one failure, then expand to `-a` when the
package is architecture-sensitive or changes cross/build-system behavior.
Remember that `-a`, `-n`, and `-r` are mutually exclusive.

For a successful test, `test-pkg` runs:

```text
make <package>-dirclean
make <package>
make legal-info
make show-info
```

It sets dependency checking, records per-toolchain status, and validates
`show-info` output with `jq`. Use `-k` only when retained logs/artifacts are
needed for debugging.

## Commit structure

Use a focused subject such as:

```text
package/<name>: bump version to <version>
```

Use `security bump` only when the update is explicitly addressing security
issues:

```text
package/<name>: security bump to version <version>
```

For related package instances, preserve established grouping notation rather
than creating an ambiguous subject:

```text
package/{openjdk, openjdk-bin}: bump <series> to <version>
```

The body should include:

- relevant upstream release/changelog URL;
- notable dependency, API, ABI, patch, or build-system changes;
- why removed patches are no longer necessary;
- important security/CVE context for a security bump;
- exact validation commands and meaningful results when they are not obvious;
- `Signed-off-by:` trailer.

The package maintainer taking responsibility is the sole commit co-author.
Do not add a `Co-authored-by: Copilot` trailer to Buildroot commits.

Fix issues in the commit that introduced them. Before finalizing a series,
fold typo, patch-formatting, dependency, and direct validation fixes back into
the responsible bump commit instead of leaving a separate follow-up commit.
Use fixup commits only temporarily during development, and autosquash them
before presenting or sending the series.

Do not copy CVE descriptions or release notes as if their presence alone
explains package changes. Describe the Buildroot impact.

Keep unrelated packages in separate commits. A package bump that performs a
build-system migration should explain and group only the directly coupled
changes.

## Version bump checklist

- [ ] Official stable candidate identified.
- [ ] Series/major-version compatibility confirmed.
- [ ] `.mk` version and derived source naming updated.
- [ ] Official announcement/release-side checksum checked and preferred.
- [ ] Exact source archive hash verified.
- [ ] All current and new license/COPYING/NOTICE files inspected.
- [ ] Removed/renamed license files deleted from hashes and `_LICENSE_FILES`.
- [ ] `_LICENSE` updated for newly added, split, or changed component licenses.
- [ ] Every `_LICENSE_FILES` hash independently recomputed.
- [ ] Patches reviewed, applied, refreshed, or removed.
- [ ] `.checkpackageignore` paths updated if necessary.
- [ ] Dependencies and `Config.in` constraints reviewed.
- [ ] Every new or tightened Kconfig constraint propagated to every package
      that selects or otherwise requires the constrained package.
- [ ] CMake/Meson/Autotools options reviewed for renames/removals.
- [ ] `utils/check-package` run on explicit changed/new package files and
      reports processed lines plus `0 warnings generated`.
- [ ] `git diff --check` passes.
- [ ] Each package tested independently with the default six challenging
      `test-pkg` toolchains; all skips explained.
- [ ] `-a` matrix run when the change is architecture-sensitive or changes
      build-system/cross-compilation behavior.
- [ ] Legal-info and show-info pass through `test-pkg`.
- [ ] Diff is limited to the bump and its direct consequences.
- [ ] Commit subject/body describe the Buildroot change.
- [ ] No Copilot co-author trailer; the responsible maintainer owns the
      authorship/trailer.
- [ ] All fixups folded into the commit that introduced the issue.

## Thomas Devoogdt bump inventory

When auditing packages previously bumped by `Thomas Devoogdt
<thomas@devoogdt.com>`, use git author email matching and search subjects
containing `bump`; currently relevant package families include:

- at-spi2-core
- busybox
- cairo
- fluent-bit
- fontconfig
- libglib2
- libgtk4
- libinput
- librdkafka
- librsvg
- libsoup3
- libsrtp
- lighttpd
- msgpack-c
- openjdk and host-openjdk-bin
- pango
- seatd
- syslog-ng
- wayland
- wayland-protocols
- webkitgtk
- weston
- x11r7/xlib_libxshmfence
- yq

Rediscover this inventory before a new audit rather than treating the list as
permanent:

```sh
git log HEAD --author='<thomas@devoogdt.com>' \
  --format='%H%x09%s' --grep='bump' -i
```

Historical or private packages that are absent from the current public
Buildroot tree are outside the inventory and must not be recreated solely for
a version audit.
