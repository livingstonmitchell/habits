import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
	const ProgressScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Progress')),
			body: const Center(
				child: Text(
					'Progress screen coming soon',
					style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
				),
			),
		);
	}
}
