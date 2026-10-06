import 'package:flutter/material.dart';

import 'recycling_centre_details_screen.dart';

class RecyclingCentreLocatorScreen extends StatefulWidget {
  const RecyclingCentreLocatorScreen({super.key});

  @override
  State<RecyclingCentreLocatorScreen> createState() =>
      _RecyclingCentreLocatorScreenState();
}

class _RecyclingCentreLocatorScreenState
    extends State<RecyclingCentreLocatorScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _centres = [
    {
      'name': 'Green Earth Recycling Centre',
      'distance': '1.2 km',
      'address': '123, Galle Road, Colombo 06',
    },
    {
      'name': 'Colombo Central Recycling Centre',
      'distance': '2.8 km',
      'address': 'Colombo Central Area',
    },
    {
      'name': 'EcoPoint Recycling Centre',
      'distance': '4.5 km',
      'address': 'Colombo',
    },
  ];

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER CENTRES
  // ============================================================

  List<Map<String, String>> get _filteredCentres {
    if (_searchText.trim().isEmpty) {
      return _centres;
    }

    final query = _searchText.toLowerCase();

    return _centres.where((centre) {
      final name = centre['name']!.toLowerCase();

      final address = centre['address']!.toLowerCase();

      return name.contains(query) || address.contains(query);
    }).toList();
  }

  // ============================================================
  // OPEN CENTRE DETAILS
  // ============================================================

  void _openCentreDetails({
    required String name,
    required String distance,
    required String address,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecyclingCentreDetailsScreen(
          name: name,
          distance: distance,
          address: address,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final centres = _filteredCentres;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Recycling Centres',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Column(
        children: [
          // ====================================================
          // SEARCH BAR
          // ====================================================

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search location...',
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchText = '';
                          });
                        },
                        icon: const Icon(Icons.close, size: 20),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF3F5F3),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ====================================================
          // MAP PLACEHOLDER
          // ====================================================
          Container(
            height: 235,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5EFE7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD0E3D3)),
            ),
            child: Stack(
              children: [
                // ROAD LINE 1
                Positioned(
                  left: 0,
                  right: 0,
                  top: 105,
                  child: Container(height: 6, color: Colors.white70),
                ),

                // ROAD LINE 2
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 135,
                  child: Transform.rotate(
                    angle: 0.35,
                    child: Container(width: 6, color: Colors.white70),
                  ),
                ),

                // ROAD LINE 3
                Positioned(
                  left: 15,
                  right: 15,
                  top: 42,
                  child: Transform.rotate(
                    angle: -0.18,
                    child: Container(height: 4, color: Colors.white54),
                  ),
                ),

                // MAP LABEL
                const Positioned(
                  left: 16,
                  top: 14,
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: Color(0xFF159447),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Nearby Recycling Centres',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF126B38),
                        ),
                      ),
                    ],
                  ),
                ),

                // USER LOCATION
                const Positioned(
                  left: 145,
                  top: 115,
                  child: _MapUserLocation(),
                ),

                // CENTRE 1
                const Positioned(
                  left: 65,
                  top: 70,
                  child: _MapMarker(number: '1'),
                ),

                // CENTRE 2
                const Positioned(
                  right: 60,
                  top: 55,
                  child: _MapMarker(number: '2'),
                ),

                // CENTRE 3
                const Positioned(
                  right: 85,
                  bottom: 30,
                  child: _MapMarker(number: '3'),
                ),

                // CURRENT LOCATION BUTTON
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF159447),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // NEARBY TITLE
          // ====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nearby Centres',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${centres.length} found',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          // ====================================================
          // CENTRE LIST
          // ====================================================
          Expanded(
            child: centres.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 44,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No recycling centres found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: centres.length,
                    itemBuilder: (context, index) {
                      final centre = centres[index];

                      return _centreCard(
                        name: centre['name']!,
                        distance: centre['distance']!,
                        address: centre['address']!,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CENTRE CARD
  // ============================================================

  Widget _centreCard({
    required String name,
    required String distance,
    required String address,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

        // CENTRE ICON
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.recycling,
            color: Color(0xFF159447),
            size: 27,
          ),
        ),

        // CENTRE NAME
        title: Text(
          name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),

        // ADDRESS
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.black45,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),

        // DISTANCE + ARROW
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              distance,
              style: const TextStyle(
                color: Color(0xFF159447),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Icon(Icons.chevron_right, size: 20, color: Colors.black45),
          ],
        ),

        // ======================================================
        // OPEN SCREEN 10
        // ======================================================
        onTap: () {
          _openCentreDetails(name: name, distance: distance, address: address);
        },
      ),
    );
  }
}

// ============================================================
// MAP MARKER
// ============================================================

class _MapMarker extends StatelessWidget {
  final String number;

  const _MapMarker({required this.number});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF159447),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 5,
              ),
            ],
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(width: 3, height: 9, color: const Color(0xFF159447)),
      ],
    );
  }
}

// ============================================================
// USER LOCATION
// ============================================================

class _MapUserLocation extends StatelessWidget {
  const _MapUserLocation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
        ],
      ),
    );
  }
}
