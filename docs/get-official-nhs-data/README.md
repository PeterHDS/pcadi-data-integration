# Get official NHS England data

Use only official NHS England publication pages and downloadable resources.
Start by generating a checklist for the configured observation period. The
checklist is a collection plan, not proof that a local file is correct.

## Official NHS England release pages

Begin from the official monthly release index for each source. Open the release
covering the required observation period, read its notices, then download the
named resource from the **Resources** section of that NHS England page.

| Data needed | Official NHS England release index | Resource to select on the release page |
|---|---|---|
| Online Consultation Systems (OCS) | [Submissions via Online Consultation Systems in General Practice](https://digital.nhs.uk/data-and-information/publications/statistical/submissions-via-online-consultation-systems-in-general-practice) | **CSV zip** and metadata; add **Day and Time CSV zip** only for temporal analysis |
| General Practice Appointment Data (GPAD) | [Appointments in General Practice](https://digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice) | **Annex 1: Practice Level CSV zip** and its metadata or mapping evidence |
| Cloud Based Telephony (CBT) | [Cloud Based Telephony Data in General Practice](https://digital.nhs.uk/data-and-information/publications/statistical/cloud-based-telephony-data-in-general-practice) | **By Day and Time**, participation and submission evidence, and metadata; add **By Durations** only when required |
| Registered-patient denominator | [Patients Registered at a GP Practice](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice) | **Totals (GP practice-all persons)** for the matching month |

These links lead to the NHS England release indexes, not to a copied file or a
third-party mirror. A release page contains the official download links,
publication date, reporting range, notices, metadata and previous-version
navigation needed for provenance.

Before downloading, use the [source catalogue](../SOURCE_CATALOGUE.md) to
confirm which source can support the intended question and which grain and
limitations must be preserved.

For each resource retain:

- publication title and page URL;
- direct resource URL;
- access and publication dates;
- publication release month;
- observation months represented;
- exact filename and archive member;
- file size and SHA-256 checksum;
- metadata and supporting information;
- selection decision and supersession reason.

Never equate publication month with observation month. OCS publications can
contain retrospectively revised historical data. GPAD releases can include
practice-level files for earlier appointment months. CBT coverage changes with
supplier participation and practice-account mapping.

The runner requires one selected source owner per dataset-component-month. If a
later release supersedes a historical month, retain the earlier candidate in
the audit but mark only the chosen vintage as selected.

After completing the download manifest, validate file size, SHA-256, official
domains, ZIP integrity, required archive members and CSV headers:

```powershell
python automation/pipeline_cli.py validate-downloads `
  --config configs/my_period.json `
  --manifest data/downloads/download_manifest.csv `
  --download-dir data/downloads `
  --output work/download_validation.csv
```

The command does not download or replace files. It confirms the identity and
integrity of the local evidence selected by the user.

See the dataset-specific guides in this directory and the machine-readable
registry in `pipeline/source_registry/official_sources.csv`.

For a concrete worked example, inspect the exact filenames, checksums, schemas,
row counts and month-ownership decisions in `reference-release/manifests/`.
