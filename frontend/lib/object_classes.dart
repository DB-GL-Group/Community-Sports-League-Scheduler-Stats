class User {
  String firstname = '';
  String lastname = '';
  String email = '';
  List<String> roles = [];
  bool anonymous = true;

  User();

  User.create(this.firstname, this.lastname, this.email, this.roles) {
    anonymous = false;
  }
}