import 'package:flutter/material.dart';

class CreateDeckDialog extends StatefulWidget {
  final Function(String topic, int count) onSubmit;
  const CreateDeckDialog({super.key, required this.onSubmit});

  @override
  State<CreateDeckDialog> createState() => _CreateDeckDialogState();
}

class _CreateDeckDialogState extends State<CreateDeckDialog> {
  String topic = "";
  int count = 5;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create New Deck"),
      content: Column(
        mainAxisSize: .min,
        children: [
          TextField(
            decoration: const InputDecoration(
              label: Text("Topic"),
              hintText: "e.g. 'AI Fundamentals'",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(21)),
              ),
            ),
            onChanged: (value) => topic = value,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Card Count: "),
              Text(
                "${count.round()}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),

          Slider(
            value: count.toDouble(),
            min: 3,
            max: 20,
            divisions: 17,
            label: count.round().toString(),
            onChanged: (value) {
              setState(() {
                count = value.round();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (topic.isNotEmpty) {
              widget.onSubmit(topic, count.round());
              Navigator.pop(context);
            }
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }
}
