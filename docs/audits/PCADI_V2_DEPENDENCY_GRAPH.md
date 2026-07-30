# PCADI v2 correction dependency graph

The annual booking-band interface affects more than one CSV. This graph records
the reviewed dependency path.

```text
official GPAD booking categories
    |
    v
prepared GPAD practice-month counts
    |
    v
annual GPAD component totals
    |
    +--> gpad_1_day_share
    +--> gpad_2_to_7_days_share
    |
    v
14-feature national matrix
    |
    +--> 17-feature CBT inbound matrix
    |        |
    |        v
    |    exact 14-field inheritance gate
    |
    +--> 21-feature CBT outcome matrix
             |
             v
         exact 17-field inheritance gate
```

## Affected repository surfaces

| Surface | Dependency | Required control |
|---|---|---|
| Fixed SQL stages 09 to 12 | annual shares, matrix schema, validation and fingerprint | exact fields and order |
| Portable SQL stages 03 to 05 | configurable annual and CBT outputs | 14, 17 and 21-feature contracts |
| Reference CSVs | public modelling interface | locked dimensions and hashes |
| Export automation | filenames and column order | deterministic output |
| Synthetic tests | future regression protection | deliberately unequal booking bands |
| Feature and table dictionaries | public meaning | exact numerator and denominator |
| Audience and design guides | analytical use | correct population and limitation |
| Release manifests | file identity | replacement and superseded registers |
| Downstream outcome sensitivity | inherited core fields | raw 21 documented separately from 20-feature ILR |

## Unaffected analytical structures

The source-specific practice-month aggregation, union coverage spine, retained
practice populations, OCS and GPAD totals, temporal output and observation
period do not depend on combining the two booking bands.
