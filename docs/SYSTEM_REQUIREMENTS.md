# System requirements

The portable demonstration requires Python 3.11 or newer with its standard
library SQLite module. It has no third-party Python dependency.

The first clean-checkout reference validation also requires internet access to
download the pinned 36.2 MB release asset. The runner verifies the asset and
each restored CSV against the published SHA-256 manifest before use. Later
validations reuse the verified local copy under `work/reference_assets/`.

The frozen full reference build used large official CSVs and working SQLite
databases. Users should allow substantial temporary disk space, particularly
for raw GPAD imports and indexes. Runtime depends on storage speed, available
memory and SQLite temporary-file settings. The documented clean reference build
took 1,166.312 seconds on one machine; that timing is a benchmark, not a
guarantee.

All local databases and generated work products belong under `work/`, which is
excluded from Git. Use a separate work location if the system drive has limited
space. Do not delete source downloads until their checksums and provenance have
been secured.
