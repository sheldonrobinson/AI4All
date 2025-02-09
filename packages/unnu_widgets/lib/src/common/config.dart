// const String SESSION_ID_KEY = 'session.id';

enum Avatars {
  User(
    id: "user",
    Name: 'User',
    imageSource: 'packages/unnu_widgets/assets/images/user.png',
  ),
  Assistant(
    id: "assistant",
    Name: 'Assistant',
    imageSource: 'packages/unnu_widgets/assets/images/assistant.png',
  );

  const Avatars({
    required this.id,
    required this.Name,
    required this.imageSource,
  });

  final String id;
  final String Name;
  final String imageSource;
}
