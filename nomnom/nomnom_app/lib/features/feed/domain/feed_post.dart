class FeedPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? groupId;
  final String? groupName;
  final String? recipeId;
  final String? recipeName;
  final String? recipeImage;
  final String? content;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.groupId,
    this.groupName,
    this.recipeId,
    this.recipeName,
    this.recipeImage,
    this.content,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    final rawAuthor = json['author'];
    String authorName = '';
    String? authorAvatar;
    String authorId = '';

    if (rawAuthor is Map<String, dynamic>) {
      authorName = rawAuthor['username'] as String? ?? '';
      authorAvatar = rawAuthor['profilePictureRef'] as String?;
      authorId = rawAuthor['_id']?.toString() ?? '';
    } else if (rawAuthor is String) {
      authorName = 'Unknown';
      authorId = rawAuthor;
    }

    final rawGroup = json['group'];
    String? groupName;
    String? groupId;
    if (rawGroup is Map<String, dynamic>) {
      groupName = rawGroup['name'] as String?;
      groupId = rawGroup['_id']?.toString();
    } else if (rawGroup is String) {
      groupId = rawGroup;
    }

    final rawRecipe = json['recipe'];
    String? recipeId;
    String? recipeName;
    String? recipeImage;

    if (rawRecipe is Map<String, dynamic>) {
      recipeId = rawRecipe['_id']?.toString();
      recipeName = rawRecipe['name'] as String?;
      final imgs = rawRecipe['images'] as List<dynamic>?;
      if (imgs != null && imgs.isNotEmpty) {
        recipeImage = imgs.first.toString();
      }
    } else if (rawRecipe is String) {
      recipeId = rawRecipe;
    }

    int likeCount = 0;
    int commentCount = 0;

    if (json['likeCount'] is num) {
      likeCount = (json['likeCount'] as num).toInt();
    } else if (json['likes'] is List) {
      likeCount = (json['likes'] as List).length;
    }

    if (json['commentCount'] is num) {
      commentCount = (json['commentCount'] as num).toInt();
    } else if (json['comments'] is List) {
      commentCount = (json['comments'] as List).length;
    }

    return FeedPost(
      id: json['_id']?.toString() ?? '',
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      groupId: groupId,
      groupName: groupName,
      recipeId: recipeId,
      recipeName: recipeName,
      recipeImage: recipeImage,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      likeCount: likeCount,
      commentCount: commentCount,
    );
  }
}
