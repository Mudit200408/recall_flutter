import 'package:flutter/material.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';

class CreateDeckDialog extends StatefulWidget {
  final Function(String topic, int count, bool useImages, int duration)
  onSubmit;
  const CreateDeckDialog({super.key, required this.onSubmit});

  @override
  State<CreateDeckDialog> createState() => _CreateDeckDialogState();
}

class _CreateDeckDialogState extends State<CreateDeckDialog> {
  String topic = "";
  int count = 5;
  int duration = 3;
  bool useImages = false;

  // Neo-Brutalist Constants
  static const Color primaryColor = Color(0xFFCCFF00);
  static const Color blackColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: blackColor, width: 4),
          boxShadow: const [
            BoxShadow(color: blackColor, offset: Offset(8, 8), blurRadius: 0),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: blackColor),
                  child: const Icon(Icons.add, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "NEW MISSION",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Topic Input
            Text(
              "OBJECTIVE (TOPIC)",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                hintText: "e.g. 'Cybersecurity Basics'",
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.normal,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: blackColor, width: 3),
                  borderRadius: BorderRadius.zero,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: blackColor, width: 3),
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onChanged: (value) => topic = value,
            ),
            const SizedBox(height: 20),

            // Card Count Slider
            _buildSliderParams(
              context,
              "INTEL VOLUME (CARDS)",
              count,
              3,
              20,
              (val) => setState(() => count = val),
            ),
            const SizedBox(height: 16),

            // Duration Slider
            _buildSliderParams(
              context,
              "DEADLINE (DAYS)",
              duration,
              1,
              10,
              (val) => setState(() => duration = val),
            ),

            const SizedBox(height: 20),

            // Image Toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: blackColor, width: 3),
                color: useImages ? const Color(0xFFE0E0E0) : Colors.white,
              ),
              child: SwitchListTile(
                title: const Text(
                  "VISUAL DATA",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                subtitle: const Text(
                  "Enable AI generated imagery",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                activeThumbColor: blackColor,
                activeTrackColor: primaryColor,
                inactiveThumbColor: blackColor,
                inactiveTrackColor: Colors.grey[300],
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                value: useImages,
                onChanged: (value) => setState(() => useImages = value),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AnimatedButton(
                    text: "ABORT",
                    onTap: () => Navigator.pop(context),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedButton(
                    text: 'START',
                    onTap: () {
                      if (topic.isNotEmpty) {
                        widget.onSubmit(topic, count, useImages, duration);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderParams(
    BuildContext context,
    String label,
    int value,
    double min,
    double max,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: blackColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "$value",
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: blackColor,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: primaryColor,
            overlayColor: primaryColor.withOpacity(0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: (val) => onChanged(val.round()),
          ),
        ),
      ],
    );
  }
}
