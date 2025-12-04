import 'dart:convert';
import 'package:http/http.dart' as http;


class EmbeddingService {
  // Use OpenAI's text-embedding-3-small model (1536 dimensions)
  // Alternative: text-embedding-ada-002 (1536 dimensions)
  static const String _apiUrl = 'https://api.openai.com/v1/embeddings';
  static const String _model = 'text-embedding-3-small';

  // Store your API key securely - consider using flutter_dotenv or similar
  final String _apiKey;

  EmbeddingService({required String apiKey}) : _apiKey = apiKey;

  /// Generates an embedding vector from profile text
  /// Returns a List<double> representing the semantic meaning
  Future<List<double>> generateEmbedding(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('Cannot generate embedding from empty text');
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'input': text,
          'model': _model,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = List<double>.from(
            data['data'][0]['embedding'].map((x) => x.toDouble())
        );
        return embedding;
      } else {
        throw Exception('Failed to generate embedding: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating embedding: $e');
    }
  }

  /// Creates a combined text string from profile fields for embedding
  /// This determines what aspects of the profile will be searchable
  static String createProfileText({
    required String bio,
    required String interests,
    required String location,
    String? city,
    String? country,
  }) {
    // Combine relevant fields into a single text
    // Order matters: prioritize the most important information first
    final parts = <String>[];

    if (bio.trim().isNotEmpty) {
      parts.add('Bio: $bio');
    }

    if (interests.trim().isNotEmpty) {
      parts.add('Interests: $interests');
    }

    if (city != null && city.trim().isNotEmpty) {
      parts.add('City: $city');
    } else if (location.trim().isNotEmpty) {
      parts.add('Location: $location');
    }

    if (country != null && country.trim().isNotEmpty) {
      parts.add('Country: $country');
    }

    return parts.join('. ');
  }

  /// Calculates cosine similarity between two vectors
  /// Returns a value between -1 and 1 (higher = more similar)
  static double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    if (vectorA.length != vectorB.length) {
      throw Exception('Vectors must have same length');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      normA += vectorA[i] * vectorA[i];
      normB += vectorB[i] * vectorB[i];
    }

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
  }
}

// Helper class for Math functions
class Math {
  static double sqrt(double x) => x < 0 ? 0 : _sqrt(x);

  static double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    double prevGuess;
    do {
      prevGuess = guess;
      guess = (guess + x / guess) / 2;
    } while ((guess - prevGuess).abs() > 0.000001);
    return guess;
  }
}