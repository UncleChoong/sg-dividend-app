import 'package:flutter/material.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';

class ExplainScreen extends StatelessWidget {
  final Allocation alloc;
  final RiskLevel risk;
  const ExplainScreen({super.key, required this.alloc, required this.risk});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Why these stocks?')),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Risk level: ${risk.label} (max score ${risk.maxScore})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'The optimizer filters the SGX dividend universe down to tickers whose risk score '
            'is at or below your chosen level, then greedily picks the highest-yielding ones '
            'subject to: max 25% in any single ticker, max 40% in any single sector, minimum 5 '
            'holdings (3 if capital below S\$2,000).',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 24),
          const Text('Per-ticker score breakdown',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final l in alloc.lines) Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${l.ticker.ticker}  ·  ${l.ticker.name}  ·  ${l.ticker.sector}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Total score: ${l.ticker.score}/100  '
                   '(sector ${l.ticker.scoreBreakdown.sector}, '
                   'mcap ${l.ticker.scoreBreakdown.mcap}, '
                   'div-vol ${l.ticker.scoreBreakdown.divVol}, '
                   'payout ${l.ticker.scoreBreakdown.payout}, '
                   'price-vol ${l.ticker.scoreBreakdown.priceVol})',
                   style: const TextStyle(fontSize: 12)),
            ]),
          )),
        ],
      ),
    );
  }
}
