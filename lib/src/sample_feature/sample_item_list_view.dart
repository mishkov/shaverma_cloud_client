import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../settings/settings_view.dart';
import 'sample_item.dart';

import 'package:http/http.dart' as http;

class SampleItemListView extends StatefulWidget {
  const SampleItemListView({
    super.key,
    this.items = const [SampleItem(1), SampleItem(2), SampleItem(3)],
  });

  static const routeName = '/';

  final List<SampleItem> items;

  @override
  State<SampleItemListView> createState() => _SampleItemListViewState();
}

class _SampleItemListViewState extends State<SampleItemListView> {
  Uri baseUri = Uri.parse('http://localhost:8080/');
  late VideoPlayerController _controller;
  Future<List<String>>? _availableMoviesFetchFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network('http://localhost:8080/')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });

    _availableMoviesFetchFuture = _getAvailableMovies();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<List<String>> _getAvailableMovies() async {
    final response = await http.get(
      baseUri.replace(path: '/get-available-movies'),
    );
    if (response.statusCode != 200) {
      throw Exception();
    }

    final Map<String, dynamic> mapResponse = jsonDecode(response.body);
    if (!mapResponse.containsKey('paths')) {
      throw Exception();
    }

    final pathsToMovies = (mapResponse['paths'] as List).map((path) {
      return path.toString();
    }).toList();

    return pathsToMovies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _availableMoviesFetchFuture = _getAvailableMovies();
                    });
                  },
                  child: const Text('Relod Movies List'),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: _availableMoviesFetchFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final movies = snapshot.data;
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: movies?.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(movies?[index] ?? 'Error'),
                              ),
                            );
                          },
                        );
                      } else {
                        return const Center(
                          child: Text('Error!!!'),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : Container(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
