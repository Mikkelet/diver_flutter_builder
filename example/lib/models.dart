/// Plain runtime objects passed to routes through go_router's `$extra`.
///
/// They cannot be encoded in a URL, which is what makes a route carrying a
/// *required* `$extra` parameter ineligible for deeplinking.
class User {
  const User(this.name);

  final String name;
}

class Cart {
  const Cart(this.itemCount);

  final int itemCount;
}
