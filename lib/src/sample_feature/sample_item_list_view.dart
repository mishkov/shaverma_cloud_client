import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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

  final player = Player();
  VideoController? controller;

  Future<List<String>>? _availableMoviesFetchFuture;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Create a [VideoController] instance from `package:media_kit_video`.
      // Pass the [handle] of the [Player] from `package:media_kit` to the [VideoController] constructor.
      controller = await VideoController.create(player.handle);
      player.streams.error.listen((event) {
        print(event);
      });
      // Must be created before opening any media. Otherwise, a separate window will be created.
      setState(() {});
    });
    _availableMoviesFetchFuture = _getAvailableMovies();
  }

  @override
  void dispose() {
    Future.microtask(() async {
      // Release allocated resources back to the system.
      await controller?.dispose();
      await player.dispose();
    });
    super.dispose();
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
                            return GestureDetector(
                              onTap: () async {
                                final pathToMovie = baseUri
                                    .replace(path: '/movies/${movies![index]}')
                                    .toString();
                                await player.open(
                                  Playlist([Media(pathToMovie)]),
                                );
                                await player.play();
                              },
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(movies?[index] ?? 'Error'),
                                ),
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
            child: Video(controller: controller),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            player.playOrPause();
          });
        },
        child: Icon(
          !player.state.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
