import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';

// IDEM algae page
final advisoriesUrl = Uri.parse('https://www.in.gov/idem/algae/');

Future<void> openAdvisories() => launchUrl(advisoriesUrl, mode: LaunchMode.externalApplication);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GG.ground,
        appBar: AppBar(
          backgroundColor: GG.ground,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          foregroundColor: GG.text,
          title: Text('About & credits', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: GG.text)),
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Row(children: [
                Image.asset(GG.logo, width: 56, height: 56),
                SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('GeistGuard', style: T.title),
                    SizedBox(height: 2),
                    Text('Spot blooms. Protect the lake.', style: T.small),
                  ]),
                ),
              ]),
              _section('What GeistGuard does', [
                'Take a photo of the water and an AI on your phone estimates whether it shows a possible algal bloom. Photos from your library are checked too, but never added to the map.',
                'Reports appear on a shared map of Geist Reservoir for 7 days, and a hotspot view shows where blooms were reported over the last 6 months.',
                'Save a spot to see when a possible bloom is reported within 1 mile of it in the last 48 hours.',
                'Upstream mode checks whether your location or any address is in the Geist watershed and gives runoff tips based on the forecast.',
              ]),
              SectionTitle('How the AI works'),
              Panel(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: _figure('83%', 'right on 81 test photos')),
                    VerticalDivider(width: 1, color: GG.rule),
                    Expanded(child: _figure('81%', 'of blooms caught')),
                    VerticalDivider(width: 1, color: GG.rule),
                    Expanded(child: _figure('87%', 'right when it answers')),
                  ]),
                ),
              ),
              SizedBox(height: 16),
              ..._lines([
                'A MobileNetV3 neural network, retrained on about 540 labeled photos, sorts each photo into: possible bloom, look-alike (duckweed, pollen, weeds), clear water, or not water.',
                'On 81 test photos it never saw during training, it was right about 83% of the time. It caught 81% of the blooms.',
                'If it is less than 60% sure, it says "Not sure" instead of guessing. On the photos it does answer, it was right about 87% of the time.',
                'Its mistakes lean cautious: it more often calls clear water a bloom than misses a real one.',
                'The AI runs on the phone. Only a small, low-resolution preview of each water report is shared on the map, never the full photo.',
              ]),
              _section('Limits', [
                'This is a visual estimate only. A photo can\'t measure toxins, and some harmful blooms are hard to see.',
                'GeistGuard never tells you water is safe. Always check official advisories before contact with the water.',
              ]),
              SizedBox(height: 4),
              SecondaryButton(onPressed: openAdvisories, label: 'Indiana algae advisories (IDEM) ↗'),
              _section('Credits', [
                'Training photos: iNaturalist contributors and Wikimedia Commons contributors, used under their Creative Commons licenses. The full list of photographers is in the project\'s credits files.',
                'Watershed boundary: USGS Watershed Boundary Dataset (public domain).',
                'Weather: National Weather Service API. Address suggestions: Photon by Komoot (OpenStreetMap data). Address lookup: US Census Bureau Geocoder.',
                'Map: © OpenStreetMap contributors.',
                'Advice: Purdue Turfgrass Science, Iowa State University Extension, Town of Fortville Stormwater, Hamilton County Health Department, and WFYI.',
                'Safety tips: CDC Harmful Algal Blooms. Reservoir history: Encyclopedia of Indianapolis.',
                'Typeface: DM Sans by Colophon Foundry, SIL Open Font License.',
              ]),
              SizedBox(height: 8),
              Text(
                'GeistGuard is a student project for the 2026 Congressional App Challenge. '
                'It is not affiliated with or endorsed by the City of Fishers, IDEM, or any government agency.',
                style: T.meta,
              ),
            ],
          ),
        ),
      );

  Widget _figure(String value, String label) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: T.figure.copyWith(fontSize: 26)),
          SizedBox(height: 4),
          Text(label, style: T.meta),
        ]),
      );

  List<Widget> _lines(List<String> lines) => [
        for (final line in lines)
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(line, style: T.body),
          ),
      ];

  Widget _section(String title, List<String> lines) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [SectionTitle(title), ..._lines(lines)],
      );
}
