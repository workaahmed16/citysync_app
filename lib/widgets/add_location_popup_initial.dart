import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AddLocationPopupInitial extends StatelessWidget {
  const AddLocationPopupInitial({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kDarkBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "✨ Add a New Location ✨",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kWhite,
              ),
            ),
            const SizedBox(height: 20),

            /// Explanation
            const Text(
              "Pick your spot directly from the map for perfect accuracy.",
              textAlign: TextAlign.center,
              style: TextStyle(color: kWhite, fontSize: 16),
            ),
            const SizedBox(height: 24),

            /// Button to go to map
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                foregroundColor: kWhite,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // TODO: Navigate to your map screen
                // Example:
                // Navigator.of(context).push(
                //   MaterialPageRoute(builder: (_) => MapSelectionScreen()),
                // );
              },
              icon: const Icon(Icons.map),
              label: const Text(
                "Select Location on Map",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            /// Cancel button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: kWhite,
                side: const BorderSide(color: kWhite),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
