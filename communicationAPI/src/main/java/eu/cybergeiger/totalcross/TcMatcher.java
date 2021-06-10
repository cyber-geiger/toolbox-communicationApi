package eu.cybergeiger.totalcross;

interface TcMatcher {

  Matcher matcher(String s);

  boolean matches();

  String group(int num);

  String pattern();
}
