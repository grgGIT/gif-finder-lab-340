import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const GiphyApp());
}

class GiphyApp extends StatelessWidget {
  const GiphyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIPHY App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'CustomFont', // Replace with your actual custom font family name
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      home: const GiphySearchPage(),
    );
  }
}

class GiphySearchPage extends StatefulWidget {
  const GiphySearchPage({super.key});

  @override
  _GiphySearchPageState createState() => _GiphySearchPageState();
}

class _GiphySearchPageState extends State<GiphySearchPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedNumber;
  String? _selectedRating;
  List<GifData> _results = [];
  final List<String> _dropdownValues = ['10', '20', '30', '40', '50'];
  final List<String> _ratingValues = ['g', 'pg', 'pg-13', 'r'];
  int _numberOfResults = 0;
  final String _apiKey = 'TVuw2BunbafGQpCJVjrI0vPmV20qqndi';

  @override
  void initState() {
    super.initState();
    _fetchRandomGif(); // Fetch random gif on startup
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Some GIFs!', style: TextStyle(fontFamily: 'CustomFont')), // Custom font in AppBar title
        shadowColor: Colors.blue,
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/giphy.gif'), // Add your moving background asset
            fit: BoxFit.cover,
            opacity: 0.5, // Less opaque background
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search for GIFs',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a search term';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                // Styled Dropdown for Number of GIFs
                DropdownButtonFormField<String>(
                  value: _selectedNumber,
                  items: _dropdownValues.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.black, // Black text for better contrast
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedNumber = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Number of GIFs to fetch',
                    border: const OutlineInputBorder(),
                    fillColor: Colors.deepPurple[50], // Light pastel purple
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select the number of GIFs';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                // Styled Dropdown for GIF Rating
                DropdownButtonFormField<String>(
                  value: _selectedRating,
                  items: _ratingValues.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.black, // Black text for better contrast
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedRating = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Select GIF rating',
                    border: const OutlineInputBorder(),
                    fillColor: Colors.deepPurple[50], // Light pastel purple
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a rating';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          FocusScope.of(context).unfocus();
                          _findGifs();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.deepPurpleAccent, // Button text color
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded corners
                        ),
                      ),
                      child: const Text('Find some GIFs!'),
                    ),
                    ElevatedButton(
                      onPressed: _resetForm,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.redAccent, // Button text color
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded corners
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Text(
                  _numberOfResults > 0
                      ? 'Found $_numberOfResults GIF${_numberOfResults > 1 ? 's' : ''}'
                      : 'No GIFs found.',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: _results.isEmpty
                      ? const Text('No GIFs to display.')
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _showGifDetails(_results[index]),
                              child: Column(
                                children: [
                                  Image.network(
                                    _results[index].url,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(height: 4.0),
                                  TextButton(
                                    onPressed: () {
                                      _launchUrl(_results[index].url); // Launch URL
                                    },
                                    child: const Text('View on Giphy'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blueAccent, // Button text color
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold), // Text style
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to fetch a random funny GIF
  Future<void> _fetchRandomGif() async {
    final Uri url = Uri.parse(
      'https://api.giphy.com/v1/gifs/random?api_key=$_apiKey&tag=funny&rating=g',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String gifUrl = data['data']['images']['fixed_height']['url'] as String;

        setState(() {
          _results = [GifData(url: gifUrl, meta: data['data'])]; // Set the results to the random GIF
          _numberOfResults = 1; // Update the number of results
        });
      } else {
        throw Exception('Failed to load random GIF');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching random GIF: $error')),
      );
    }
  }

  // API call to GIPHY for fetching GIFs
  Future<void> _findGifs() async {
    if (_apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key not set')),
      );
      return;
    }

    final String query = _searchController.text;
    final int limit = int.parse(_selectedNumber ?? '10');
    final String rating = _selectedRating ?? 'g';
    final Uri url = Uri.parse(
      'https://api.giphy.com/v1/gifs/search?api_key=$_apiKey&q=$query&limit=$limit&rating=$rating',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> gifs = data['data'];

        setState(() {
          _results = gifs.map((gif) => GifData(url: gif['images']['fixed_height']['url'], meta: gif)).toList();
          _numberOfResults = gifs.length; // Update the number of results
        });
      } else {
        throw Exception('Failed to load GIFs');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching GIFs: $error')),
      );
    }
  }

  // Reset the form fields and fetch a new random GIF
  void _resetForm() {
    _formKey.currentState!.reset();
    _searchController.clear();
    setState(() {
      _results = [];
      _numberOfResults = 0;
    });
    _fetchRandomGif(); // Fetch a new random GIF on reset
  }

  // Show GIF details when tapped
  void _showGifDetails(GifData gif) {
    // You can implement this to show more details if needed
  }

  // Launch URL in the default web browser
  Future<void> _launchUrl(String url) async {
    if (!await launch(url)) throw 'Could not launch $url';
  }
}

// Model for GIF data
class GifData {
  final String url;
  final dynamic meta;

  GifData({required this.url, required this.meta});
}
