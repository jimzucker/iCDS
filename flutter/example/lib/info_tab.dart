import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

/// Port of `iCDS/icds/InfoView.swift`.
class InfoTab extends StatelessWidget {
  const InfoTab({super.key, this.version = '3.0.1'});
  final String version;

  static final _apacheURL  = Uri.parse('https://www.apache.org/licenses/LICENSE-2.0');
  static final _isdaURL    = Uri.parse('https://www.cdsmodel.com');
  static final _docsURL    = Uri.parse('https://jimzucker.github.io/iCDS/');
  static final _privacyURL = Uri.parse('https://jimzucker.github.io/iCDS/PRIVACY');

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _aboutSection(),
              const _DividerLine(),
              _dataSourcesSection(),
              const _DividerLine(),
              _disclaimersSection(),
              const _DividerLine(),
              _legalSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutSection() {
    return Column(
      children: [
        const Text(
          'iCDS',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: AppTheme.orange,
          ),
        ),
        const Text(
          'Credit Default Swap Calculator',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          'Version $version',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.menu_book, color: AppTheme.orange),
          label: const Text(
            'Documentation & Source',
            style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.orange, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _open(_docsURL),
        ),
      ],
    );
  }

  Widget _dataSourcesSection() {
    return Column(
      children: [
        _SectionHeader('Data sources'),
        const SizedBox(height: 14),
        _AttributionBlock(
          title: 'Pricing engine',
          lines: const [
            'ISDA CDS Standard Model',
            '© 2009 JPMorgan Chase Bank, N.A.',
            'Licensed under the ISDA CDS Standard Model Public License',
          ],
          link: ('www.cdsmodel.com', _isdaURL),
        ),
        const SizedBox(height: 14),
        _AttributionBlock(
          title: 'Live reference rates',
          lines: const [
            'USD SOFR — Federal Reserve Bank of New York (newyorkfed.org)',
            'EUR €STR — European Central Bank (ecb.europa.eu)',
            'GBP SONIA — Bank of England (bankofengland.co.uk)',
            'JPY TONA (monthly proxy) — FRED, St. Louis Fed (fred.stlouisfed.org)',
            'AUD AONIA — Reserve Bank of Australia (rba.gov.au)',
          ],
          link: null,
        ),
      ],
    );
  }

  Widget _disclaimersSection() {
    return const Column(
      children: [
        _SectionHeader('Disclaimers'),
        SizedBox(height: 8),
        _DisclaimerLine('Indicative pricing only. Not financial, investment, or trading advice.'),
        _DisclaimerLine('Provided AS IS, without warranty of any kind. No liability is accepted for any loss arising from use of this app or its results.'),
        _DisclaimerLine('Rates may be delayed; calculations use a flat overnight-rate discount curve — a standard simplification. Not suitable for booking, settlement, or trading.'),
        _DisclaimerLine('Users are responsible for verifying all results against authoritative sources before acting on them.'),
        _DisclaimerLine('Not affiliated with, endorsed by, or sponsored by ISDA, Markit, JPMorgan Chase, or any rate provider listed above. All trademarks are property of their respective owners.'),
      ],
    );
  }

  Widget _legalSection() {
    return Column(
      children: [
        const Text(
          '© 2016-2026 James A. Zucker',
          style: TextStyle(fontSize: 12, color: AppTheme.captionText),
        ),
        const Text(
          'Licensed under the Apache License, Version 2.0',
          style: TextStyle(fontSize: 11, color: Color(0xFF737373)),
        ),
        InkWell(
          onTap: () => _open(_apacheURL),
          child: const Text(
            'apache.org/licenses/LICENSE-2.0',
            style: TextStyle(fontSize: 11, color: AppTheme.orange),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _open(_privacyURL),
          child: const Text(
            'Privacy Policy',
            style: TextStyle(fontSize: 12, color: AppTheme.orange, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _open(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.captionText,
        ),
      ),
    );
  }
}

class _AttributionBlock extends StatelessWidget {
  final String title;
  final List<String> lines;
  final (String, Uri)? link;

  const _AttributionBlock({
    required this.title,
    required this.lines,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.dimText,
          ),
        ),
        const SizedBox(height: 4),
        ...lines.map(
          (l) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              l,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFFBFBFBF)),
            ),
          ),
        ),
        if (link != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: () async {
                final uri = link!.$2;
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                link!.$1,
                style: const TextStyle(fontSize: 11, color: AppTheme.orange),
              ),
            ),
          ),
      ],
    );
  }
}

class _DisclaimerLine extends StatelessWidget {
  final String text;
  const _DisclaimerLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: Color(0xFFB8B8B8)),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Divider(color: Color(0xFF333333), height: 1),
      );
}
