import 'package:flutter/material.dart';
import 'package:fitfusion/fitness_level_page.dart';

class WeightSelectionPage extends StatefulWidget {
  final int age;
  const WeightSelectionPage({super.key, required this.age});

  @override
  State<WeightSelectionPage> createState() => _WeightSelectionPageState();
}

class _WeightSelectionPageState extends State<WeightSelectionPage> {
  bool _isKg = true;
  double _weight = 62.0;
  final ScrollController _scrollController = ScrollController();

  final double _itemWidth = 10.0;
  final int _minWeight = 20;
  final int _maxWeight = 200;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollToWeight(_weight);
      }
    });
  }

  void _scrollToWeight(double weight) {
    double offset = (weight - _minWeight) * _itemWidth;
    _scrollController.jumpTo(offset);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFE7235),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Assessment",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "2 of 6",
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: const Text(
                "What’s your current\nweight right now?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 32),

            Container(
              decoration: BoxDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleButton("Kg", _isKg, () {
                    setState(() {
                      _isKg = true;
                    });
                  }),
                  const SizedBox(width: 24),
                  _buildToggleButton("Lbs", !_isKg, () {
                    setState(() {
                      _isKg = false;
                    });
                  }),
                ],
              ),
            ),

            const SizedBox(height: 48),

            Text(
              "${_weight.toInt()} ${_isKg ? 'Kg' : 'Lbs'}",
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(
              height: 100,
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollUpdateNotification) {
                    setState(() {
                      double val =
                          (_scrollController.offset / _itemWidth) + _minWeight;
                      if (val < _minWeight) val = _minWeight.toDouble();
                      if (val > _maxWeight) val = _maxWeight.toDouble();
                      _weight = val;
                    });
                  }
                  return true;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: (_maxWeight - _minWeight) + 1,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width / 2,
                  ),
                  itemBuilder: (context, index) {
                    final int value = _minWeight + index;
                    final bool isMajor = value % 5 == 0;

                    return Container(
                      width: _itemWidth,
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isMajor) ...[
                            Container(
                              width: 2,
                              height: 30,
                              color: Colors.white.withAlpha(204),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$value",
                              style: TextStyle(
                                color: Colors.white.withAlpha(204),
                                fontSize: 12,
                              ),
                            ),
                          ] else ...[
                            Container(
                              width: 2,
                              height: 15,
                              color: Colors.white.withAlpha(128),
                              margin: const EdgeInsets.only(bottom: 24),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FitnessLevelPage(
                          age: widget.age,
                          weight: _weight,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.white, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFE7235) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
