/// Optional annotation attached to a go_router route class to enrich the
/// generated `app_urls.json` with a human-readable [name] and [description].
class DiverRoute {
  const DiverRoute({required this.name, required this.description});

  final String name;
  final String description;
}
