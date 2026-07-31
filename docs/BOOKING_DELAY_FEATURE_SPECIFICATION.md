# GPAD booking-delay feature specification

The primary annual matrix preserves the separately published GPAD booking bands `1 Day` and `2 to 7 Days` as:

- `gpad_1_day_share`
- `gpad_2_to_7_days_share`

Both use annual total recorded GPAD appointments as the denominator. Same-day, 8-to-14-day and over-14-day fields remain separate. Unknown/data-issue values remain outside the selected components, so the selected shares are not forced to sum to one.

The detailed annual audit table may report `gpad_days_1_to_7_audit_share` as the transparent sum of the two fields. This diagnostic sits outside the authoritative modelling matrices.

Booking interval describes the elapsed time between the recorded booking date and appointment date. Initial contact timing, demand and service quality require additional evidence.

Official interpretation:

- https://digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice/appointments-in-general-practice-supporting-information
- https://digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice/improving-data-quality
