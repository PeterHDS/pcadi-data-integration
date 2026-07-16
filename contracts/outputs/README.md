# Output contracts

## Practice-month outputs

Key: `practice_code_standardised + reporting_month`.

The coverage-preserving output contains source-presence flags and separate OCS,
GPAD and CBT measures. Matched outputs are filtered views of that table; they do
not recalculate activity. These outputs accept any configured positive number
of consecutive observation months.

## Annual core matrix

Key: `practice_code_standardised`.

The first column is traceability metadata. The remaining thirteen fields are
numerical modelling features. A matrix is created only from a validated
twelve-month configuration that explicitly enables annual features and has
complete source and denominator evidence.

## Telephony sensitivity matrices

The inbound variant contains the thirteen core features plus three CBT inbound
features. The outcome variant additionally contains four CBT outcome shares.
They are sensitivity populations, not replacements for the core annual matrix.

## Temporal output

OCS and CBT temporal measures remain separate. The April 2025 Y60 integrity
flag identifies practices affected by missing official CBT day/time evidence;
missing activity is not filled or inferred.
