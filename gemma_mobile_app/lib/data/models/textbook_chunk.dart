import 'package:objectbox/objectbox.dart';

@Entity()
class TextbookChunk {
  @Id()
  int id = 0;
  
  String text;
  
  @Property(type: PropertyType.floatVector)
  @HnswIndex(dimensions: 10) // Using 10 dimensions to match our sample data
  List<double> embedding;
  
  TextbookChunk({
    required this.text,
    required this.embedding,
  });
  
  @override
  String toString() {
    return 'TextbookChunk{id: $id, text: ${text.substring(0, text.length > 50 ? 50 : text.length)}..., embedding: ${embedding.length}D}';
  }
}