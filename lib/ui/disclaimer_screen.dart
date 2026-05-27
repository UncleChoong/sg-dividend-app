import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  static const _body = '''
This app is an educational tool. It does not provide financial advice and is not regulated by the Monetary Authority of Singapore (MAS) as a Financial Adviser.

The recommended allocations are illustrative outputs of a transparent rule-based optimizer that you parameterised yourself. They are not personal recommendations.

Past dividends do not guarantee future payments. Companies can and do cut their dividends. Stock prices fluctuate; you can lose money.

Data is scraped daily from public sources (Yahoo Finance, SGX, SGinvestors.io). It may be stale, incomplete, or wrong. Always verify against your broker before transacting.

You are responsible for your own investment decisions. If you need advice, speak to a MAS-licensed financial adviser.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disclaimer')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(_body, style: TextStyle(fontSize: 15, height: 1.5)),
      ),
    );
  }
}
