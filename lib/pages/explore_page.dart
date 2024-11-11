import 'package:flutter/material.dart';
import '../widget/activity_card.dart';

class ExplorePage extends StatefulWidget {
  final List<dynamic> activities;
  const ExplorePage({super.key, required this.activities});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
Widget build(BuildContext context) {
  super.build(context); // This ensures the keep-alive functionality
  return Scaffold(
    appBar: AppBar(title: const Text('Explore')),
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: widget.activities.length,
        itemBuilder: (context, index) {
          final activity = widget.activities[index];
          return ActivityCard(activity: activity);
        },
      ),
    ),
  );
}

  @override
  bool get wantKeepAlive => true; // Ensures the state is kept alive
}
