# Privacy Policy

**Effective date:** April 25, 2026

## TL;DR

iCDS does not collect, store, transmit, or share any personal information. It has no accounts, no analytics, no advertising, no tracking, and no third-party SDKs.

## What iCDS does

iCDS is an offline calculator for SNAC (Standard North American CDS) upfront fees, implementing the ISDA CDS Standard Model. All pricing math runs locally on your device.

## Information we collect

**None.** We do not collect, log, transmit, or store any personal information from you, your device, or your usage of the app.

The app does not contain:
- User accounts or sign-in
- Analytics or telemetry
- Advertising or advertising identifiers
- Crash reporters that send data off-device
- Third-party SDKs

The bundled [Privacy Manifest](https://github.com/jimzucker/iCDS/blob/master/icds/PrivacyInfo.xcprivacy) declares `NSPrivacyTracking = false` and an empty `NSPrivacyCollectedDataTypes` array, consistent with the above.

## Network activity

iCDS makes **anonymous, read-only HTTPS requests** to publicly available market-data endpoints to display current overnight reference rates and swap curves on the Curves tab:

| Currency | Source                                  | Operator                  |
|----------|-----------------------------------------|---------------------------|
| USD      | `markets.newyorkfed.org`                | Federal Reserve Bank of New York |
| EUR      | `data-api.ecb.europa.eu`                | European Central Bank     |
| GBP      | `www.bankofengland.co.uk`               | Bank of England           |
| JPY      | `fred.stlouisfed.org`                   | Federal Reserve Bank of St. Louis |
| AUD      | `www.rba.gov.au`                        | Reserve Bank of Australia |

These are public, unauthenticated APIs. iCDS sends only the standard HTTP request needed to retrieve the public data; no user identifier or personal information is included. The operators of these endpoints may log standard request metadata (such as IP address and User-Agent) under their own privacy policies, which apply to those interactions and which we do not control.

If a request fails or times out, iCDS silently falls back to a hardcoded reference rate; nothing is reported anywhere.

## Data sharing

We do not share, sell, rent, or disclose any information, because we do not collect any.

## Children's privacy

iCDS does not knowingly collect data from anyone, including children under 13.

## Open source

iCDS is open source. You can audit the full source — including every network call — at:

<https://github.com/jimzucker/iCDS>

## Changes to this policy

If this policy changes, the updated text will be published at the same URL with a new effective date.

## Contact

Questions about this policy: **jamesazucker@gmail.com**
